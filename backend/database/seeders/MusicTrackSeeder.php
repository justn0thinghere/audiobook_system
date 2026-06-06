<?php

namespace Database\Seeders;

use App\Models\MusicTrack;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class MusicTrackSeeder extends Seeder
{
    /**
     * Tags are comma-separated mood descriptors used for AI auto-selection and
     * caregiver filtering. Each tag spans at least 2 tracks so it is meaningful
     * as a filter. Tags are title-cased for consistent display.
     *
     * Tag coverage across the 6 tracks:
     *   Happy       → 1, 5
     *   Upbeat      → 1, 5
     *   Energetic   → 1, 5
     *   Playful     → 1, 5, 6
     *   Calm        → 2, 3
     *   Gentle      → 2, 6
     *   Soothing    → 2, 3
     *   Peaceful    → 2, 3
     *   Relaxing    → 3  (sleep / bedtime use-case anchor)
     *   Mysterious  → 4  (distinctive mood anchor)
     *   Adventurous → 4, 6
     *   Imaginative → 4, 6
     *   Curious     → 4, 6
     *   Whimsical   → 5, 6
     */
    public function run(): void
    {
        $tracks = [
            [
                'title'        => 'Happy Kids Background Music',
                'composer'     => 'Bombinsound',
                'file_path'    => 'storage/bgm/bombinsound-happy-kids-background-music-499554.mp3',
                'tags'         => 'Happy,Upbeat,Energetic,Playful',
                'tempo'        => 'upbeat',
                'duration_secs'=> 157,
            ],
            [
                'title'        => 'December Rain',
                'composer'     => 'Ceeprolific',
                'file_path'    => 'storage/bgm/ceeprolific-december-rain-274814.mp3',
                'tags'         => 'Calm,Gentle,Soothing,Peaceful',
                'tempo'        => 'slow',
                'duration_secs'=> 303,
            ],
            [
                'title'        => 'Relaxing Sleep Music with Soft Ambient Rain',
                'composer'     => 'Desifreemusic',
                'file_path'    => 'storage/bgm/desifreemusic-relaxing-sleep-music-with-soft-ambient-rain-369762.mp3',
                'tags'         => 'Calm,Soothing,Peaceful,Relaxing',
                'tempo'        => 'slow',
                'duration_secs'=> 274,
            ],
            [
                'title'        => 'Mystery of Time',
                'composer'     => 'Emmraan',
                'file_path'    => 'storage/bgm/emmraan-mystery-of-time-213387.mp3',
                'tags'         => 'Mysterious,Adventurous,Imaginative,Curious',
                'tempo'        => 'moderate',
                'duration_secs'=> 105,
            ],
            [
                'title'        => 'Happy Happy Kids Music',
                'composer'     => 'Sigma Music Art',
                'file_path'    => 'storage/bgm/sigmamusicart-happy-happy-kids-music-537737.mp3',
                'tags'         => 'Happy,Upbeat,Energetic,Playful,Whimsical',
                'tempo'        => 'upbeat',
                'duration_secs'=> 219,
            ],
            [
                'title'        => 'Once Upon a Time',
                'composer'     => 'Sonican',
                'file_path'    => 'storage/bgm/sonican-once-upon-a-time-children-loop-384715.mp3',
                'tags'         => 'Gentle,Playful,Whimsical,Imaginative,Adventurous,Curious',
                'tempo'        => 'moderate',
                'duration_secs'=> 220,
            ],
        ];

        foreach ($tracks as $data) {
            MusicTrack::firstOrCreate(
                ['title' => $data['title'], 'composer' => $data['composer']],
                array_merge($data, ['track_id' => (string) Str::uuid()])
            );
        }
    }
}
