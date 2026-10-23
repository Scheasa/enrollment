<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $users = [
            // ---- Default accounts for testing ----
            // admin   -> admin@cclang.edu.kh   / Admin@12345
            // staff   -> staff@cclang.edu.kh   / Staff@12345
            // student -> student@cclang.edu.kh / Student@12345
            ['name' => 'Sokha Chea',      'email' => 'admin@cclang.edu.kh',   'phone' => '+855 12 345 678', 'password' => 'Admin@12345',   'role' => 'admin'],
            ['name' => 'Srey Neang Kim',  'email' => 'staff@cclang.edu.kh',   'phone' => '+855 96 222 3344', 'password' => 'Staff@12345',   'role' => 'staff'],
            ['name' => 'Dara Sok',        'email' => 'student@cclang.edu.kh', 'phone' => '+855 10 555 777', 'password' => 'Student@12345', 'role' => 'student'],

            // ---- More students ----
            ['name' => 'Sophea Chan',     'email' => 'sophea.chan@example.com',   'phone' => '+855 17 888 123', 'password' => 'Student@12345', 'role' => 'student'],
            ['name' => 'Vannak Heng',     'email' => 'vannak.heng@example.com',   'phone' => '+855 15 456 789', 'password' => 'Student@12345', 'role' => 'student'],
            ['name' => 'Chanthou Lim',    'email' => 'chanthou.lim@example.com',  'phone' => '+855 93 111 222', 'password' => 'Student@12345', 'role' => 'student'],
            ['name' => 'Rithy Pov',       'email' => 'rithy.pov@example.com',     'phone' => '+855 78 333 444', 'password' => 'Student@12345', 'role' => 'student'],
            ['name' => 'Monika Yim',      'email' => 'monika.yim@example.com',    'phone' => '+855 11 999 000', 'password' => 'Student@12345', 'role' => 'student'],
        ];

        $rows = array_map(fn ($u) => [
            'name'          => $u['name'],
            'email'         => $u['email'],
            'phone'         => $u['phone'],
            'password'      => Hash::make($u['password']),
            'role'          => $u['role'],
            'profile_image' => null,
            'created_at'    => $now,
            'updated_at'    => $now,
        ], $users);

        DB::table('users')->insert($rows);
    }
}
