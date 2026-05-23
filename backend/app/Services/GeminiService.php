<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Thin wrapper around the Google Gemini REST API.
 *
 *  - generateStory()      -> autism-friendly story text (+ an illustration prompt)
 *  - generateCoverImage() -> a PNG cover saved to public storage (best-effort)
 *
 * Free-tier note: image generation has tight quotas and may be unavailable;
 * generateCoverImage() returns null on any failure so callers can continue.
 */
class GeminiService
{
    private string $key;
    private string $textModel;
    private string $imageModel;
    private string $base = 'https://generativelanguage.googleapis.com/v1beta/models';

    public function __construct()
    {
        $this->key = (string) config('services.gemini.key');
        $this->textModel = (string) config('services.gemini.text_model');
        $this->imageModel = (string) config('services.gemini.image_model');
    }

    public function isConfigured(): bool
    {
        return $this->key !== '';
    }

    /**
     * @return array{title:string, content:string, image_prompt:string}
     * @throws \RuntimeException
     */
    public function generateStory(string $topic, ?string $ageGroup, ?string $sourceText): array
    {
        $age = $ageGroup ?: '7-9';
        $instruction = ($sourceText !== null && trim($sourceText) !== '')
            ? "Rewrite the following text into a calming, autism-friendly children's story.\n\nTEXT:\n" . trim($sourceText)
            : "Write a calming, autism-friendly children's story about: {$topic}";

        $prompt = <<<PROMPT
You are an author creating gentle, sensory-friendly stories for autistic children aged {$age}.
{$instruction}

Rules:
- Use very short, simple sentences.
- Keep a calm, warm, predictable tone. No scary, loud, or sudden events.
- Between 6 and 10 short sentences total.
- Avoid idioms and sarcasm; be literal and clear.
- Suggest one gentle illustration that matches the story.

Return ONLY JSON with keys: title, story, image_prompt.
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
                            'title'        => ['type' => 'STRING'],
                            'story'        => ['type' => 'STRING'],
                            'image_prompt' => ['type' => 'STRING'],
                        ],
                        'required' => ['title', 'story', 'image_prompt'],
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
        if (!is_array($parsed) || empty($parsed['story'])) {
            // Model didn't return clean JSON — use the raw text as the story body.
            return [
                'title'        => $topic !== '' ? $topic : 'A Gentle Story',
                'content'      => trim($text),
                'image_prompt' => $topic,
            ];
        }

        return [
            'title'        => trim($parsed['title'] ?? ($topic !== '' ? $topic : 'A Gentle Story')),
            'content'      => trim($parsed['story']),
            'image_prompt' => trim($parsed['image_prompt'] ?? $topic),
        ];
    }

    /**
     * Generate a cover illustration. Returns a public path like
     * "storage/uploads/covers/<uuid>.png" or null when generation fails.
     */
    public function generateCoverImage(string $prompt): ?string
    {
        try {
            $fullPrompt = 'A soft, calming, child-friendly storybook illustration. '
                . 'Gentle pastel colours, simple rounded shapes, no text, nothing scary. '
                . 'Scene: ' . $prompt;

            $response = Http::timeout(90)->post(
                "{$this->base}/{$this->imageModel}:generateContent?key={$this->key}",
                [
                    'contents' => [
                        ['parts' => [['text' => $fullPrompt]]],
                    ],
                    'generationConfig' => [
                        'responseModalities' => ['TEXT', 'IMAGE'],
                    ],
                ]
            );

            if (!$response->successful()) {
                Log::warning('Gemini image error', [
                    'status' => $response->status(),
                    'body'   => $response->body(),
                ]);
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
                    $path = 'uploads/covers/' . Str::uuid() . '.png';
                    Storage::disk('public')->put($path, $binary);
                    return 'storage/' . $path;
                }
            }

            Log::warning('Gemini image returned no inline image data');
            return null;
        } catch (\Throwable $e) {
            Log::warning('Gemini image exception', ['error' => $e->getMessage()]);
            return null;
        }
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
}
