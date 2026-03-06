<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RegistrationToken extends Model
{
    protected $fillable = [
        'token',
        'valid_from',
        'valid_until',
        'max_usage',
        'current_usage',
    ];

    protected $casts = [
        'valid_from' => 'datetime',
        'valid_until' => 'datetime',
        'max_usage' => 'integer',
        'current_usage' => 'integer',
    ];
}
