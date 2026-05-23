<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Audiobook extends Model
{
    use HasFactory;

    protected $table = 'audiobooks';

    protected $fillable = [
        'audiobook_id',
        'title',
        'author',
        'description',
        'topic',
        'category',
        'difficulty',
        'type',
        'content_text',
        'audio_file',
        'video_file',
        'source_file',
        'cover_image',
        'duration_minutes',
        'language',
        'age_group',
        'tags',
        'is_generated',
        'is_user_uploaded',
        'status',
    ];

    protected $casts = [
        'is_generated' => 'boolean',
        'is_user_uploaded' => 'boolean',
        'duration_minutes' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($model) {
            if (!$model->audiobook_id) {
                $model->audiobook_id = (string) Str::uuid();
            }
        });
    }

    public function listeningHistory(): HasMany
    {
        return $this->hasMany(ListeningHistory::class, 'audiobook_id', 'audiobook_id');
    }

    public function pages(): HasMany
    {
        return $this->hasMany(AudiobookPage::class, 'audiobook_id', 'audiobook_id')
            ->orderBy('page_number');
    }
}