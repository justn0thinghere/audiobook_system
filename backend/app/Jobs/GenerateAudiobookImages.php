<?php

namespace App\Jobs;

use App\Models\Audiobook;
use App\Services\GeminiService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Generates the per-page illustrations for an AI storybook in the background.
 *
 * The audiobook is created with status "processing"; this job draws each page's
 * image one at a time (the free image tier serves one request at a time),
 * retrying briefly, and only flips the book to "available" once every page has
 * an image. That way the app can show a pending state and the finished book
 * appears only when all pictures are ready.
 *
 * Requires a queue worker:  php artisan queue:work
 */
class GenerateAudiobookImages implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    /** Give the whole book plenty of time (many slow image requests). */
    public int $timeout = 1200;
    public int $tries = 1;

    public function __construct(public string $audiobookId)
    {
    }

    public function handle(GeminiService $gemini): void
    {
        $book = Audiobook::with('pages')->find($this->audiobookId);
        if (!$book) {
            return;
        }

        $coverImagePath = null;

        // Paid Gemini is reliable — one call per image, no retries or pacing
        // (which would just waste paid API calls). The free tier is slow and
        // serves one at a time, so there we retry a little and pace requests.
        $reliable = $gemini->usesGeminiImages();
        $maxAttempts = $reliable ? 1 : 3;

        foreach ($book->pages as $page) {
            $prompt = $page->image_prompt !== null && $page->image_prompt !== ''
                ? $page->image_prompt
                : (string) $page->text;

            $path = null;
            for ($attempt = 0; $attempt < $maxAttempts && !$path; $attempt++) {
                if ($attempt > 0) {
                    sleep(4); // back off before retrying a busy/queued free tier
                }
                $path = $gemini->downloadImage($prompt, $page->page_number);
            }

            // Last resort: keep an on-demand URL so the page still has a picture.
            if (!$path) {
                $path = $gemini->imageUrl($prompt, $page->page_number);
            }

            $page->image = $path;
            $page->save();

            $coverImagePath ??= $path;
            if (!$reliable) {
                sleep(1); // pace requests to respect the free tier's 1-at-a-time limit
            }
        }

        $book->cover_image = $coverImagePath;
        $book->status = 'available';
        $book->save();

        Log::info('Audiobook images generated', [
            'audiobook_id' => $book->audiobook_id,
            'pages'        => $book->pages->count(),
        ]);
    }

    /** If the job blows up, don't leave the book stuck on "processing". */
    public function failed(\Throwable $e): void
    {
        $book = Audiobook::find($this->audiobookId);
        if ($book) {
            $book->status = 'available';
            $book->save();
        }
        Log::error('Audiobook image job failed', [
            'audiobook_id' => $this->audiobookId,
            'error'        => $e->getMessage(),
        ]);
    }
}
