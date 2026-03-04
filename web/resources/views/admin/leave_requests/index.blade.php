@extends('admin.layouts.app')

@section('content')
    <div class="mb-8 flex justify-between items-end">
        <div>
            <h1 class="text-2xl font-bold text-gray-900">Approval Izin / Cuti</h1>
            <p class="text-sm text-gray-500 mt-1">Review dan kelola permohonan izin day off pegawai.</p>
        </div>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th scope="col"
                            class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tanggal
                            Pengajuan</th>
                        <th scope="col"
                            class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Pegawai
                        </th>
                        <th scope="col"
                            class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Jenis
                            Izin</th>
                        <th scope="col"
                            class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Rentang
                            Tanggal</th>
                        <th scope="col"
                            class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Alasan
                        </th>
                        <th scope="col"
                            class="px-6 py-4 text-center text-xs font-semibold text-gray-500 uppercase tracking-wider">
                            Status</th>
                        <th scope="col"
                            class="px-6 py-4 text-center text-xs font-semibold text-gray-500 uppercase tracking-wider">Aksi
                        </th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    @forelse($requests as $req)
                                <tr class="hover:bg-gray-50 transition">
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                        {{ $req->created_at->format('d M Y H:i') }}</td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm text-gray-900 font-medium">{{ optional($req->user)->name ?? 'Unknown' }}
                                        </div>
                                        <div class="text-xs text-gray-500">{{ optional($req->user)->id_pegawai ?? '-' }}</div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ $req->type }}</td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                                        {{ \Carbon\Carbon::parse($req->start_date)->format('d M Y') }} -
                                        {{ \Carbon\Carbon::parse($req->end_date)->format('d M Y') }}
                                    </td>
                                    <td class="px-6 py-4 text-sm text-gray-600 max-w-xs truncate" title="{{ $req->reason }}">
                                        {{ $req->reason ?? '-' }}
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-center text-sm">
                                        <span
                                            class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold 
                                                {{ $req->status == 'approved' ? 'bg-green-100 text-green-800' :
                        ($req->status == 'rejected' ? 'bg-red-100 text-red-800' : 'bg-orange-100 text-orange-800') }}">
                                            {{ strtoupper($req->status) }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-center">
                                        @if($req->status == 'pending')
                                            <div class="flex justify-center space-x-2">
                                                <form action="{{ route('leave.approve', $req->id) }}" method="POST">
                                                    @csrf
                                                    <button type="submit"
                                                        class="text-white bg-green-500 hover:bg-green-600 px-3 py-1 rounded-md text-xs font-bold transition">Setujui</button>
                                                </form>
                                                <form action="{{ route('leave.reject', $req->id) }}" method="POST">
                                                    @csrf
                                                    <button type="submit"
                                                        class="text-white bg-red-500 hover:bg-red-600 px-3 py-1 rounded-md text-xs font-bold transition">Tolak</button>
                                                </form>
                                            </div>
                                        @else
                                            <span class="text-gray-400 text-xs italic">Selesai</span>
                                        @endif
                                    </td>
                                </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="px-6 py-8 text-center text-sm text-gray-500">
                                Belum ada permohonan izin cuti / day off.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection