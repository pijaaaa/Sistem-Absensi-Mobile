# Push Notification Roadmap (Revisi)

> Scope: notifikasi tambahan untuk sistem absensi **PT Bumi Siak Pusako** — backend Laravel 13 + mobile Flutter.
> Dokumen ini melengkapi `ROADMAP.md`. Keputusan di `ROADMAP.md` bagian 0 tetap berlaku.

---

## 1. Infrastruktur yang Sudah Ada

| Komponen | Status | Catatan |
|---|---|---|
| `FcmService` | Ada, tetapi berbasis **FCM legacy HTTP** | Google sudah mematikan legacy API secara bertahap. Wajib pindah ke **HTTP v1** (service account + OAuth2). Cek ulang di dokumentasi Firebase |
| `NotificationService` (simpan DB + kirim FCM) | Ada | Semua trigger lewat sini |
| `Schedule` (daily 00:05, 01:00) | Ada | Tambahkan command reminder |
| `WorkSchedule` (start/end time, timezone) | Ada | Dipakai menghitung waktu reminder, jangan hardcode jam |
| `ScheduleService` (hari kerja + tanggal merah) | Ada (B4) | Dipakai untuk menentukan siapa yang wajib absen |
| `Attendance`, `LeaveBalance`, `LeaveRequest` | Ada | Sumber data reminder |
| `MarkAbsentees` | Ada | Titik trigger notifikasi alfa |
| Event B9 (pengajuan baru ke manager, keputusan approval, approval device cadangan) | Seharusnya sudah ada | **Verifikasi** di Fase 0, jangan dibangun ulang |

File referensi:
- Backend FCM: `backend/app/Services/FcmService.php`
- Backend notif: `backend/app/Services/NotificationService.php`
- Model: `backend/app/Models/Notification.php`, `backend/app/Models/PushToken.php`
- Scheduler: `backend/routes/console.php`
- Mobile listener: `mobile/lib/main.dart`
- Mobile service: `mobile/lib/core/services/push_notification_service.dart`

---

## 2. Keputusan Desain

| Area | Keputusan |
|---|---|
| Siapa yang dapat reminder | Karyawan aktif + punya akun + punya push token + **wajib absen hari itu**. Dikecualikan: weekend, tanggal merah, hari cuti/sakit/izin/dinas yang sudah disetujui |
| Waktu reminder | Dihitung dari `WorkSchedule` + offset di settings (bukan jam tetap). Default: reminder masuk **15 menit sebelum** jam masuk, reminder pulang **15 menit sebelum** jam pulang, pengingat lupa pulang **30 menit setelah** jam pulang |
| Eksekusi | Satu command dijalankan **tiap 5 menit** (`withoutOverlapping`), mengirim hanya untuk jendela waktu yang tepat |
| Anti-duplikat | Kolom `dedupe_key` (unik, nullable) di tabel `notifications`, format `jenis:employee_id:tanggal`. Command boleh jalan berkali-kali tanpa mengirim dobel |
| Pengiriman | Lewat **queue** (job per penerima, dikerjakan per batch) agar 200–500 penerima tidak menahan scheduler |
| Token | Hapus token yang ditolak FCM (UNREGISTERED/NOT_FOUND/INVALID). Token dihapus saat logout. Refresh token dikirim ulang ke backend |
| Isi notifikasi | Selalu bawa `data.type` (dan `id` bila perlu) agar mobile bisa membuka layar yang sesuai saat notifikasi diketuk |
| Pengaturan | Offset dan jam ringkasan diatur superadmin di web (izin `settings`, tercatat di audit log). Karyawan bisa mematikan jenis **reminder**; notifikasi approval dan keamanan tidak bisa dimatikan |
| Retensi | Tabel `notifications` dibersihkan berkala (default simpan 90 hari) |

---

## 3. Daftar Fitur (Revisi)

Legenda status: **BARU** = dibangun, **VERIFIKASI** = seharusnya sudah ada di B9, **GABUNG** = digabung ke fitur lain, **HAPUS** = dibuang beserta alasan.

### A. Reminder harian (berbasis waktu)

