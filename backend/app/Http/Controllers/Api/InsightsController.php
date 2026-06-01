<?php

namespace App\Http\Controllers\Api;

use App\Models\ListeningHistory;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InsightsController extends ApiController
{
    private const TZ = 'Asia/Kuala_Lumpur';

    /**
     * Aggregated listening insights for the signed-in caregiver:
     *  - overall totals (sessions, minutes, completion rate, top mood)
     *  - avg session length, current daily streak
     *  - last-7-days minutes per day (for a small bar chart)
     *  - top stories by total listening time
     *  - recent activity feed
     *  - per-child breakdown (same fields, scoped per child)
     */
    public function overview(Request $request): JsonResponse
    {
        $caregiver = $request->get('auth_caregiver');
        // The 'children' list always carries every profile (the UI's selector
        // needs them all); $scopedProfiles is what each per-child / aggregate
        // query iterates over, optionally narrowed to one child via ?child_id=.
        $allProfiles = $caregiver->childProfiles()->orderBy('created_at')->get();
        $filterChildId = $request->input('child_id');
        $scopedProfiles = $filterChildId
            ? $allProfiles->where('child_id', $filterChildId)->values()
            : $allProfiles;
        if ($filterChildId && $scopedProfiles->isEmpty()) {
            return $this->errorResponse('Child profile not found', 'NOT_FOUND', 404);
        }
        $profiles = $scopedProfiles;
        $childIds = $profiles->pluck('child_id')->all();

        $now = Carbon::now(self::TZ);
        $week = $this->emptyWeek($now);

        $moods = ['happy', 'calm', 'curious', 'sleepy'];
        $moodTotals = array_fill_keys($moods, 0);

        $totalMinutes = 0;
        $totalSeconds = 0;
        $totalSessions = 0;
        $totalCompleted = 0;
        $children = [];

        foreach ($profiles as $p) {
            $sessions = $p->listeningHistory()
                ->orderByDesc('created_at')
                ->get();
            $count = $sessions->count();
            $completed = $sessions->where('completed', true)->count();
            $childSeconds = (int) $sessions->sum('duration_seconds');
            $childMinutes = (int) $p->listening_minutes;

            $totalMinutes += $childMinutes;
            $totalSeconds += $childSeconds;
            $totalSessions += $count;
            $totalCompleted += $completed;

            $childMoods = array_fill_keys($moods, 0);
            $childDays = [];
            foreach ($sessions as $s) {
                if ($s->mood && isset($childMoods[$s->mood])) {
                    $childMoods[$s->mood]++;
                    $moodTotals[$s->mood]++;
                }
                $dayKey = $this->dayKey($s->created_at);
                $childDays[$dayKey] = true;
                if (isset($week[$dayKey])) {
                    $week[$dayKey]['minutes'] += (int) round($s->duration_seconds / 60);
                }
            }

            $children[] = [
                'child_id'            => $p->child_id,
                'name'                => $p->name,
                'avatar_emoji'        => $p->avatar_emoji,
                'avatar_color'        => $p->avatar_color,
                'favorite_genre'      => $p->favorite_genre,
                'listening_minutes'   => $childMinutes,
                'sessions'            => $count,
                'completed'           => $completed,
                'completion_rate'     => $count > 0 ? (int) round($completed / $count * 100) : 0,
                'top_mood'            => $this->topMood($childMoods),
                'avg_session_minutes' => $count > 0 ? round($childSeconds / $count / 60, 1) : 0.0,
                'streak_days'         => $this->computeStreak(array_keys($childDays), $now),
            ];
        }

        $allDayKeys = $this->collectDayKeys($childIds);

        return $this->successResponse('OK', [
            'total_children'          => $profiles->count(),
            'total_listening_minutes' => $totalMinutes,
            'total_sessions'          => $totalSessions,
            'completed_sessions'      => $totalCompleted,
            'completion_rate'         => $totalSessions > 0
                ? (int) round($totalCompleted / $totalSessions * 100)
                : 0,
            'top_mood'                => $this->topMood($moodTotals),
            'mood_breakdown'          => $moodTotals,
            'avg_session_minutes'     => $totalSessions > 0
                ? round($totalSeconds / $totalSessions / 60, 1)
                : 0.0,
            'streak_days'             => $this->computeStreak($allDayKeys, $now),
            'last_seven_days'         => array_values($week),
            'top_stories'             => $this->topStories($childIds),
            'recent_sessions'         => $this->recentSessions($childIds),
            'children'                => $children,
        ]);
    }

    /** Build [date=>['date','day','minutes'=>0], …] for the last 7 days (oldest first). */
    private function emptyWeek(Carbon $now): array
    {
        $week = [];
        for ($i = 6; $i >= 0; $i--) {
            $d = $now->copy()->subDays($i)->startOfDay();
            $week[$d->format('Y-m-d')] = [
                'date'    => $d->format('Y-m-d'),
                'day'     => $d->format('D'),
                'minutes' => 0,
            ];
        }
        return $week;
    }

    /** Convert a timestamp to a Y-m-d key in the caregiver-facing timezone. */
    private function dayKey($ts): string
    {
        return Carbon::parse($ts)->setTimezone(self::TZ)->format('Y-m-d');
    }

    /** All distinct days (in local timezone) on which the caregiver's children listened. */
    private function collectDayKeys(array $childIds): array
    {
        if (empty($childIds)) {
            return [];
        }
        return ListeningHistory::query()
            ->whereIn('child_id', $childIds)
            ->orderByDesc('created_at')
            ->pluck('created_at')
            ->map(fn ($ts) => $this->dayKey($ts))
            ->unique()
            ->values()
            ->all();
    }

    /**
     * Current daily streak: how many consecutive days ending today have a
     * session. Falls through to "ending yesterday" so a streak isn't lost
     * just because the child hasn't listened yet today.
     */
    private function computeStreak(array $distinctDayKeys, Carbon $now): int
    {
        if (empty($distinctDayKeys)) {
            return 0;
        }
        $set = array_flip($distinctDayKeys);
        $cursor = $now->copy()->startOfDay();
        // If today has no session yet, start counting from yesterday.
        if (!isset($set[$cursor->format('Y-m-d')])) {
            $cursor->subDay();
        }
        $streak = 0;
        while (isset($set[$cursor->format('Y-m-d')])) {
            $streak++;
            $cursor->subDay();
        }
        return $streak;
    }

    /** Top 5 audiobooks by total minutes played across this caregiver's children. */
    private function topStories(array $childIds): array
    {
        if (empty($childIds)) {
            return [];
        }
        return ListeningHistory::query()
            ->whereIn('listening_history.child_id', $childIds)
            ->leftJoin('audiobooks', 'listening_history.audiobook_id', '=', 'audiobooks.audiobook_id')
            ->selectRaw(
                'listening_history.audiobook_id as audiobook_id, '
                . 'MAX(audiobooks.title) as title, '
                . 'MAX(audiobooks.cover_image) as cover_image, '
                . 'SUM(duration_seconds) as secs, '
                . 'COUNT(*) as plays'
            )
            ->groupBy('listening_history.audiobook_id')
            ->orderByDesc('secs')
            ->limit(5)
            ->get()
            ->map(fn ($r) => [
                'audiobook_id' => $r->audiobook_id,
                'title'        => $r->title ?? 'Untitled',
                'cover_image'  => $this->mediaUrl($r->cover_image),
                'minutes'      => (int) round(((int) $r->secs) / 60),
                'plays'        => (int) $r->plays,
            ])
            ->toArray();
    }

    /** Most recent 10 listening sessions across this caregiver's children. */
    private function recentSessions(array $childIds): array
    {
        if (empty($childIds)) {
            return [];
        }
        return ListeningHistory::query()
            ->whereIn('listening_history.child_id', $childIds)
            ->leftJoin('audiobooks', 'listening_history.audiobook_id', '=', 'audiobooks.audiobook_id')
            ->leftJoin('child_profiles', 'listening_history.child_id', '=', 'child_profiles.child_id')
            ->orderByDesc('listening_history.created_at')
            ->limit(10)
            ->select([
                'listening_history.history_id as history_id',
                'listening_history.child_id as child_id',
                'listening_history.audiobook_id as audiobook_id',
                'listening_history.duration_seconds as duration_seconds',
                'listening_history.completed as completed',
                'listening_history.mood as mood',
                'listening_history.created_at as created_at',
                'audiobooks.title as audiobook_title',
                'audiobooks.cover_image as audiobook_cover',
                'child_profiles.name as child_name',
                'child_profiles.avatar_emoji as child_emoji',
                'child_profiles.avatar_color as child_color',
            ])
            ->get()
            ->map(fn ($r) => [
                'history_id'       => $r->history_id,
                'child_id'         => $r->child_id,
                'child_name'       => $r->child_name ?? '—',
                'child_emoji'      => $r->child_emoji ?? '🌟',
                'child_color'      => $r->child_color ?? '#F5D5DD',
                'audiobook_id'     => $r->audiobook_id,
                'audiobook_title'  => $r->audiobook_title ?? 'Untitled',
                'cover_image'      => $this->mediaUrl($r->audiobook_cover),
                'duration_minutes' => (int) round(((int) $r->duration_seconds) / 60),
                'completed'        => (bool) $r->completed,
                'mood'             => $r->mood,
                'at'               => Carbon::parse($r->created_at)
                    ->setTimezone(self::TZ)
                    ->format('Y-m-d H:i'),
            ])
            ->toArray();
    }

    /**
     * Locally-stored media (e.g. "storage/uploads/...") is made absolute;
     * values that already look like full URLs (Pollinations/Gemini images)
     * pass through unchanged.
     */
    /**
     * Build an absolute URL for a stored relative path using the incoming
     * request's host (not APP_URL), so the URL is always reachable by the
     * client that asked — emulator, real device, anything. See the longer
     * comment on AudiobookController::mediaUrl for the rationale.
     */
    private function mediaUrl(?string $path): ?string
    {
        if ($path === null || $path === '') {
            return null;
        }
        if (\Illuminate\Support\Str::startsWith($path, ['http://', 'https://'])) {
            return $path;
        }
        $base = rtrim(request()->getSchemeAndHttpHost(), '/');
        return $base . '/' . ltrim($path, '/');
    }

    /** Returns the mood name with the highest count, or null if all are zero. */
    private function topMood(array $counts): ?string
    {
        arsort($counts);
        $top = array_key_first($counts);
        return ($top !== null && $counts[$top] > 0) ? $top : null;
    }
}
