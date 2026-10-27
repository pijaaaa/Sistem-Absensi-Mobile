# Push Notification Roadmap

> Scope: eksplorasi ide notifikasi tambahan untuk sistem absensi
> **PT Bumi Siak Pusako** — mobile + backend Laravel

---

## 📊 Analisis Infrastruktur Tersedia

| Komponen | Status | Bisa dipakai push notif? |
|---|---|---|
| `FcmService` (legacy FCM HTTP) | ✅ Tersedia | Ya — kirim ke 1 user / grup |
| `NotificationService` (simpan DB + kirim FCM) | ✅ Tersedia | Ya — semua trigger pakai ini |
| `Schedule` (daily 00:05, 01:00) | ✅ Tersedia | Ya — sudah ada cron |
| `WorkSchedule` (start/end time, timezone) | ✅ Tersedia | Ya — bisa compute reminder time |
| `Attendance` (late_minutes, late_level, early_leave) | ✅ Tersedia | Ya — data keterlambatan ada |
| `LeaveBalance` (quota, used) | ✅ Tersedia | Ya — sisa cuti |
| `MarkAbsentees` command | ✅ Tersedia | Ya — trigger alfa |

### File referensi
- Backend FCM: `backend/app/Services/FcmService.php`
- Backend notif: `backend/app/Services/NotificationService.php`
- Frontend listener: `mobile/lib/main.dart:48-59`
- Frontend service: `mobile/lib/core/services/push_notification_service.dart`
- DB notifikasi: `backend/app/Models/Notification.php`, `backend/app/Models/PushToken.php`
- Scheduler: `backend/routes/console.php`

---

## 💡 Ide Fitur Push Notifikasi Tambahan

### A. Daily Reminder (time-based, via Schedule)

| # | Fitur | Trigger | Kepada | Isi notifikasi |
|---|---|---|---|---|
| 1 | Pagi belum absen | Daily 07:45 (5m sebelum shift) | Employee belum check-in | "Belum absen masuk! Silakan absen sebelum jam kerja dimulai." |
| 2 | Sore belum absen pulang | Daily 16:45 (5m sebelum akhir shift) | Employee sudah check-in, belum checkout | "Belum absen pulang? Jangan lupa selesaikan sesi absen." |
| 3 | Check-out reminder | Daily 30 mnt setelah end_time | Employee belum checkout | "Anda belum absen pulang. Silakan lakukan check-out." |

### B. Real-time (event-based, trigger saat absen selesai)

| # | Fitur | Trigger | Kepada | Isi notifikasi |
|---|---|---|---|---|
| 4 | Terlambat | Check-in selesai, `late_minutes > 0` | Employee + manager department | "Anda terlambat X menit. Silakan perhatikan jam kerja." |
| 5 | Early leave | Check-out, `early_leave_minutes > 0` | Employee | "Anda pulang lebih awal Y menit dari jadwal." |
| 6 | Face quality rendah | `face_score_server < threshold` | Employee | "Kualitas verifikasi wajah rendah, absen akan direview." |
| 7 | Outside geofence (soft) | Check-in di luar area tapi lolos | Employee | "Lokasi absen Anda di luar area kantor." |

### C. Approval & Workflow

| # | Fitur | Trigger | Kepada | Isi notifikasi |
|---|---|---|---|---|
| 8 | Pending approval berlangsung >24h | Manager punya approval yang belum diklik | Manager | "3 pengajuan butuh persetujuan Anda." |
| 9 | Cuti disetujui/ditolak | Manager approve/reject | Employee (requester) | "Pengajuan cuti Anda disetujui/ditolak." |

### D. Leave & Cuti (data-based)

| # | Fitur | Trigger | Kepada | Isi notifikasi |
|---|---|---|---|---|
| 10 | Sisa cuti hampir habus | `LeaveBalance.used / quota > 80%` | Employee | "Sisa cuti: X/Y masih tersedia. Ajukan sebelum tahun berakhir." |
| 11 | Cuti akan expire | LeaveRequest approved tapi belum dipakai | Employee | "Cuti yang disetujui akan expire pada {date}." |
| 12 | Cuti baru diajukan | Employee ajukan cuti | Manager | "{nama} mengajukan cuti {type}. Klik untuk review." |

### E. Security & Maintenance

| # | Fitur | Trigger | Kepada | Isi notifikasi |
|---|---|---|---|---|
| 13 | Device baru terdaftar | `POST /devices/register-backup` | Employee (owner akun) | "Device baru terdaftar. Jika tidak Anda, segera hubungi HR." |
| 14 | Face template terhapus | `DELETE /face/template` | Employee | "Template wajah Anda dihapus. Daftar ulang di enrollment screen." |
| 15 | Offline sync berhasil | Backend `/attendance/sync` berhasil | Employee | "Absen offline Anda tersinkronkan ke server." |
| 16 | Review needed (manual) | `review_flag = true` | Manager/HR | "Absensi {nama} membutuhkan review manual." |

---

## 🗺️ Prioritas Rekomendasi (MVP → Advanced)

### Fase 1 — MVP (2–3 hari dev)
- **#1 & #2** — daily reminder (pagi / sore)
- **#10** — sisa cuti hampir habis
- **#4** — terlambat (trigger di `AttendanceController.checkIn`)

### Fase 2 — Medium (1 minggu)
- **#3** — check-out reminder
- **#5** — early leave
- **#8** — pending approval >24h
- **#13** — device baru terdaftar (security alert)

### Fase 3 — Advanced (2 minggu)
- **#6** — face quality rendah (butuh threshold config)
- **#7** — geofence soft warning (butuh geofence service)
- **#11, #12** — cuti expire / baru diajukan
- **#15** — offline sync (butuh webhook dari sync endpoint)
- **#16** — review needed (manual)

---

## ⚙️ Implementation Sketch (Backend)

### Daily reminder via Schedule
```php
// routes/console.php
Schedule::call(function () {
    app(\App\Services\NotificationService::class)->sendDailyReminder();
}, '07:45');
```

### Method baru di NotificationService
```php
public function sendDailyReminder(): void
{
    $schedule = WorkSchedule::current();
    $tz = $schedule?->timezone ?? config('app.timezone');
    $now = \Carbon\Carbon::now($tz);

    Employee::where('is_active', true)
        ->whereNotNull('user_id')
        ->with('user.pushTokens')
        ->each(function ($e) use ($now) {
            // skip karyawan yang sudah absen hari ini
            if ($e->attendances()
                ->whereDate('date', $now->toDateString())
                ->exists()) return;

            $this->send(
                $e->user,
                'Absensi',
                'Belum absen masuk. Jangan lupa check-in.',
                ['type' => 'daily_reminder']
            );
        });
}
```

### Trigger real-time di controller
```php
// AttendanceController.php — setelah checkIn sukses
if ($attendance->late_minutes > 0) {
    $this->notifier->send(
        $employee->user,
        'Terlambat!',
        "Anda terlambat {$attendance->late_minutes} menit.",
        ['type' => 'late', 'id' => $attendance->id]
    );
}
```
