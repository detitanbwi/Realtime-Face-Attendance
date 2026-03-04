<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use Illuminate\Http\Request;

class LeaveRequestController extends Controller
{
    public function index()
    {
        $requests = LeaveRequest::with('user')->orderBy('created_at', 'desc')->get();
        return view('admin.leave_requests.index', compact('requests'));
    }

    public function approve($id)
    {
        $request = LeaveRequest::findOrFail($id);
        $request->update(['status' => 'approved']);
        return back()->with('success', 'Permohonan cuti disetujui');
    }

    public function reject($id)
    {
        $request = LeaveRequest::findOrFail($id);
        $request->update(['status' => 'rejected']);
        return back()->with('success', 'Permohonan cuti ditolak');
    }
}
