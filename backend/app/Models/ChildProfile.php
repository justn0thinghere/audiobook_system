<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ChildProfile extends Model
{
    use HasFactory;
    use HasUuids;

    protected $table = 'child_profiles';
    protected $primaryKey = 'child_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'caregiver_id',
        'name',
        'age',
        'avatar_emoji',
        'avatar_color',
        'favorite_genre',
        'listening_minutes',
    ];

    protected $casts = [
        'age' => 'integer',
        'listening_minutes' => 'integer',
    ];

    public function uniqueIds(): array
    {
        return ['child_id'];
    }

    public function caregiver(): BelongsTo
    {
        return $this->belongsTo(Caregiver::class, 'caregiver_id', 'caregiver_id');
    }

    public function listeningHistory(): HasMany
    {
        return $this->hasMany(ListeningHistory::class, 'child_id', 'child_id');
    }

    public function childSettings(): HasOne
    {
        return $this->hasOne(ChildSettings::class, 'child_id', 'child_id');
    }
}
