<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use Illuminate\Support\Str;
use App\Models\FaceRegistration;
use App\Models\AttendanceLog;

class DashboardController extends Controller
{
    public function index()
    {
        $logs = AttendanceLog::with('faceRegistration')->whereDate('check_in_time', today())->get();
        $users = FaceRegistration::where('is_used', true)->get();
        return view('admin.dashboard', compact('logs', 'users'));
    }

    public function generateToken()
    {
        $token = strtoupper(Str::random(8));
        FaceRegistration::create(['token' => $token]);
        return back()->with('success', "Token created: $token");
    }
}
