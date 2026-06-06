<?php

namespace App\Http\Controllers\Api;

use App\Models\MusicTrack;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MusicTrackController extends ApiController
{
    /**
     * List active music tracks. Supports optional tag-combo filter and title
     * search. Returns tracks matching ALL selected tags (intersection).
     *
     * POST /music-tracks/list
     * Body: { tags?: string[], search?: string }
     */
    public function list(Request $request): JsonResponse
    {
        $this->logEvent('MusicTrack', 'list called', [
            'tags'   => $request->input('tags'),
            'search' => $request->input('search'),
        ]);

        $tracks = MusicTrack::where('status', 'active')->get();

        // Tag filter: every requested tag must be present on the track.
        $filterTags = $request->input('tags', []);
        if (is_array($filterTags) && count($filterTags) > 0) {
            $tracks = $tracks->filter(function (MusicTrack $t) use ($filterTags) {
                $trackTags = array_map('strtolower', $t->tagsArray());
                foreach ($filterTags as $ft) {
                    if (!in_array(strtolower(trim($ft)), $trackTags, true)) {
                        return false;
                    }
                }
                return true;
            });
        }

        // Title/composer search.
        $search = trim((string) $request->input('search', ''));
        if ($search !== '') {
            $lower = strtolower($search);
            $tracks = $tracks->filter(function (MusicTrack $t) use ($lower) {
                $label = strtolower($t->title . '-' . $t->composer);
                return str_contains($label, $lower);
            });
        }

        return $this->successResponse('OK', [
            'tracks' => $tracks->values()->map(fn ($t) => $this->serialize($t)),
        ]);
    }

    /**
     * Return all distinct tags that appear on active tracks, sorted.
     * Used to populate the filter chips in the picker UI.
     *
     * POST /music-tracks/tags
     */
    public function allTags(): JsonResponse
    {
        $this->logEvent('MusicTrack', 'allTags called');

        $tags = MusicTrack::where('status', 'active')
            ->pluck('tags')
            ->flatMap(fn ($t) => array_map('trim', explode(',', $t)))
            ->filter()
            ->unique()
            ->sort()
            ->values();

        return $this->successResponse('OK', ['tags' => $tags]);
    }

    /**
     * Given a set of currently-selected tags, return only the tags that still
     * form a valid combination (i.e. at least one active track has ALL of the
     * selected tags PLUS the candidate tag). This drives the "hide impossible
     * tags" behaviour in the picker UI.
     *
     * POST /music-tracks/compatible-tags
     * Body: { selected_tags: string[] }
     */
    public function compatibleTags(Request $request): JsonResponse
    {
        $selected = $request->input('selected_tags', []);

        $active = MusicTrack::where('status', 'active')->get();

        // Tracks that already match the current selection.
        $matching = $active->filter(function (MusicTrack $t) use ($selected) {
            $tt = array_map('strtolower', $t->tagsArray());
            foreach ($selected as $s) {
                if (!in_array(strtolower(trim($s)), $tt, true)) {
                    return false;
                }
            }
            return true;
        });

        // Tags that appear on at least one matching track (excluding already-
        // selected ones so they don't get shown as available to add again).
        $selectedLower = array_map('strtolower', array_map('trim', $selected));

        $compatible = $matching
            ->flatMap(fn ($t) => $t->tagsArray())
            ->map(fn ($t) => trim($t))
            ->filter(fn ($t) => !in_array(strtolower($t), $selectedLower, true))
            ->unique()
            ->sort()
            ->values();

        return $this->successResponse('OK', ['tags' => $compatible]);
    }

    private function serialize(MusicTrack $t): array
    {
        return [
            'track_id'      => $t->track_id,
            'title'         => $t->title,
            'composer'      => $t->composer,
            'file_url'      => url($t->file_path),
            'tags'          => $t->tagsArray(),
            'tempo'         => $t->tempo,
            'duration_secs' => $t->duration_secs,
        ];
    }
}
