<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FaceRegistration extends Model
{
    protected $fillable = [
        'token',
        'is_used',
        'name',
        'nia',
        'face_embedding',
        'address',
        'birth_date',
    ];

    protected $casts = [
        'is_used' => 'boolean',
        'face_embedding' => 'array',
        'birth_date' => 'date',
    ];

    public function attendanceLogs()
    {
        return $this->hasMany(AttendanceLog::class);
    }
}
