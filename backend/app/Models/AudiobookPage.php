<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AudiobookPage extends Model
{
    use HasFactory;
    use HasUuids;

    protected $table = 'audiobook_pages';
    protected $primaryKey = 'page_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'audiobook_id',
        'page_number',
        'text',
        'image',
    ];

    protected $casts = [
        'page_number' => 'integer',
    ];

    public function uniqueIds(): array
    {
        return ['page_id'];
    }

    public function audiobook(): BelongsTo
    {
        return $this->belongsTo(Audiobook::class, 'audiobook_id', 'audiobook_id');
    }
}
