<?php

namespace Database\Seeders;

use App\Enums\PermissionAction;
use App\Models\Module;
use App\Models\Permission;
use Illuminate\Database\Seeder;

class ModulePermissionSeeder extends Seeder
{
    /**
     * key => [label, platform, extra_actions]
     */
    private const MODULES = [
        'dashboard' => ['Dashboard', 'web', []],
        'employees' => ['Karyawan', 'both', []],
        'departments' => ['Department', 'both', []],
        'locations' => ['Lokasi Absen', 'web', []],
        'schedule' => ['Jadwal Kerja', 'web', []],
        'lateness' => ['Keterlambatan', 'web', []],
        'holidays' => ['Tanggal Merah', 'web', []],
        'leave_quota' => ['Jatah Cuti', 'web', []],
        'leave_requests' => ['Pengajuan', 'both', ['approve']],
        'attendance_approval' => ['Approval Kehadiran', 'both', ['approve']],
        'attendance_reports' => ['Laporan Absensi', 'web', ['export']],
        'review' => ['Perlu Review', 'web', []],
        'devices' => ['Device', 'web', []],
        'audit_logs' => ['Audit Log', 'web', []],
        'access' => ['Manajemen Akses', 'web', []],
        'menus' => ['Manajemen Menu', 'web', []],
        'settings' => ['Pengaturan', 'web', []],
        'home' => ['Beranda', 'mobile', []],
        'attendance' => ['Absensi', 'mobile', []],
        'history' => ['Riwayat Absensi', 'mobile', []],
        'profile' => ['Profil', 'mobile', []],
        'notifications' => ['Notifikasi', 'mobile', []],
        'team_stats' => ['Statistik Tim', 'mobile', []],
    ];

    public function run(): void
    {
        $order = 0;

        foreach (self::MODULES as $key => [$label, $platform, $extras]) {
            $module = Module::updateOrCreate(
                ['key' => $key],
                [
                    'label' => $label,
                    'platform' => $platform,
                    'extra_actions' => $extras,
                    'sort_order' => $order++,
                ]
            );

            $actions = array_merge(
                PermissionAction::standard(),
                array_map(fn (string $a) => PermissionAction::from($a), $extras)
            );

            foreach ($actions as $action) {
                Permission::updateOrCreate(
                    ['key' => $key.'.'.$action->value],
                    ['module_id' => $module->id, 'action' => $action->value]
                );
            }
        }
    }
}
