<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\FaceRegistration;
use App\Models\AttendanceLog;

class AttendanceApiController extends Controller
{
    public function verifyToken(Request $request)
    {
        $token = FaceRegistration::where('token', $request->token)->where('is_used', false)->first();
        if (!$token)
            return response()->json(['error' => 'Token invalid or used'], 400);
        return response()->json(['message' => 'Token valid']);
    }

    public function registerFace(Request $request)
    {
        $request->validate([
            'token' => 'required',
            'name' => 'required|string',
            'nia' => 'nullable|string|max:7',
            'face_embedding' => 'required|array',
            'address' => 'required|string',
            'birth_date' => 'required|date'
        ]);

        $reg = FaceRegistration::where('token', $request->token)->where('is_used', false)->first();
        if (!$reg)
            return response()->json(['error' => 'Token invalid or used'], 400);

        if ($request->nia && FaceRegistration::where('nia', $request->nia)->exists()) {
            return response()->json(['error' => 'NIA already registered'], 400);
        }

        $reg->update([
            'name' => $request->name,
            'nia' => $request->nia,
            'face_embedding' => $request->face_embedding,
            'address' => $request->address,
            'birth_date' => $request->birth_date,
            'is_used' => true
        ]);

        return response()->json(['message' => 'Registration successful']);
    }

    public function getSyncData()
    {
        $users = FaceRegistration::where('is_used', true)->get(['id', 'name', 'nia', 'face_embedding']);
        return response()->json(['data' => $users]);
    }

    public function logAttendance(Request $request)
    {
        $request->validate([
            'face_registration_id' => 'required|exists:face_registrations,id',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        // Check if already attended today
        $existingLog = AttendanceLog::where('face_registration_id', $request->face_registration_id)
            ->whereDate('check_in_time', now()->toDateString())
            ->first();

        if ($existingLog) {
            $reg = FaceRegistration::find($request->face_registration_id);
            return response()->json([
                'already_attended' => true,
                'message' => 'Sudah absen hari ini',
                'name' => $reg->name ?? '-',
                'nia' => $reg->nia ?? '-',
                'check_in_time' => $existingLog->check_in_time->format('H:i'),
            ], 200);
        }

        AttendanceLog::create([
            'face_registration_id' => $request->face_registration_id,
            'check_in_time' => now(),
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
        ]);
        return response()->json(['message' => 'Attendance logged', 'already_attended' => false]);
    }
}
