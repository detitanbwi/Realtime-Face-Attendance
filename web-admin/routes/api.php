<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\LeaveRequestController;
use App\Http\Controllers\Api\AttendanceApiController;

Route::post('/login', [AuthController::class, 'login']);

// Face Authentication endpoints (Public endpoints because it uses custom FaceTokens from Admin)
Route::post('/verify-token', [AttendanceApiController::class, 'verifyToken']);
Route::post('/register-face', [AttendanceApiController::class, 'registerFace']);
Route::get('/sync-data', [AttendanceApiController::class, 'getSyncData']);
Route::post('/log-attendance', [AttendanceApiController::class, 'logAttendance']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/attendance/check-in', [AttendanceController::class, 'checkIn']);
    Route::post('/attendance/check-out', [AttendanceController::class, 'checkOut']);
    Route::get('/attendance/history', [AttendanceController::class, 'history']);
    Route::post('/update-profile', [AuthController::class, 'updateProfile']);

    Route::get('/leave-requests', [LeaveRequestController::class, 'index']);
    Route::post('/leave-requests', [LeaveRequestController::class, 'store']);
});
