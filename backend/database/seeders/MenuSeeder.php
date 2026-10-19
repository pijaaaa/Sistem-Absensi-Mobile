<?php

namespace Database\Seeders;

use App\Models\Menu;
use App\Models\Module;
use Illuminate\Database\Seeder;

class MenuSeeder extends Seeder
{
    private const WEB = [
        ['dashboard', 'Dashboard', 'dashboard', 'home'],
        ['employees', 'Karyawan', 'employees.index', 'users'],
        ['departments', 'Department', 'departments.index', 'building'],
        ['locations', 'Lokasi Absen', 'locations.index', 'map-pin'],
        ['schedule', 'Jadwal Kerja', 'schedule.index', 'clock'],
        ['lateness', 'Keterlambatan', 'lateness.index', 'alert'],
        ['holidays', 'Tanggal Merah', 'holidays.index', 'calendar'],
        ['leave_quota', 'Jatah Cuti', 'leave-quota.index', 'calendar-days'],
        ['leave_requests', 'Pengajuan', 'leave-requests.index', 'file-text'],
        ['attendance_approval', 'Approval Kehadiran', 'attendance-approval.index', 'check-circle'],
        ['attendance_reports', 'Laporan Absensi', 'reports.index', 'bar-chart'],
        ['review', 'Perlu Review', 'review.index', 'flag'],
        ['devices', 'Device', 'devices.index', 'smartphone'],
        ['audit_logs', 'Audit Log', 'audit-logs.index', 'list'],
        ['access', 'Manajemen Akses', 'access.index', 'shield'],
        ['menus', 'Manajemen Menu', 'menus.index', 'menu'],
        ['settings', 'Pengaturan', 'settings.index', 'cog'],
    ];

    private const LOCKED = ['access', 'menus'];

    private const MOBILE = [
        ['home', 'Beranda', 'home', 'home'],
        ['attendance', 'Absensi', 'attendance', 'camera'],
        ['history', 'Riwayat', 'history', 'list'],
        ['leave_requests', 'Pengajuan', 'leave', 'file-text'],
        ['attendance_approval', 'Approval', 'approval', 'check-circle'],
        ['team_stats', 'Statistik Tim', 'team_stats', 'bar-chart'],
        ['notifications', 'Notifikasi', 'notifications', 'bell'],
        ['profile', 'Profil', 'profile', 'user'],
    ];

    public function run(): void
    {
        $order = 0;

        foreach (self::WEB as [$moduleKey, $label, $route, $icon]) {
            $this->upsert('web', $moduleKey, $label, $route, $icon, $order++);
        }

        $order = 0;

        foreach (self::MOBILE as [$moduleKey, $label, $feature, $icon]) {
            $this->upsert('mobile', $moduleKey, $label, $feature, $icon, $order++);
        }
    }

    private function upsert(string $platform, string $moduleKey, string $label, string $key, string $icon, int $order): void
    {
        $module = Module::where('key', $moduleKey)->firstOrFail();

        Menu::updateOrCreate(
            ['platform' => $platform, 'module_id' => $module->id],
            [
                'label' => $label,
                'icon' => $icon,
                'sort_order' => $order,
                'route_or_feature_key' => $key,
                'is_active' => true,
                'is_locked' => $platform === 'web' && in_array($moduleKey, self::LOCKED, true),
            ]
        );
    }
}
