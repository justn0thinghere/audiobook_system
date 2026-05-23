<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InsightsController extends Controller
{
    /**
     * Aggregated listening insights for the signed-in caregiver:
     * overall totals plus a per-child breakdown built from listening_history.
     */
    public function overview(Request $request): JsonResponse
    {
        $caregiver = $request->get('auth_caregiver');
        $profiles = $caregiver->childProfiles()->orderBy('created_at')->get();

        $moods = ['happy', 'calm', 'curious', 'sleepy'];
        $moodTotals = array_fill_keys($moods, 0);

        $totalMinutes = 0;
        $totalSessions = 0;
        $totalCompleted = 0;
        $children = [];

        foreach ($profiles as $p) {
            $sessions = $p->listeningHistory()->get();
            $count = $sessions->count();
            $completed = $sessions->where('completed', true)->count();
            $minutes = (int) $p->listening_minutes;

            $totalMinutes += $minutes;
            $totalSessions += $count;
            $totalCompleted += $completed;

            $childMoods = array_fill_keys($moods, 0);
            foreach ($sessions as $s) {
                if ($s->mood && isset($childMoods[$s->mood])) {
                    $childMoods[$s->mood]++;
                    $moodTotals[$s->mood]++;
                }
            }

            $children[] = [
                'child_id'          => $p->child_id,
                'name'              => $p->name,
                'avatar_emoji'      => $p->avatar_emoji,
                'avatar_color'      => $p->avatar_color,
                'favorite_genre'    => $p->favorite_genre,
                'listening_minutes' => $minutes,
                'sessions'          => $count,
                'completed'         => $completed,
                'completion_rate'   => $count > 0 ? (int) round($completed / $count * 100) : 0,
                'top_mood'          => $this->topMood($childMoods),
            ];
        }

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
            'children'                => $children,
        ]);
    }

    /**
     * Returns the mood name with the highest count, or null if all are zero.
     */
    private function topMood(array $counts): ?string
    {
        arsort($counts);
        $top = array_key_first($counts);
        return ($top !== null && $counts[$top] > 0) ? $top : null;
    }
}
