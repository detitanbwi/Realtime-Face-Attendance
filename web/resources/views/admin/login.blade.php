<!DOCTYPE html>
<html lang="id">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Login - Sistem Absensi</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
        }
    </style>
</head>

<body class="bg-gray-50 text-gray-800 flex items-center justify-center min-h-screen">

    <div class="bg-white p-8 rounded-2xl shadow-xl w-full max-w-md border border-gray-100">
        <div class="text-center mb-8">
            <h1 class="text-3xl font-bold text-gray-900 tracking-tight">Login Admin</h1>
            <p class="text-gray-500 mt-2 text-sm">Masuk untuk mengelola data absensi</p>
        </div>

        @if($errors->any())
            <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-600 rounded-lg text-sm">
                <ul class="list-disc list-inside">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('login') }}" method="POST" class="space-y-5">
            @csrf
            <div>
                <label for="id_pegawai" class="block text-sm font-medium text-gray-700 mb-1">ID Pegawai</label>
                <input type="text" id="id_pegawai" name="id_pegawai" required
                    class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors shadow-sm"
                    placeholder="Contoh: ADMIN01">
            </div>

            <div>
                <label for="password" class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input type="password" id="password" name="password" required
                    class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors shadow-sm"
                    placeholder="••••••••">
            </div>

            <button type="submit"
                class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-4 rounded-lg shadow-md hover:shadow-lg transition flex justify-center items-center gap-2">
                Masuk Dashboard
            </button>
        </form>

        <div class="mt-8 border-t border-gray-200 pt-6">
            <p class="text-sm text-center text-gray-500 mb-4">Belum punya aplikasi mobile?</p>
            <a href="{{ asset('apk/app-release.apk') }}" download
                class="w-full bg-emerald-50 hover:bg-emerald-100 text-emerald-700 font-medium py-3 px-4 rounded-lg border border-emerald-200 transition flex justify-center items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd"
                        d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"
                        clip-rule="evenodd" />
                </svg>
                Download APK Absensi
            </a>
        </div>

        <div class="mt-8 text-center text-xs text-gray-400">
            &copy; 2026 Aplikasi Absensi Flutter & Laravel.
        </div>
    </div>

</body>

</html>