| # | Fitur | Penerima | Isi | Status |
|---|---|---|---|---|
| 1 | Belum absen masuk | Karyawan wajib absen yang belum check-in | "Belum absen masuk. Jangan lupa absen sebelum jam kerja dimulai." | BARU (Fase 1) |
| 2 | Belum absen pulang | Sudah check-in, belum check-out, mendekati jam pulang | "Belum absen pulang? Jangan lupa check-out." | BARU (Fase 1) |
| 3 | Lupa absen pulang | Sudah check-in, belum check-out, 30 menit setelah jam pulang | "Anda belum absen pulang. Silakan lakukan check-out." | BARU (Fase 1) |
| 17 | Tercatat alfa | Karyawan yang ditandai alfa oleh `MarkAbsentees` | "Anda tercatat alfa pada {tanggal}. Jika ada kendala, ajukan izin sesuai batas yang berlaku." | BARU (Fase 1) |
| 18 | Ringkasan harian manager | Manager department | "Hari ini: {n} terlambat, {m} belum absen di department Anda." (satu notifikasi per hari, bukan per karyawan) | BARU (Fase 1) |

### B. Event saat absen

| # | Fitur | Status |
|---|---|---|
| 4 | Terlambat → karyawan | **HAPUS push**: hasil sudah tampil di layar saat absen. Informasi terlambat cukup di layar hasil dan riwayat |
| 4b | Terlambat → manager | **GABUNG ke #18** (ringkasan harian), supaya manager tidak dibanjiri notifikasi per orang |
| 5 | Pulang lebih awal | **HAPUS push**: sama seperti #4, sudah tampil di layar hasil |
| 6 | Kualitas wajah rendah | **GABUNG ke #15** (status "perlu review" pada hasil sinkron offline) |
| 7 | Di luar geofence (soft) | **HAPUS**: bertentangan dengan B6, absen di luar area ditolak, tidak ada kondisi "di luar area tapi lolos" |
| 15 | Absen offline tersinkron | BARU (Fase 2). Isi memuat hasil: tepat waktu/terlambat, atau "perlu review". Ini satu-satunya push yang relevan untuk absen karena terjadi di background |

### C. Approval & workflow

| # | Fitur | Status |
|---|---|---|
| 8 | Pengajuan menunggu >24 jam | BARU (Fase 2). Satu notifikasi ringkasan per manager per hari: "{n} pengajuan menunggu persetujuan Anda" |
| 9 | Keputusan cuti/izin disetujui/ditolak → karyawan | VERIFIKASI (B9) |
| 12 | Pengajuan baru → manager | VERIFIKASI (B9) |
| 19 | Approval kehadiran device cadangan (permintaan ke manager, keputusan ke karyawan) | VERIFIKASI (B9) |

### D. Cuti

| # | Fitur | Status |
|---|---|---|
| 10 | Sisa cuti akan hangus | BARU (Fase 2). Cuti hangus akhir tahun, jadi yang diingatkan adalah **sisa masih banyak**. Dikirim 2 kali (default 1 November dan 15 Desember) ke karyawan yang sisanya ≥ ambang di settings (default 3 hari). Contoh: "Sisa cuti Anda {n} hari dan akan hangus pada 31 Desember." |
| 11 | Cuti disetujui akan expire | **HAPUS**: cuti yang sudah disetujui tidak punya masa expire |

### E. Keamanan

| # | Fitur | Status |
|---|---|---|
| 13 | Device cadangan baru terdaftar | BARU (Fase 2). Ke pemilik akun: "Device baru didaftarkan di akun Anda. Jika bukan Anda, hubungi admin." |
| 14 | Template wajah dihapus | BARU (Fase 3) |
| 16 | Absensi perlu review | **HAPUS dari push**: review dikerjakan superadmin di web (superadmin tidak memakai mobile). Cukup badge/hitungan "perlu review" di dashboard web (B10) |

---

## 4. Fase Pengerjaan

| Fase | Isi | Selesai kalau |
|---|---|---|
| **0** | Pondasi: FCM HTTP v1, uji kirim end-to-end, siklus token, penanganan notifikasi di mobile, verifikasi event B9 | Push benar-benar sampai ke HP (foreground, background, aplikasi tertutup) dan bisa diketuk ke layar yang tepat |
| **1** | #1, #2, #3, #17, #18 + aturan siapa wajib absen, anti-duplikat, queue, pengaturan di web | Reminder terkirim tepat waktu, tidak dobel, tidak terkirim ke yang cuti/libur |
| **2** | #10, #13, #8, #15 + preferensi notifikasi karyawan + retensi | Semua notifikasi data-based dan keamanan berjalan, karyawan bisa mematikan reminder |
| **3** | #14 dan penyempurnaan | Sisa ide opsional |

