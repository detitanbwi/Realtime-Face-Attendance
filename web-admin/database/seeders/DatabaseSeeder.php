<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Admin
        User::create([
            'id_pegawai' => 'ADMIN01',
            'name' => 'Administrator',
            'password' => bcrypt('12345678'),
            'role' => 'admin',
        ]);

        // Pegawai Dummy 1
        User::create([
            'id_pegawai' => 'PEG001',
            'name' => 'Budi Santoso',
            'password' => bcrypt('12345678'),
            'role' => 'user',
        ]);

        // Pegawai Dummy 2
        User::create([
            'id_pegawai' => 'PEG002',
            'name' => 'Siti Aminah',
            'password' => bcrypt('12345678'),
            'role' => 'user',
        ]);
    }
}
