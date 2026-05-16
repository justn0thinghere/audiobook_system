<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Facades\Hash;

class Caregiver extends Model
{
    use HasFactory;
    use HasUuids;

    protected $table = 'caregivers';
    protected $primaryKey = 'caregiver_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'name',
        'email',
        'mobile_number',
        'pin',
        'device_id',
        'device_name',
        'fcm_token',
        'session_token',
        'session_expires',
        'is_active',
        'last_login_at',
    ];

    protected $hidden = [
        'pin',
        'session_token',
        'fcm_token',
    ];

    protected $casts = [
        'session_expires' => 'datetime',
        'last_login_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    /**
     * Columns that should receive auto-generated UUIDs on creation.
     */
    public function uniqueIds(): array
    {
        return ['caregiver_id'];
    }

    public function setPinAttribute(string $value): void
    {
        // If a 60-char bcrypt hash is passed in (during re-hydration), keep it.
        $this->attributes['pin'] = strlen($value) === 60 && str_starts_with($value, '$2y$')
            ? $value
            : Hash::make($value);
    }

    public function verifyPin(string $plainPin): bool
    {
        return Hash::check($plainPin, $this->pin);
    }

    public function childProfiles(): HasMany
    {
        return $this->hasMany(ChildProfile::class, 'caregiver_id', 'caregiver_id');
    }

    public function settings(): HasOne
    {
        return $this->hasOne(CaregiverSettings::class, 'caregiver_id', 'caregiver_id');
    }
}