Satu fase per sesi agent, test manual dulu sebelum lanjut.

---

## 5. Prompt untuk AI Agent

> Tambahkan di awal setiap sesi: *"Project absensi PT Bumi Siak Pusako: backend Laravel 13 (folder backend) + mobile Flutter (folder mobile). Baca ROADMAP.md bagian 0 dan PUSH_NOTIFICATION_ROADMAP.md bagian 2 sebagai acuan keputusan. Kode harus sederhana dan natural, tanpa abstraksi berlebihan. Selesaikan fase yang diminta saja."*

### Fase 0 — Pondasi

```
Fase 0 push notification. Tujuan: pastikan jalur push berfungsi end-to-end sebelum menambah
fitur apa pun.

BACKEND
1. Audit FcmService yang ada. Jika masih memakai FCM legacy HTTP API, ganti ke FCM HTTP v1
   (endpoint projects/{project_id}/messages:send, autentikasi OAuth2 dari service account).
   Path file service account dan project_id dari .env, file JSON jangan masuk git (tambahkan
   ke .gitignore). Cek dulu apakah paket resmi yang kompatibel dengan Laravel 13 tersedia
   (mis. kreait/laravel-firebase); jika tidak, pakai google/auth + HTTP client. Jelaskan
   langkah manual di Firebase console untuk membuat/mengunduh service account.
2. Penanganan respons FCM: jika token ditolak (UNREGISTERED / NOT_FOUND / INVALID_ARGUMENT),
   hapus baris token itu dari push_tokens. Error sementara (5xx/timeout) di-retry lewat queue,
   jangan menghapus token.
3. NotificationService: semua notifikasi membawa data.type (string tetap) dan id bila perlu.
   Simpan juga ke tabel notifications seperti sekarang. Tambahkan kolom nullable `dedupe_key`
   (unique) di notifications; bila kunci sudah ada, kirim dilewati tanpa error.
4. Pindahkan pengiriman FCM ke queue (job per user, driver database). Jelaskan cara
   menjalankan queue worker di Laragon/Windows.
5. Artisan command `notif:test {user_id} {--type=test}` untuk mengirim push uji ke satu user.
6. Endpoint token: simpan/refresh token (POST), hapus token milik device ini saat logout
   (DELETE). Satu user boleh punya beberapa token (device utama + cadangan).
7. Verifikasi event B9 yang seharusnya sudah ada: pengajuan baru ke manager, keputusan
   approval ke karyawan, approval kehadiran device cadangan. Cek masing-masing benar-benar
   memanggil NotificationService dengan data.type yang jelas. Perbaiki bila ada yang belum.

MOBILE
8. Android 13+: minta izin POST_NOTIFICATIONS saat yang tepat (bukan saat splash), tangani
   kasus ditolak dengan pesan yang jelas.
9. Buat notification channel dengan flutter_local_notifications: "Pengingat absensi",
   "Persetujuan", "Informasi". data.type dipetakan ke channel.
10. Aplikasi terbuka (foreground): tampilkan notifikasi lokal (FCM tidak menampilkannya
    otomatis di foreground) dan refresh badge/daftar notifikasi.
11. Ketuk notifikasi (dari background/terminated/foreground): buka layar sesuai data.type
    (mis. approval -> inbox approval, leave_decision -> detail pengajuan, reminder -> Home).
    Jika belum login, simpan tujuan lalu arahkan setelah login. Gunakan alur redirect
    go_router yang sudah ada, jangan menambah navigasi manual yang menabrak redirect.
12. Token: kirim token setelah login, perbarui lewat onTokenRefresh, hapus lewat endpoint
    DELETE saat logout.

UJI (laporkan satu per satu)
- notif:test saat aplikasi foreground, background, dan ditutup total: notifikasi muncul.
- Ketuk notifikasi membuka layar yang benar di ketiga kondisi.
- Logout lalu kirim notif ke user itu: tidak ada notifikasi di HP tersebut.
- Token palsu: baris token terhapus otomatis.
- Dua event B9 yang diverifikasi benar-benar memunculkan push di HP.
Beri tahu saya apa yang perlu saya cek manual di HP.
```

### Fase 1 — Reminder Harian

