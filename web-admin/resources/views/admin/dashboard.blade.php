@extends('admin.layouts.app')

@section('content')
    <div class="mb-8 flex justify-between items-end">
        <div>
            <h1 class="text-2xl font-bold text-gray-900">Data Absensi Pegawai</h1>
            <p class="text-sm text-gray-500 mt-1">Pantau rekapan clock-in dan clock-out secara real-time.</p>
        </div>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th scope="col"
                            class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tanggal
                        </th>
                        <th scope="col"
                            class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Pegawai
                        </th>
                        <th scope="col"
                            class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Waktu
                            Masuk</th>
                        <th scope="col"
                            class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Lokasi
                            Masuk (Lat, Long)</th>
                        <th scope="col"
                            class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Waktu
                            Keluar</th>
                        <th scope="col"
                            class="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Lokasi
                            Keluar (Lat, Long)</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    @forelse($attendances as $absen)
                        <tr class="hover:bg-gray-50 transition">
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-medium">
                                {{ \Carbon\Carbon::parse($absen->date)->format('d M Y') }}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900 font-medium">
                                    {{ optional($absen->user)->name ?? 'Unknown' }}
                                </div>
                                <div class="text-xs text-gray-500">{{ optional($absen->user)->id_pegawai ?? '-' }}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                                @if($absen->time_in)
                                    <span
                                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                                        {{ \Carbon\Carbon::parse($absen->time_in)->format('H:i') }}
                                    </span>
                                @else
                                    <span class="text-gray-400">-</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-xs text-gray-500">
                                @if($absen->lat_in && $absen->long_in)
                                    <div class="flex items-center gap-2">
                                        <span class="truncate max-w-[100px]"
                                            title="{{ $absen->lat_in }}, {{ $absen->long_in }}">{{ $absen->lat_in }},
                                            {{ $absen->long_in }}</span>
                                        <a href="https://www.google.com/maps/search/?api=1&query={{ $absen->lat_in }},{{ $absen->long_in }}"
                                            target="_blank"
                                            class="text-blue-600 hover:text-blue-800 bg-blue-50 hover:bg-blue-100 flex items-center justify-center h-6 w-6 rounded-md transition-colors"
                                            title="Lihat di Maps">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                                                stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                                            </svg>
                                        </a>
                                    </div>
                                @else
                                    <span class="text-gray-400">-</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                                @if($absen->time_out)
                                    <span
                                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                                        {{ \Carbon\Carbon::parse($absen->time_out)->format('H:i') }}
                                    </span>
                                @else
                                    <span
                                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-600">
                                        Belum Keluar
                                    </span>
                                @endif
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-xs text-gray-500">
                                @if($absen->lat_out && $absen->long_out)
                                    <div class="flex items-center gap-2">
                                        <span class="truncate max-w-[100px]"
                                            title="{{ $absen->lat_out }}, {{ $absen->long_out }}">{{ $absen->lat_out }},
                                            {{ $absen->long_out }}</span>
                                        <a href="https://www.google.com/maps/search/?api=1&query={{ $absen->lat_out }},{{ $absen->long_out }}"
                                            target="_blank"
                                            class="text-blue-600 hover:text-blue-800 bg-blue-50 hover:bg-blue-100 flex items-center justify-center h-6 w-6 rounded-md transition-colors"
                                            title="Lihat di Maps">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
                                                stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                                            </svg>
                                        </a>
                                    </div>
                                @else
                                    <span class="text-gray-400">-</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-6 py-8 text-center text-sm text-gray-500">
                                <div class="flex flex-col items-center justify-center">
                                    <svg class="h-10 w-10 text-gray-300 mb-3" fill="none" viewBox="0 0 24 24"
                                        stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                    </svg>
                                    Belum ada data absensi yang terekam.
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- Face Authentication Dashboard Sections -->
    <div class="mt-12 mb-8 flex items-center justify-between">
        <div>
            <h2 class="text-2xl font-bold text-gray-900">Sistem Absensi Wajah Terpusat (Face Recognition)</h2>
            <p class="text-md text-gray-500 mt-1">Mengelola Pendaftaran, Data Wajah (Vector Embedding), dan Kehadiran Secara
                Real-Time.</p>
        </div>
        <form action="{{ route('face.token.generate') }}" method="POST">
            @csrf
            <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg shadow">
                + Buat Token Pendaftaran
            </button>
        </form>
    </div>

    @if(session('success'))
        <div class="mb-4 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative">
            <strong>Berhasil!</strong> {{ session('success') }}
        </div>
    @endif

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        <!-- Token Aktif -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div class="p-6 border-b border-gray-200">
                <h3 class="text-lg font-bold">Token Pendaftaran Aktif</h3>
                <p class="text-sm text-gray-500">Berikan Token ini pada Karyawan agar mereka dapat menggunakan
                    Face-Registration di handphone.</p>
            </div>
            <div class="p-4">
                @if($faceTokens->count() > 0)
                    <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
                        @foreach($faceTokens as $t)
                            <div
                                class="bg-yellow-100 border border-yellow-300 text-yellow-800 px-4 py-2 rounded-lg font-bold text-center tracking-widest text-lg">
                                {{ $t->token }}
                            </div>
                        @endforeach
                    </div>
                @else
                    <p class="text-gray-500 text-center py-4">Tidak ada token aktif. Silahkan buat Token baru.</p>
                @endif
            </div>
        </div>

        <!-- Log Kehadiran Realtime -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div class="p-6 border-b border-gray-200">
                <h3 class="text-lg font-bold">Log Absensi Wajah Hari Ini</h3>
                <p class="text-sm text-gray-500">Daftar kehadiran tersinkronisasi realtime dari verifikasi Model Edge
                    Computing.</p>
            </div>
            <div class="overflow-x-auto p-4">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead>
                        <tr>
                            <th class="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Nama (NIA)</th>
                            <th class="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Waktu Terekam</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($faceLogs as $fLog)
                            <tr class="border-t border-gray-100">
                                <td class="px-4 py-2">
                                    <div class="font-medium text-gray-900">{{ $fLog->faceRegistration->name ?? '-' }}</div>
                                    <div class="text-xs text-gray-500">{{ $fLog->faceRegistration->nia ?? '-' }}</div>
                                </td>
                                <td class="px-4 py-2 text-sm">
                                    <span
                                        class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                                        {{ \Carbon\Carbon::parse($fLog->check_in_time)->format('H:i:s') }}
                                    </span>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="2" class="px-4 py-4 text-center text-sm text-gray-500">Belum ada absen dari
                                    pengenalan wajah hari ini.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Data Orang Terdaftar -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden mt-8">
        <div class="p-6 border-b border-gray-200">
            <h3 class="text-lg font-bold">Direktori Pengguna (Face Embedding)</h3>
            <p class="text-sm text-gray-500">Daftar Face Embedding yang digunakan Model Verifikasi untuk pembandingan jarak
                terdekat.</p>
        </div>
        <div class="overflow-x-auto p-4">
            <table class="min-w-full divide-y divide-gray-200">
                <thead>
                    <tr>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">ID Edge</th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Nama Pengguna</th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">NIA</th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status Vektor</th>
                        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                    @forelse($faceUsers as $fUser)
                        <tr class="hover:bg-gray-50">
                            <td class="px-4 py-3 text-sm font-medium">#{{ $fUser->id }}</td>
                            <td class="px-4 py-3 text-sm font-medium text-gray-900">{{ $fUser->name }}</td>
                            <td class="px-4 py-3 text-sm text-gray-500">{{ $fUser->nia }}</td>
                            <td class="px-4 py-3 text-sm">
                                @if(is_array($fUser->face_embedding) || is_string($fUser->face_embedding))
                                    <span
                                        class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                                        128-D Tersedia
                                    </span>
                                @else
                                    <span class="text-red-500 text-xs">Kosong</span>
                                @endif
                            </td>
                            <td class="px-4 py-3 text-sm text-blue-600 font-medium">Valid</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-4 py-8 text-center text-sm text-gray-500">Belum ada user yang direkam
                                wajahnya.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection