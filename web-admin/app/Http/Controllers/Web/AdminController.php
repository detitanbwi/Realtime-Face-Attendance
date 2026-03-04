<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Attendance;

class AdminController extends Controller
{
    public function showLogin()
    {
        return view('admin.login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'id_pegawai' => 'required',
            'password' => 'required',
        ]);

        if (Auth::attempt($credentials)) {
            if (Auth::user()->role === 'admin') {
                $request->session()->regenerate();
                return redirect()->intended('admin/dashboard');
            }
            Auth::logout();
            return back()->withErrors(['id_pegawai' => 'Hanya admin yang dapat mengakses halaman ini.']);
        }

        return back()->withErrors(['id_pegawai' => 'Kredensial tidak valid.']);
    }

    public function dashboard()
    {
        $attendances = Attendance::with('user')->orderBy('date', 'desc')->orderBy('time_in', 'desc')->get();
        // Face Authentication Data
        $faceLogs = \App\Models\AttendanceLog::with('faceRegistration')->whereDate('check_in_time', today())->get();
        $faceUsers = \App\Models\FaceRegistration::where('is_used', true)->get();
        $faceTokens = \App\Models\FaceRegistration::where('is_used', false)->get();

        return view('admin.dashboard', compact('attendances', 'faceLogs', 'faceUsers', 'faceTokens'));
    }

    public function generateFaceToken()
    {
        $token = strtoupper(\Illuminate\Support\Str::random(8));
        \App\Models\FaceRegistration::create(['token' => $token]);
        return back()->with('success', "Token pendaftaran wajah baru berhasil dibuat: $token");
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect('/admin/login');
    }
}
