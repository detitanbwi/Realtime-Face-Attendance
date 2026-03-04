<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use Illuminate\Http\Request;
use Carbon\Carbon;

class AttendanceController extends Controller
{
    public function checkIn(Request $request)
    {
        $request->validate([
            'lat' => 'required',
            'long' => 'required',
        ]);

        $user = $request->user();
        $today = Carbon::today()->toDateString();

        $attendance = Attendance::where('user_id', $user->id)
            ->where('date', $today)
            ->first();

        if ($attendance) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah melakukan check-in hari ini.'
            ], 400);
        }

        $newAttendance = Attendance::create([
            'user_id' => $user->id,
            'date' => $today,
            'time_in' => Carbon::now()->toTimeString(),
            'lat_in' => $request->lat,
            'long_in' => $request->long,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Check-in berhasil.',
            'data' => $newAttendance
        ]);
    }

    public function checkOut(Request $request)
    {
        $request->validate([
            'lat' => 'required',
            'long' => 'required',
        ]);

        $user = $request->user();
        $today = Carbon::today()->toDateString();

        $attendance = Attendance::where('user_id', $user->id)
            ->where('date', $today)
            ->first();

        if (!$attendance) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum melakukan check-in hari ini.'
            ], 400);
        }

        if ($attendance->time_out) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah melakukan check-out hari ini.'
            ], 400);
        }

        $attendance->update([
            'time_out' => Carbon::now()->toTimeString(),
            'lat_out' => $request->lat,
            'long_out' => $request->long,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Check-out berhasil.',
            'data' => $attendance
        ]);
    }

    public function history(Request $request)
    {
        $user = $request->user();
        $history = Attendance::where('user_id', $user->id)
            ->orderBy('date', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Data riwayat absensi',
            'data' => $history
        ]);
    }
}