```
Fase 1 push notification. Fase 0 sudah selesai dan lolos uji. Bangun reminder harian.

ATURAN SIAPA YANG DIKIRIMI
Buat satu service (mis. AttendanceReminderService) dengan method yang menentukan karyawan
yang WAJIB absen pada tanggal tertentu: karyawan aktif, punya user dan push token,
hari itu hari kerja (pakai ScheduleService dari B4: weekend + tanggal merah), dan tidak
sedang cuti/sakit/izin/dinas berstatus approved yang menutupi tanggal itu.

SCHEDULER
1. Command `notifications:send-reminders`, dijadwalkan tiap 5 menit di routes/console.php
   dengan withoutOverlapping. Waktu "sekarang" dan jam kerja dihitung di timezone
   WorkSchedule. Tiap jenis reminder hanya dikirim bila waktu sekarang berada dalam jendela
   5 menit setelah waktu targetnya; anti-duplikat tetap lewat dedupe_key
   (jenis:employee_id:tanggal).
2. Jenis reminder:
   - reminder_checkin: (jam masuk - offset) ke karyawan wajib absen yang BELUM check-in.
     Default offset 15 menit.
   - reminder_checkout: (jam pulang - offset) ke yang SUDAH check-in dan BELUM check-out.
     Default 15 menit.
   - reminder_forgot_checkout: (jam pulang + 30 menit) ke yang sudah check-in, belum
     check-out.
3. Alfa: di command MarkAbsentees yang sudah ada, setelah karyawan ditandai alfa, kirim
   notifikasi "Anda tercatat alfa pada {tanggal}..." (dedupe_key alfa:employee_id:tanggal).
4. Ringkasan manager: command/jendela waktu terpisah pada jam di settings (default 09:00,
   diatur relatif terhadap jam masuk bila memungkinkan). Per manager department, hitung
   karyawan department-nya yang terlambat dan yang belum absen (hanya yang wajib absen),
   kirim SATU notifikasi bila jumlahnya > 0. Tidak ada push per karyawan.
5. Semua pengiriman lewat queue (job per penerima, chunk), memakai NotificationService.

PENGATURAN (web admin superadmin, ikuti pola B3: izin settings.*, tercatat di audit log)
- Offset reminder masuk dan pulang (menit), jeda reminder lupa pulang, jam ringkasan
  manager, saklar aktif/nonaktif per jenis reminder. Cache pengaturan dan invalidate saat
  diubah.

TEST (feature test dengan FCM dipalsukan dan Carbon::setTestNow)
- Karyawan yang sudah absen tidak dapat reminder masuk.
- Hari weekend, tanggal merah, dan hari cuti/sakit/izin/dinas approved: tidak ada reminder.
- Command dijalankan dua kali di jendela yang sama: tidak ada notifikasi dobel.
- Reminder pulang hanya ke yang sudah check-in dan belum check-out.
- Timezone WorkSchedule diikuti (bukan timezone server).
- Ringkasan manager hanya menghitung department-nya sendiri dan tidak terkirim bila 0.
- Karyawan tanpa push token tidak menimbulkan error.
Jelaskan cara menjalankan scheduler dan queue worker di Laragon (php artisan schedule:work
dan queue:work) serta cara menguji manual dengan mengubah jam kerja di pengaturan.
```

### Fase 2 — Cuti, Keamanan, Sinkron Offline, Preferensi

