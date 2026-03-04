<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttendanceLog extends Model
{
    protected $fillable = [
        'face_registration_id',
        'check_in_time',
        'latitude',
        'longitude',
    ];

    protected $casts = [
        'check_in_time' => 'datetime',
    ];

    public function faceRegistration()
    {
        return $this->belongsTo(FaceRegistration::class);
    }
}
