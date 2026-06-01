<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class GeminiService
{
    private string $key;
    private string $textModel;
    private string $imageModel;
    private string $imageProvider;
    private string $pollinationsToken;
    private string $base = 'https://generativelanguage.googleapis.com/v1beta/models';

    /** Human-readable reason the last image generation failed (null when it succeeded). */
    private ?string $lastImageError = null;

    public function __construct()
    {
        $this->key = (string) config('services.gemini.key');
        $this->textModel = (string) config('services.gemini.text_model');
        $this->imageModel = (string) config('services.gemini.image_model');
        $this->imageProvider = (string) config('services.gemini.image_provider', 'pollinations');
        $this->pollinationsToken = (string) config('services.gemini.pollinations_token', '');
    }

    /**
     * Whether we can download many images quickly (so every page image can be
     * pre-generated). True for Gemini (billing) or when a Pollinations token
     * lifts the free-tier rate limit. On the anonymous free tier this is false,
     * so callers should pre-generate only the cover and link the rest by URL.
     */
    public function canBatchImages(): bool
    {
        return $this->imageProvider === 'gemini' || $this->pollinationsToken !== '';
    }

    /**
     * True when the image provider is the reliable paid Gemini one — so callers
     * can skip the retries and pacing that the free image tier needs (which
     * would otherwise waste paid API calls / tokens).
     */
    public function usesGeminiImages(): bool
    {
        return $this->imageProvider === 'gemini';
    }

    public function isConfigured(): bool
    {
        return $this->key !== '';
    }

    /** Reason the last generateCoverImage() call failed, or null on success. */
    public function imageError(): ?string
    {
        return $this->lastImageError;
    }

    /**
     * Download an illustration to local storage and return a public path like
     * "storage/uploads/covers/<uuid>.jpg", or null if it could not be made.
     *
     * Downloading (rather than storing a URL) means the app loads images from
     * our own server — so several page images can display at once without
     * hitting the image provider's per-request rate limit. The caller should
     * pace these and keep a time budget (see ContentManagementController).
     */
    public function downloadImage(string $prompt, int $seed = 0): ?string
    {
        $this->lastImageError = null;

        if ($this->imageProvider === 'gemini') {
            return $this->generateWithGemini($this->styledPrompt($prompt));
        }
        return $this->downloadFromPollinations($this->imageUrl($prompt, $seed));
    }

    /**
     * Generate natural-voice narration for a piece of text using Gemini TTS
     * (free tier). Returns a public "storage/tts/<hash>.wav" path, or null on
     * failure. Cached by text+voice so a page isn't regenerated (saves quota).
     */
    public function generateSpeech(string $text, string $voice = 'Kore'): ?string
    {
        $text = trim($text);
        if ($text === '') {
            return null;
        }

        $path = 'tts/' . sha1($voice . '|' . $text) . '.wav';
        if (Storage::disk('public')->exists($path)) {
            return 'storage/' . $path;
        }

        try {
            $model = 'gemini-2.5-flash-preview-tts';
            $response = Http::timeout(60)->post(
                "{$this->base}/{$model}:generateContent?key={$this->key}",
                [
                    'contents' => [
                        ['parts' => [['text' => $text]]],
                    ],
                    'generationConfig' => [
                        'responseModalities' => ['AUDIO'],
                        'speechConfig' => [
                            'voiceConfig' => [
                                'prebuiltVoiceConfig' => ['voiceName' => $voice],
                            ],
                        ],
                    ],
                ]
            );

            if (!$response->successful()) {
                Log::warning('Gemini TTS error', [
                    'status' => $response->status(),
                    'body'   => mb_substr($response->body(), 0, 300),
                ]);
                return null;
            }

            $b64 = data_get($response->json(), 'candidates.0.content.parts.0.inlineData.data')
                ?? data_get($response->json(), 'candidates.0.content.parts.0.inline_data.data');
            if (!$b64) {
                return null;
            }

            $pcm = base64_decode($b64, true);
            if ($pcm === false) {
                return null;
            }

            // Gemini returns 16-bit signed PCM, 24 kHz, mono — wrap it in a WAV
            // container so the app can play it with a normal audio player.
            Storage::disk('public')->put($path, $this->pcmToWav($pcm, 24000, 1, 16));
            return 'storage/' . $path;
        } catch (\Throwable $e) {
            Log::warning('Gemini TTS exception', ['error' => $e->getMessage()]);
            return null;
        }
    }

    /** Wrap raw PCM bytes in a minimal 44-byte WAV header. */
    private function pcmToWav(string $pcm, int $sampleRate, int $channels, int $bits): string
    {
        $byteRate   = $sampleRate * $channels * intdiv($bits, 8);
        $blockAlign = $channels * intdiv($bits, 8);
        $dataLen    = strlen($pcm);

        return 'RIFF' . pack('V', 36 + $dataLen) . 'WAVE'
            . 'fmt ' . pack('V', 16) . pack('v', 1) . pack('v', $channels)
            . pack('V', $sampleRate) . pack('V', $byteRate)
            . pack('v', $blockAlign) . pack('v', $bits)
            . 'data' . pack('V', $dataLen) . $pcm;
    }

    /**
     * Build a stable Pollinations image URL (no network call). Used as a
     * fallback reference when a synchronous download isn't possible.
     */
    public function imageUrl(string $prompt, int $seed = 0): string
    {
        // Keep the URL bounded and add a short, consistent illustration style.
        $scene = trim($prompt);
        if (mb_strlen($scene) > 240) {
            $scene = mb_substr($scene, 0, 240);
        }
        $styled = $scene . ', soft pastel storybook illustration for children, gentle, calm, no text';

        // NB: we deliberately don't request 'flux' — it's now a paid model that
        // returns HTTP 402 / is heavily throttled. The default model is free.
        $query = http_build_query([
            'width'  => 768,
            'height' => 512,
            'nologo' => 'true',
            'seed'   => $seed > 0 ? $seed : random_int(1, 999999),
        ]);

        return 'https://image.pollinations.ai/prompt/' . rawurlencode($styled) . '?' . $query;
    }

    /** Fetch a Pollinations image URL and store the bytes locally. */
    private function downloadFromPollinations(string $url): ?string
    {
        try {
            // Short timeout: if the free tier is queueing us, fail fast and let
            // the caller fall back to a URL reference instead of hanging.
            $request = Http::timeout(25);
            if ($this->pollinationsToken !== '') {
                $request = $request->withToken($this->pollinationsToken);
            }
            $response = $request->get($url);

            if (!$response->successful()) {
                Log::warning('Pollinations image error', ['status' => $response->status()]);
                $this->lastImageError = 'The free image service was busy.';
                return null;
            }

            $binary = $response->body();
            if (strlen($binary) < 1000 || !str_contains((string) $response->header('Content-Type'), 'image')) {
                $this->lastImageError = 'The free image service did not return a picture.';
                return null;
            }

            $path = 'uploads/covers/' . Str::uuid() . '.jpg';
            Storage::disk('public')->put($path, $binary);
            return 'storage/' . $path;
        } catch (\Throwable $e) {
            Log::warning('Pollinations image exception', ['error' => $e->getMessage()]);
            $this->lastImageError = 'Image download timed out.';
            return null;
        }
    }

    /** Wrap a scene description in a consistent, calming illustration style. */
    private function styledPrompt(string $prompt): string
    {
        return 'A soft, calming, child-friendly storybook illustration. '
            . 'Gentle pastel colours, simple rounded shapes, no text, nothing scary. '
            . 'Scene: ' . $prompt;
    }

    /**
     * Generate a paginated, autism-friendly story.
     *
     * @return array{title:string, content:string, image_prompt:string, pages:list<array{text:string, image_prompt:string}>}
     * @throws \RuntimeException
     */
    public function generateStory(string $topic, ?string $ageGroup, ?string $sourceText, ?int $pageCount = null, ?string $language = null): array
    {
        $age = $ageGroup ?: '7-9';
        $instruction = ($sourceText !== null && trim($sourceText) !== '')
            ? "Rewrite the following text into a calming, autism-friendly children's story.\n\nTEXT:\n" . trim($sourceText)
            : "Write a calming, autism-friendly children's story about: {$topic}";

        // Page count: honour the caregiver's request when given, otherwise let
        // the model pick — but cap "Auto" to a few pages, because each page is a
        // separate (~12s) image, so more pages = a much longer generation wait.
        $lengthRule = ($pageCount !== null && $pageCount > 0)
            ? "Split the story into exactly {$pageCount} short pages, like a picture book."
            : 'Split the story into between 4 and 6 short pages, like a picture book — '
                . 'choose a sensible length for the topic and age.';

        // Map app language code to a clear instruction. Image prompts always
        // stay in English so the image model gets predictable, unambiguous
        // descriptions even when the story text is Malay.
        $code = strtolower($language ?? 'en');
        $languageRule = match ($code) {
            'ms' => "Write the story TEXT (the 'text' field for every page, and the 'title') in Bahasa Malaysia (standard Malay). Keep \"image_prompt\" in English — it goes to the image generator and must stay clear and literal.",
            default => 'Write the story in clear, simple English.',
        };

        $prompt = <<<PROMPT
You are an author creating gentle, sensory-friendly stories for autistic children aged {$age}.
{$instruction}

Stay close to what the reader asked for: keep the characters, setting, and ideas
they described, and make the story actually about their request.

{$languageRule}

{$lengthRule}
For each page give:
- "text": one or two very short, simple sentences for that page.
- "image_prompt": a clear description of a gentle illustration for THAT page's scene.

Rules:
- Keep a calm, warm, predictable tone. No scary, loud, or sudden events.
- Avoid idioms and sarcasm; be literal and clear.
- Each page's text should follow on naturally from the page before.
- Each "image_prompt" MUST be self-contained: restate the main character's
  name and appearance every time so every illustration looks consistent, and
  describe only what happens on that page.

Return ONLY JSON with keys: title (string) and pages (array of page objects).
PROMPT;

        $response = Http::timeout(60)->post(
            "{$this->base}/{$this->textModel}:generateContent?key={$this->key}",
            [
                'contents' => [
                    ['parts' => [['text' => $prompt]]],
                ],
                'generationConfig' => [
                    'temperature' => 0.8,
                    'responseMimeType' => 'application/json',
                    'responseSchema' => [
                        'type' => 'OBJECT',
                        'properties' => [
                            'title' => ['type' => 'STRING'],
                            'pages' => [
                                'type'  => 'ARRAY',
                                'items' => [
                                    'type'       => 'OBJECT',
                                    'properties' => [
                                        'text'         => ['type' => 'STRING'],
                                        'image_prompt' => ['type' => 'STRING'],
                                    ],
                                    'required' => ['text', 'image_prompt'],
                                ],
                            ],
                        ],
                        'required' => ['title', 'pages'],
                    ],
                ],
            ]
        );

        if ($response->status() === 429) {
            Log::warning('Gemini quota exceeded', ['body' => $response->body()]);
            throw new \RuntimeException($this->quotaMessage($response->json()));
        }

        if (!$response->successful()) {
            Log::error('Gemini text error', [
                'status' => $response->status(),
                'body'   => $response->body(),
            ]);
            throw new \RuntimeException('Gemini text generation failed (HTTP ' . $response->status() . ')');
        }

        $text = data_get($response->json(), 'candidates.0.content.parts.0.text');
        if (!$text) {
            throw new \RuntimeException('Gemini returned no content');
        }

        $parsed = json_decode($text, true);
        $title = trim((string) ($parsed['title'] ?? ($topic !== '' ? $topic : 'A Gentle Story')));

        // Normalise the pages array; fall back to a single page if needed.
        $pages = [];
        if (is_array($parsed) && !empty($parsed['pages']) && is_array($parsed['pages'])) {
            foreach ($parsed['pages'] as $page) {
                $pageText = trim((string) ($page['text'] ?? ''));
                if ($pageText === '') {
                    continue;
                }
                $pages[] = [
                    'text'         => $pageText,
                    'image_prompt' => trim((string) ($page['image_prompt'] ?? $pageText)),
                ];
            }
        }

        if (empty($pages)) {
            // Model didn't return usable pages — treat the whole reply as one page.
            $body = (is_array($parsed) && !empty($parsed['story']))
                ? trim((string) $parsed['story'])
                : trim((string) $text);
            $pages[] = ['text' => $body, 'image_prompt' => $topic !== '' ? $topic : $title];
        }

        return [
            'title'        => $title,
            'content'      => implode("\n\n", array_column($pages, 'text')),
            'image_prompt' => $pages[0]['image_prompt'],
            'pages'        => $pages,
        ];
    }

    /** Image generation via Google Gemini (requires a billing-enabled key). */
    private function generateWithGemini(string $fullPrompt): ?string
    {
        try {
            $response = Http::timeout(90)->post(
                "{$this->base}/{$this->imageModel}:generateContent?key={$this->key}",
                [
                    'contents' => [
                        ['parts' => [['text' => $fullPrompt]]],
                    ],
                    'generationConfig' => [
                        // Image only — don't also generate descriptive text we'd
                        // throw away (saves output tokens / cost).
                        'responseModalities' => ['IMAGE'],
                    ],
                ]
            );

            if (!$response->successful()) {
                Log::warning('Gemini image error', [
                    'status' => $response->status(),
                    'body'   => $response->body(),
                ]);
                $this->lastImageError = $this->imageErrorMessage($response->status(), $response->json());
                return null;
            }

            $parts = data_get($response->json(), 'candidates.0.content.parts', []);
            foreach ($parts as $part) {
                $data = $part['inlineData']['data'] ?? $part['inline_data']['data'] ?? null;
                if ($data) {
                    $binary = base64_decode($data, true);
                    if ($binary === false) {
                        continue;
                    }
                    // Gemini returns 1024x1024 PNGs (~1.4-1.7 MB each), which
                    // makes the page reader feel slow on emulators because every
                    // page has to download AND decode that much data. Shrink to
                    // ~768px JPEG before persisting — typically ~120-200 KB,
                    // so the static file served from storage/uploads/covers/
                    // loads roughly 7-10x faster without visible quality loss.
                    [$saveBytes, $ext] = $this->shrinkForWeb($binary);
                    $path = 'uploads/covers/' . Str::uuid() . '.' . $ext;
                    Storage::disk('public')->put($path, $saveBytes);
                    return 'storage/' . $path;
                }
            }

            Log::warning('Gemini image returned no inline image data');
            $this->lastImageError = 'The AI did not return an image. Please try a different topic.';
            return null;
        } catch (\Throwable $e) {
            Log::warning('Gemini image exception', ['error' => $e->getMessage()]);
            $this->lastImageError = 'Image generation timed out or failed. The story was saved without a picture.';
            return null;
        }
    }

    /** Turn an image-generation HTTP failure into a short, caregiver-friendly reason. */
    private function imageErrorMessage(int $status, ?array $json): string
    {
        if ($status === 429) {
            return 'Image generation is not available on the free Gemini tier'
                . ' (quota is 0). Enable billing on your Google AI Studio key to'
                . ' generate pictures, or add your own image. The story text was saved.';
        }
        if ($status === 404) {
            return 'The configured image model was not found. Set'
                . ' GEMINI_IMAGE_MODEL=gemini-2.5-flash-image in the backend .env.';
        }
        $apiMessage = (string) data_get($json, 'error.message', '');
        return $apiMessage !== ''
            ? "Image generation failed: {$apiMessage}"
            : "Image generation failed (HTTP {$status}). The story text was saved.";
    }

    /**
     * Build a friendly message from a Gemini 429 (quota) response, including
     * the suggested retry delay when the API provides one.
     */
    private function quotaMessage(?array $json): string
    {
        $seconds = null;
        foreach (data_get($json, 'error.details', []) as $detail) {
            if (($detail['@type'] ?? '') === 'type.googleapis.com/google.rpc.RetryInfo') {
                $seconds = (int) rtrim((string) ($detail['retryDelay'] ?? ''), 's');
            }
        }

        $msg = "AI quota reached for model {$this->textModel}.";
        if ($seconds) {
            $msg .= " Please try again in about {$seconds}s.";
        }
        $msg .= ' If this keeps happening, the free-tier quota for this key may be 0 —'
            . ' try a different model (e.g. gemini-2.5-flash) or check your Gemini plan.';

        return $msg;
    }

    /**
     * Downscale image bytes to a max edge and re-encode as JPEG.
     *
     * Returns a [bytes, extension] tuple. Falls back to ['png', original bytes]
     * if PHP's GD extension isn't available or the operation fails, so image
     * generation always succeeds — just with a larger file in that case.
     */
    private function shrinkForWeb(string $original, int $maxEdge = 768, int $quality = 82): array
    {
        if (!function_exists('imagecreatefromstring')) {
            return [$original, 'png'];
        }
        $src = @imagecreatefromstring($original);
        if (!$src) {
            return [$original, 'png'];
        }
        $dst = null;
        try {
            $w = imagesx($src);
            $h = imagesy($src);
            if ($w <= 0 || $h <= 0) {
                return [$original, 'png'];
            }
            $ratio = min(1.0, $maxEdge / max($w, $h));
            $tw = max(1, (int) round($w * $ratio));
            $th = max(1, (int) round($h * $ratio));
            $dst = imagecreatetruecolor($tw, $th);
            if (!$dst) {
                return [$original, 'png'];
            }
            // JPEG has no alpha — paint a white backing first so PNG transparency
            // becomes white, not black.
            $white = imagecolorallocate($dst, 255, 255, 255);
            imagefilledrectangle($dst, 0, 0, $tw, $th, $white);
            imagecopyresampled($dst, $src, 0, 0, 0, 0, $tw, $th, $w, $h);
            ob_start();
            $ok = imagejpeg($dst, null, $quality);
            $jpeg = (string) ob_get_clean();
            if (!$ok || $jpeg === '') {
                return [$original, 'png'];
            }
            return [$jpeg, 'jpg'];
        } catch (\Throwable $e) {
            Log::warning('Image shrink failed', ['error' => $e->getMessage()]);
            return [$original, 'png'];
        } finally {
            if ($src) {
                imagedestroy($src);
            }
            if ($dst) {
                imagedestroy($dst);
            }
        }
    }
}