```
Fase 2 push notification. Fase 0 dan 1 sudah selesai dan lolos uji.

1. Sisa cuti akan hangus (#10): command harian yang berjalan pada tanggal di settings
   (default 1 November dan 15 Desember). Kirim ke karyawan yang sisa cuti (quota - used)
   >= ambang di settings (default 3 hari). dedupe_key sisa_cuti:employee_id:tahun:tanggal.
2. Device baru terdaftar (#13): saat device cadangan didaftarkan, kirim ke pemilik akun
   (tidak bisa dimatikan oleh karyawan).
3. Pengajuan menunggu >24 jam (#8): satu notifikasi per manager per hari, isi jumlah
   pengajuan department-nya yang pending lebih dari 24 jam. Pengajuan manager yang pending
   >24 jam dikirim ke superadmin lewat notifikasi di tabel (tanpa push, karena superadmin
   tidak memakai mobile) dan tampil sebagai badge di web.
4. Sinkron offline (#15): setelah endpoint /attendance/sync memproses batch, kirim satu
   notifikasi ringkas per user: jumlah absen tersinkron dan statusnya (tepat waktu/terlambat,
   atau "perlu review" bila review_flag). Jangan kirim per absen. Jangan membocorkan
   alasan teknis (time_trust dan sebagainya) ke karyawan, cukup "perlu review".
5. Preferensi notifikasi karyawan: tabel/kolom preferensi per user untuk jenis reminder
   (reminder_checkin, reminder_checkout, reminder_forgot_checkout, sisa_cuti, ringkasan
   manager). Endpoint GET/PUT /api/me/notification-preferences. Notifikasi approval dan
   keamanan tidak bisa dimatikan. Service pengirim menghormati preferensi.
6. Mobile: layar pengaturan notifikasi di Profil (saklar per jenis reminder, memakai
   komponen design system), sesuai izin dan role (menu manager hanya tampil untuk manager).
7. Retensi: command harian menghapus baris notifications yang lebih tua dari 90 hari
   (nilai di settings).

TEST
- Pengingat cuti hanya ke yang sisanya >= ambang, dan hanya pada tanggal yang diatur.
- Preferensi dimatikan: reminder tidak terkirim, tetapi notifikasi approval tetap.
- Sinkron offline 5 absen: hanya 1 notifikasi.
- Retensi menghapus yang lama, yang baru tetap ada.
Beri tahu saya apa yang perlu saya cek manual di HP.
```

### Fase 3 — Opsional

```
Fase 3 push notification (opsional).

1. Template wajah dihapus (#14): kirim ke pemilik akun saat template dihapus (oleh dirinya
   atau admin), dengan petunjuk mendaftar ulang di layar enrollment.
2. Tinjau semua jenis notifikasi: jika ada yang terlalu sering, gabungkan atau jadikan
   ringkasan.
3. Dokumentasikan seluruh data.type beserta tujuan layar mobile dan penerimanya dalam satu
   tabel di dokumen ini (bagian 6).
```

---

## 6. Referensi `data.type` (isi seiring pengerjaan)

| data.type | Penerima | Layar tujuan di mobile | Bisa dimatikan? |
|---|---|---|---|
| `reminder_checkin` | Karyawan | Home | Ya |
| `reminder_checkout` | Karyawan | Home | Ya |
| `reminder_forgot_checkout` | Karyawan | Home | Ya |
| `absent_marked` | Karyawan | Riwayat | Tidak |
| `team_daily_summary` | Manager | Statistik tim | Ya |
| `leave_request_new` | Manager | Inbox approval | Tidak |
| `leave_decision` | Karyawan | Detail pengajuan | Tidak |
| `backup_attendance_request` | Manager | Inbox approval | Tidak |
| `backup_attendance_decision` | Karyawan | Riwayat | Tidak |
| `pending_approval_digest` | Manager | Inbox approval | Ya |
| `leave_balance_expiring` | Karyawan | Pengajuan | Ya |
| `device_registered` | Karyawan | Profil (device) | Tidak |
| `offline_sync_result` | Karyawan | Riwayat | Tidak |

---

## 7. Checklist Uji Manual

1. Push sampai ke HP saat aplikasi foreground, background, dan ditutup total.
2. Ketuk notifikasi membuka layar yang sesuai; jika belum login, setelah login diarahkan ke tujuan.
3. Logout: notifikasi tidak lagi masuk ke HP itu.
4. Reminder masuk tidak terkirim ke karyawan yang sudah absen, sedang cuti, atau hari libur.
5. Menjalankan command reminder dua kali tidak menghasilkan notifikasi dobel.
6. Ubah jam kerja di web: waktu reminder ikut berubah.
7. Manager menerima satu ringkasan harian, bukan notifikasi per karyawan terlambat.
8. Karyawan mematikan reminder: reminder berhenti, notifikasi approval tetap masuk.
9. Absen offline lalu sync: hanya satu notifikasi ringkasan.
10. Cabut izin atau nonaktifkan akun: tidak ada notifikasi ke akun itu.

---

## 8. Catatan Kerja

- Jalankan `php artisan schedule:work` dan `php artisan queue:work` selama pengujian di Laragon; tanpa keduanya reminder tidak akan terkirim.
- Untuk uji reminder tanpa menunggu jam sebenarnya, ubah jam masuk/pulang di pengaturan jadwal ke beberapa menit dari sekarang.
- Jangan membagikan file service account Firebase atau memasukkannya ke git.
- Satu fase per sesi agent; test manual dulu sebelum lanjut.
