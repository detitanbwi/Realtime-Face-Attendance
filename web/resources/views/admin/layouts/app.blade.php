<!DOCTYPE html>
<html lang="id">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard - Sistem Absensi</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
        }
    </style>
</head>

<body class="bg-gray-50 text-gray-800">

    <nav class="bg-white border-b border-gray-200 sticky top-0 z-50">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between h-16">
                <div class="flex items-center gap-8">
                    <span class="text-xl font-bold text-gray-900 tracking-tight">Admin<span
                            class="text-blue-600">Absen</span></span>
                    <div class="hidden md:flex space-x-4">
                        <a href="{{ route('dashboard') }}"
                            class="text-gray-900 px-3 py-2 rounded-md text-sm font-medium hover:bg-gray-100 {{ request()->routeIs('dashboard') ? 'bg-gray-100' : '' }}">Dashboard</a>
                        <a href="{{ route('users.index') }}"
                            class="text-gray-900 px-3 py-2 rounded-md text-sm font-medium hover:bg-gray-100 {{ request()->routeIs('users.index') ? 'bg-gray-100' : '' }}">Manajemen
                            Akun</a>
                        <a href="{{ route('leave.index') }}"
                            class="text-gray-900 px-3 py-2 rounded-md text-sm font-medium hover:bg-gray-100 {{ request()->routeIs('leave.index') ? 'bg-gray-100' : '' }}">Approval
                            Izin</a>
                    </div>
                </div>
                <div class="flex items-center gap-4">
                    <span class="text-sm text-gray-600 font-medium">Halo, {{ Auth::user()->name ?? 'Admin' }}</span>
                    <form action="{{ route('logout') }}" method="POST">
                        @csrf
                        <button type="submit"
                            class="text-sm font-medium text-red-600 hover:text-red-800 transition">Logout</button>
                    </form>
                </div>
            </div>
        </div>
    </nav>

    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        @if(session('success'))
            <div class="mb-4 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative" role="alert">
                <span class="block sm:inline">{{ session('success') }}</span>
            </div>
        @endif
        @if ($errors->any())
            <div class="mb-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative">
                <ul class="list-disc list-inside">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        @yield('content')
    </main>
</body>

</html>