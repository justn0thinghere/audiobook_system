<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Latest cache of Gemini's listening-behaviour analysis for one child (UC-9).
 * The `items` JSON holds the list of suggestions with per-item status; the
 * caregiver resolves each one with accept / edit / dismiss in UC-10.
 */
class AiSuggestion extends Model
{
    use HasFactory;
    use HasUuids;

    protected $table = 'ai_suggestions';
    protected $primaryKey = 'suggestion_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'child_id',
        'source_stats',
        'items',
        'confidence',
        'is_stale',
        'generated_at',
    ];

    protected $casts = [
        'source_stats' => 'array',
        'items'        => 'array',
        'is_stale'     => 'boolean',
        'generated_at' => 'datetime',
    ];

    public function uniqueIds(): array
    {
        return ['suggestion_id'];
    }

    public function child(): BelongsTo
    {
        return $this->belongsTo(ChildProfile::class, 'child_id', 'child_id');
    }
}
