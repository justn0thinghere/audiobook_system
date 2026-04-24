<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Audiobook extends Model
{
    use HasFactory;

    protected $table = 'audiobooks';

    protected $fillable = [
        'title',
        'author',
        'description',
        'topic',
        'category',
        'difficulty',
        'type',
        'content_text',
        'audio_file',
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
}