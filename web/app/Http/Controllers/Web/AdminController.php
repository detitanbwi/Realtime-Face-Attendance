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
        $faceTokens = \App\Models\RegistrationToken::all();

        return view('admin.dashboard', compact('attendances', 'faceLogs', 'faceUsers', 'faceTokens'));
    }

    public function generateFaceToken(Request $request)
    {
        $request->validate([
            'token_type' => 'required|string|in:unlimited,duration,date',
            'max_usage' => 'nullable|integer|min:1',
            'duration_hours' => 'nullable|integer|min:1',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        $tokenStr = strtoupper(\Illuminate\Support\Str::random(5));
        $data = ['token' => $tokenStr, 'max_usage' => $request->max_usage];

        if ($request->token_type == 'duration') {
            $data['valid_from'] = now();
            $data['valid_until'] = now()->addHours($request->duration_hours ?? 1);
        } elseif ($request->token_type == 'date') {
            $data['valid_from'] = $request->start_date;
            $data['valid_until'] = $request->end_date;
        }

        \App\Models\RegistrationToken::create($data);

        return back()->with('success', "Token pendaftaran wajah baru berhasil dibuat: $tokenStr");
    }

    public function deleteFaceToken($id)
    {
        $token = \App\Models\RegistrationToken::findOrFail($id);
        $token->delete();
        return back()->with('success', "Token {$token->token} berhasil dihapus.");
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect('/admin/login');
    }
}
