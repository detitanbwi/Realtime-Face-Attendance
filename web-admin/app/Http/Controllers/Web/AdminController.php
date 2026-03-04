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
        return view('admin.dashboard', compact('attendances'));
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect('/admin/login');
    }
}
