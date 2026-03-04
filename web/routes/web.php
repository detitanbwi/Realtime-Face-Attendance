<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\AdminController;
use App\Http\Controllers\Web\UserController;
use App\Http\Controllers\Web\LeaveRequestController;

Route::get('/', function () {
    return redirect('/admin/login');
});

Route::get('/admin/login', [AdminController::class, 'showLogin'])->name('login');
Route::post('/admin/login', [AdminController::class, 'login']);

Route::middleware(['auth'])->group(function () {
    Route::get('/admin/dashboard', [AdminController::class, 'dashboard'])->name('dashboard');
    Route::post('/admin/face-token/generate', [AdminController::class, 'generateFaceToken'])->name('face.token.generate');
    Route::delete('/admin/face-token/{id}', [AdminController::class, 'deleteFaceToken'])->name('face.token.delete');
    Route::post('/admin/logout', [AdminController::class, 'logout'])->name('logout');

    Route::get('/admin/users', [UserController::class, 'index'])->name('users.index');
    Route::post('/admin/users', [UserController::class, 'store'])->name('users.store');
    Route::post('/admin/users/{id}/reset', [UserController::class, 'resetPassword'])->name('users.reset');

    Route::get('/admin/leave-requests', [LeaveRequestController::class, 'index'])->name('leave.index');
    Route::post('/admin/leave-requests/{id}/approve', [LeaveRequestController::class, 'approve'])->name('leave.approve');
    Route::post('/admin/leave-requests/{id}/reject', [LeaveRequestController::class, 'reject'])->name('leave.reject');
});
