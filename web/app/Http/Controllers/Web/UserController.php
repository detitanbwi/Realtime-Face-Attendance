<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserController extends Controller
{
    public function index()
    {
        $users = User::all();
        return view('admin.users.index', compact('users'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'id_pegawai' => 'required|unique:users',
            'role' => 'required'
        ]);

        User::create([
            'name' => $request->name,
            'id_pegawai' => $request->id_pegawai,
            'password' => Hash::make('password'),
            'role' => $request->role,
        ]);

        return back()->with('success', 'User berhasil ditambahkan dengan password default: password');
    }

    public function resetPassword($id)
    {
        $user = User::findOrFail($id);
        $user->update(['password' => Hash::make('password')]);
        return back()->with('success', 'Password user ' . $user->name . ' berhasil direset menjadi "password"');
    }
}
