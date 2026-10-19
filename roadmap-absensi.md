# Roadmap & Prompt OpenCode — Sistem Absensi Perusahaan

**Stack:** Laravel 13 (API + web admin, **tanpa React**) · Flutter (Android) · Python FastAPI + OpenCV (service wajah) · MySQL (Laragon, local dulu)
**Skala:** 200–500 karyawan, 2 lokasi awal (superadmin bisa menambah)
**Cara kerja:** satu milestone per sesi opencode, test manual dulu sebelum lanjut.

## Dua Kelompok Pengerjaan

| Kelompok | Isi | Selesai kalau |
|---|---|---|
| **Kelompok 1 — Backend & Web Admin** (milestone `B0`–`B11`) | Seluruh backend Laravel (semua API) + web sederhana superadmin (Blade + Tailwind + Alpine.js) + service wajah Python | Semua API lulus feature test, dokumentasi API siap, web admin lengkap |
| **Kelompok 2 — Aplikasi Mobile Flutter** (milestone `F0`–`F8`) | Aplikasi Android karyawan & manager yang memakai API dari Kelompok 1 | UAT selesai, APK release jadi |

**Kelompok 2 baru dimulai setelah Kelompok 1 selesai.** Dengan begitu aplikasi mobile dibangun di atas API yang sudah stabil, bukan API yang masih berubah-ubah.

---

## 0. Keputusan yang sudah disepakati

| Area | Keputusan |
|---|---|
| Role | `karyawan` (staff), `manager_department`, `superadmin` |
| Backend | **Laravel 13** (butuh PHP 8.3+), API untuk mobile + web admin |
| Web admin | Khusus superadmin. **Hanya Laravel**: Blade + Tailwind + Alpine.js. Tanpa React/Vue/Inertia |
| Mobile | Flutter Android untuk karyawan & manager. Superadmin tidak memakai mobile |
| Manajemen akses & menu | Superadmin mengatur **izin per modul dengan aksi Lihat, Tambah, Ubah, Hapus** (plus aksi khusus seperti Ekspor/Approve) untuk tiap role, serta **urutan dan label menu (web & mobile)**. Menu tampil otomatis jika role punya izin Lihat modul tersebut |
| Wajah | **Hybrid**: cocokkan di HP (bisa offline), verifikasi ulang di server lewat service Python (FastAPI + OpenCV). **Liveness wajib** |
| Data wajah | Embedding disimpan permanen di server. Foto crop wajah saat absen disimpan **30 hari lalu dihapus otomatis** |
| Jadwal kerja | **1 shift**, berlaku semua karyawan, diatur superadmin. Hanya absen **masuk dan pulang** |
| Keterlambatan | 3 range dinamis diatur superadmin (contoh: ≤5 menit toleransi, 5–15 kuning, >15 merah) |
| Pulang awal | Dihitung otomatis dari jam pulang |
| Lokasi absen | 3 mode: **titik + radius**, **polygon (min 3 titik)**, **tanpa lokasi (off)**. 1 karyawan terikat **1 lokasi**. Superadmin bisa menambah lokasi |
| Dinas | Selama dinas yang disetujui boleh absen di lokasi mana saja (wajah & anti fake GPS tetap diperiksa), absen ditandai "dinas" |
| Tanggal merah | Diinput manual superadmin per tahun. Hari libur/weekend/tanggal merah = tidak perlu absen |
| Offline | Absen tersimpan lokal, auto sync saat ada jaringan. Waktu dicatat dengan **elapsed-realtime** |
| Cuti | Saldo per karyawan, default **12 hari/tahun**, bisa diubah superadmin. Sakit & izin tidak memotong jatah |
| Dinas vs SPD | Tidak terhubung dengan sistem SPD/DPD. Karyawan mengajukan dinas sendiri |
| Approval | Pengajuan karyawan → **manager department yang sama**. Pengajuan manager → **superadmin** |
| Device binding | 1 akun = 1 device utama. **Device cadangan** tersedia; absen di device cadangan butuh approval kehadiran dari **manager department karyawan itu sendiri** |
| Koreksi absen manual | Tidak ada |
| Audit log | Hanya sisi superadmin |
| Android | minSdk 24 (Android 7.0), semua ukuran layar termasuk tablet, dark mode |
| Notifikasi | Push notification (FCM) |
| Deploy | Local dulu |

### Asumsi saya (tolong dikoreksi kalau salah)

1. **Manager** memakai aplikasi mobile saja (approval + statistik departemennya). Dashboard/laporan seluruh perusahaan hanya di web superadmin.
2. Absen di device cadangan yang **ditolak manager** dihitung alfa.
3. Absen offline yang gagal verifikasi ulang di server ditandai **"perlu review"**. Superadmin hanya menandai valid/tidak valid, **bukan mengubah jam**.
4. Penggantian device **utama** yang rusak permanen: superadmin me-reset binding dari web, device baru mengunduh template wajah dari server (tidak daftar ulang).
5. Pengajuan izin/sakit boleh dibuat **mundur** (batas diatur superadmin, default 3 hari) untuk kasus HP rusak/lupa absen.
6. Zona waktu default `Asia/Jakarta`, bisa diubah di pengaturan.
7. **Manajemen akses:** tiga role dasar bersifat tetap (logika approval bergantung pada role), tetapi **izin per modul dan per aksi (Lihat/Tambah/Ubah/Hapus) tiap role bisa diatur**. Membuat role baru tidak termasuk di versi ini. Role superadmin selalu memegang semua izin dan tidak bisa dikunci keluar.
8. Menu mobile yang diatur superadmin berarti **menu mana yang tampil per role**. Layar baru tetap butuh pembaruan aplikasi.

### Hasil pengecekan versi (Oktober 2026)

- **Laravel 13** (rilis 17 Maret 2026) butuh **PHP 8.3 atau lebih tinggi**. Laravel 11 sudah habis dukungan keamanan sejak Maret 2026. Jadi cek dulu `php -v` di Laragon, dan upgrade PHP-nya jika masih di bawah 8.3 (langkah ada di prompt B0).
- **Flutter** stabil saat ini 3.44.x. Minimum Android dinaikkan sejak Flutter 3.35 (rujukan resmi menyebut minSdk 24). Jadi Android 5/6 praktis tidak didukung. Selalu cek `flutter.minSdkVersion` di project hasil `flutter create`.
- Library wajah di Flutter berubah cepat dan saya **belum bisa memverifikasi** dukungan `opencv_dart` untuk model pengenal wajah. Karena itu ada milestone **spike** (`F1`) sebelum enrollment dibangun.
- Paket pihak ketiga (misalnya `spatie/laravel-permission`) harus dicek kompatibilitasnya dengan Laravel 13 saat dipasang. Prompt meminta opencode memeriksa dan memakai implementasi sendiri jika belum kompatibel.

---

## 1. Struktur Repo

```
absensi/
├─ backend/        Laravel 13 (API + web admin)
├─ mobile/         Flutter (mulai di Kelompok 2)
├─ face-service/   Python FastAPI + OpenCV
└─ ROADMAP.md
```

## 2. Hak Akses Bawaan (bisa diubah superadmin)

Ini hanya **nilai awal** (seeder). Setelah B2, superadmin mengatur per modul dan per aksi (Lihat, Tambah, Ubah, Hapus) dari web admin. Izin Hapus tidak ikut aktif saat Ubah dicentang.

| Fitur | Karyawan | Manager | Superadmin |
|---|---|---|---|
| Absen masuk/pulang | ✅ | ✅ | – |
| Ringkasan absensi sendiri | ✅ | ✅ | – |
| Ajukan cuti/sakit/izin/dinas | ✅ | ✅ | – |
| Approve pengajuan & kehadiran device cadangan | – | ✅ (department sendiri) | ✅ (pengajuan manager) |
| Statistik tim | – | ✅ (department sendiri) | ✅ (semua, di web) |
| Master data, lokasi, jadwal, tanggal merah, jatah cuti | – | – | ✅ |
| Laporan, ekspor, audit log | – | – | ✅ |
| Manajemen akses & menu | – | – | ✅ (terkunci) |

> **Prinsip penting:** menyembunyikan menu atau tombol bukan pengamanan. Setiap endpoint API dan halaman web tetap memeriksa **izin aksi** (view/create/update/delete/export/approve) di sisi server. Cakupan "department sendiri" untuk manager adalah aturan data yang berlaku di atas izin.

## 3. Skema Database (acuan)

```
users                id, name, email, password, role(enum), is_active
departments          id, name
employees            id, user_id, nip, name, department_id, work_location_id, is_active
work_locations       id, name, mode(point|polygon|off), lat, lng, radius_m, polygon_json
work_schedule        id, work_days(json), start_time, end_time, timezone   (1 baris)
lateness_rules       id, label, from_minute, to_minute(null=tak terbatas), color, is_counted_late
holidays             id, date, name

-- manajemen akses & menu
modules              id, key (mis. employees), label, platform(web|mobile|both),
                     extra_actions(json, mis. ["export"] atau ["approve"])
permissions          id, module_id, action(view|create|update|delete|export|approve),
                     key (format modul.aksi, mis. employees.update)
role_permissions     role, permission_id
menus                id, platform(web|mobile), module_id, label, icon, parent_id, sort_order,
                     route_or_feature_key, is_active, is_locked
                     -- menu tampil jika is_active DAN role punya izin view pada modulnya

devices              id, employee_id, device_uid, name, type(primary|backup), status, registered_at
face_templates       id, employee_id, embedding(encrypted), model_version, created_at
attendances          id, employee_id, date, check_in_at, check_out_at,
                     in_lat, in_lng, out_lat, out_lng, location_id,
                     late_minutes, late_level, early_leave_minutes,
                     is_dinas, is_offline, time_trust(ok|suspect), client_uuid,
                     device_id, is_backup_device, approval_status(none|pending|approved|rejected),
                     approver_id, face_score_local, face_score_server,
                     review_flag, review_status(null|valid|invalid), review_note
face_captures        id, attendance_id, type(in|out), path, expires_at
leave_balances       id, employee_id, year, quota, used
leave_requests       id, employee_id, type(cuti|sakit|izin|dinas), start_date, end_date,
                     reason, attachment_path, status(pending|approved|rejected),
                     approver_id, rejection_reason
push_tokens          id, user_id, token, platform
notifications        id, user_id, title, body, data_json, read_at, created_at
audit_logs           id, actor_id, action, entity_type, entity_id, old_json, new_json, created_at
settings             key, value
```

**Aturan penting:**
- Approver ditentukan dari **role + department**: manager dengan `department_id` sama dengan karyawan. Pengajuan manager → superadmin. Tiap department hanya boleh punya 1 manager aktif.
- Waktu disimpan UTC, ditampilkan sesuai timezone pengaturan.
- Model wajah (`model_version`) di server **harus kompatibel** dengan model di HP. Jika spike `F1` memilih model berbeda dari default server, face-service disesuaikan.

---

## 4. Daftar Milestone

### Kelompok 1 — Backend & Web Admin (Laravel saja)

| # | Milestone | Fokus |
|---|---|---|
| B0 | Setup & skeleton | Pastikan PHP ≥ 8.3, Laravel 13, Tailwind, face-service kosong |
| B1 | Master data & auth | Role, department, karyawan, lokasi, Sanctum (mobile) + login web |
| B2 | **Manajemen akses & menu** | Matriks izin per modul (Lihat/Tambah/Ubah/Hapus), menu web & mobile dinamis, kunci anti-lockout |
| B3 | Web admin: master & pengaturan | CRUD, peta lokasi, jadwal, aturan telat, tanggal merah, jatah cuti, audit log |
| B4 | Rules engine | Geofence 3 mode, telat/pulang awal, hari libur, dinas + unit test |
| B5 | Face-service & API wajah | Enroll/verify, template terenkripsi, test dengan foto uji |
| B6 | API absensi online + device | Check-in/out, device utama & cadangan, approval kehadiran |
| B7 | API offline sync | Sync batch, elapsed-realtime, verifikasi ulang, review flag |
| B8 | API cuti/sakit/izin/dinas | Pengajuan, saldo, approval bertingkat |
| B9 | Notifikasi, ringkasan & job terjadwal | FCM server, endpoint ringkasan/statistik, purge foto 30 hari |
| B10 | Laporan, dashboard, statistik web | Dashboard, rekap, review flag, ekspor Excel/PDF |
| B11 | Hardening & gerbang Kelompok 1 | Dokumentasi API, feature test, seeder, keamanan |

### Kelompok 2 — Aplikasi Mobile Flutter

| # | Milestone | Fokus |
|---|---|---|
| F0 | Fondasi Flutter | Arsitektur, tema gelap, responsif, login, **menu dinamis dari API**, FCM |
| F1 | **Spike wajah** | Buktikan library OpenCV on-device (titik berhenti) |
| F2 | Enrollment & liveness | Daftar wajah, tantangan liveness, unduh template |
| F3 | Absen online | GPS, blok mock location, wajah, absen masuk/pulang |
| F4 | Offline & sync | Antrian lokal, elapsed-realtime, auto sync |
| F5 | Device utama & cadangan | Sisi aplikasi, approval kehadiran manager |
| F6 | Pengajuan & approval | Cuti/sakit/izin/dinas, inbox manager |
| F7 | Ringkasan, statistik, notifikasi | Kalender, statistik tim, daftar notifikasi |
| F8 | Hardening & rilis lokal | Anti-spoof, performa HP lama, tablet, UAT, APK |

---

## 5. Prompt OpenCode — Kelompok 1 (Backend & Web Admin)

> Tambahkan di awal setiap sesi: *"Project absensi: backend Laravel 13 + web admin (Blade/Tailwind/Alpine, TANPA React/Vue/Inertia), mobile Flutter dibangun belakangan, face-service Python. Baca ROADMAP.md bagian 0 sebagai acuan keputusan. Mulai B3, gunakan izin berformat modul.aksi dari B2 (view/create/update/delete/export/approve) untuk semua pemeriksaan akses."*

### B0 — Setup & Skeleton

```
Bangun skeleton project "absensi": folder backend (Laravel 13), face-service (Python
FastAPI). Folder mobile dikerjakan nanti, jangan dibuat dulu.

1. Cek `php -v`. Laravel 13 butuh PHP 8.3 atau lebih tinggi. Jika PHP di Laragon masih di
   bawah itu, beri saya langkah menambah/mengganti versi PHP di Laragon (Menu > PHP) dan
   berhenti sampai saya konfirmasi sudah beres.
2. backend: `composer create-project laravel/laravel:^13.0 backend`. Konfigurasi MySQL
   Laragon (db "absensi_db", user root, password kosong), install Sanctum, siapkan Tailwind
   via Vite dan Alpine.js untuk web admin. JANGAN pasang React, Vue, Inertia, maupun Livewire.
3. face-service: FastAPI + uvicorn + opencv-python + numpy di virtualenv, endpoint GET
   /health. Autentikasi antar service lewat header shared secret dari .env.
4. Pastikan Laravel bisa memanggil /health face-service lewat HTTP client.
5. README di root: cara menjalankan semuanya di Windows/Laragon.
Jangan buat fitur bisnis dulu.
```

### B1 — Master Data & Auth

```
Lanjutan project absensi (Laravel 13, tanpa React). Buat master data dan autentikasi.

Role (kolom enum di users): karyawan, manager_department, superadmin.
Tabel: users, departments, employees (user_id, nip, name, department_id,
work_location_id, is_active), work_locations (name, mode point|polygon|off, lat, lng,
radius_m, polygon_json).

Aturan:
- Satu karyawan terikat tepat satu work_location.
- Per department hanya boleh 1 manager_department aktif (validasi + pesan jelas).
- Auth mobile: Sanctum token (login NIP/email + password, logout, GET /api/me berisi role,
  employee, department, lokasi kerja). Auth web admin: session login, hanya superadmin.
- Seeder: 1 superadmin, 2 department, 2 lokasi contoh (satu point, satu polygon),
  1 manager per department, beberapa karyawan.
- Form Request, API Resource, struktur respons error yang konsisten.

Siapkan helper audit log (tabel audit_logs + trait/observer), dipakai di B3.
```

### B2 — Manajemen Akses & Menu

```
Lanjutan project absensi (Laravel 13, Blade + Tailwind + Alpine, tanpa React). Bangun
manajemen akses dan menu yang diatur superadmin.

A. MODUL & IZIN
- Tabel modules (key, label, platform, extra_actions), permissions (module_id, action, key)
  dan role_permissions. Aksi standar tiap modul: view, create, update, delete. Aksi tambahan
  per modul bila perlu: export (laporan), approve (pengajuan, approval kehadiran).
  Format key izin: "modul.aksi", contoh employees.update.
- Modul awal: employees, departments, locations, schedule, lateness, holidays, leave_quota,
  settings, leave_requests, attendance_approval, attendance_reports, review, devices,
  audit_logs, access, menus.
- Cek apakah spatie/laravel-permission kompatibel dengan Laravel 13. Jika ya, boleh dipakai
  (role tetap dari enum). Jika belum, buat implementasi sendiri (Gate + tabel di atas).
- Halaman web "Manajemen Akses": untuk tiap role, tabel modul x aksi dengan kotak centang
  Lihat / Tambah / Ubah / Hapus (+ kolom Ekspor/Approve bila modul punya). Kotak yang tidak
  berlaku untuk modul tersebut dinonaktifkan. Sediakan "centang semua" per baris dan per kolom.
  Mencentang Ubah TIDAK otomatis mengaktifkan Hapus.
- Terapkan pemeriksaan izin di SEMUA route web dan API sesuai aksi: daftar/detail = view,
  form dan simpan baru = create, edit = update, hapus = delete. Tombol Tambah/Ubah/Hapus di
  web hanya tampil jika izinnya ada. Server tetap menolak (403) tanpa izin, termasuk bila API
  dipanggil langsung. Menyembunyikan tombol BUKAN pengamanan.
- Izin berlaku bersama aturan data. Contoh: manager hanya melihat dan memutuskan data
  department sendiri apa pun izinnya.

B. MENU
- Tabel menus (platform web|mobile, module_id, label, icon, parent_id, sort_order,
  route_or_feature_key, is_active, is_locked).
- Sidebar web dibangun dari database. Menu tampil jika is_active DAN role user punya izin
  view pada modul menu tersebut.
- Halaman web "Manajemen Menu": superadmin mengubah label, ikon, urutan (naik/turun atau
  drag), dan mengaktifkan/menonaktifkan menu, terpisah untuk platform web dan mobile.
  Hak tampil per role tidak diatur di sini karena mengikuti izin view dari Manajemen Akses.
- Endpoint API: GET /api/me/menus (menu mobile untuk role user, sudah terfilter izin view)
  dan GET /api/me/permissions (daftar izin lengkap, agar aplikasi bisa menyembunyikan tombol
  Tambah/Ubah/Hapus/Approve).
- Seeder menu mobile awal (feature_key): home, attendance, history, leave, profile,
  approval (manager), team_stats (manager), notifications.

C. PENGAMAN
- Superadmin selalu memegang semua izin. Izin modul access dan menus (semua aksi) terkunci
  untuk superadmin dan tidak bisa dicabut. Menu "Manajemen Akses/Menu" is_locked = true.
- Tiga role dasar tidak bisa dihapus.
- Semua perubahan izin dan menu tercatat di audit log (siapa, kapan, sebelum/sesudah).
- Cache izin dan menu per role, invalidate otomatis saat diubah.

Tulis feature test:
- Role dengan izin Lihat saja: bisa membuka daftar, tetapi create/update/delete mengembalikan
  403 baik di web maupun API.
- Mencentang Ubah tidak otomatis mengaktifkan Hapus.
- Menu hilang dari /api/me/menus saat izin view modulnya dicabut.
- Manager tidak bisa melihat data department lain meski punya izin view.
- Superadmin tidak bisa mencabut izin modul access/menus miliknya sendiri.
```

### B3 — Web Admin: Master & Pengaturan

```
Lanjutan project absensi. Bangun halaman web admin superadmin (Blade + Tailwind + Alpine.js)
memakai layout sidebar dinamis dari B2. Buat komponen Blade yang dipakai ulang (tabel, form
field, modal, badge). Setiap halaman wajib memeriksa izin dari B2.

1. CRUD department dan karyawan (assign department, lokasi kerja, role, aktif/nonaktif).
2. CRUD lokasi absen dengan 3 mode:
   - point: klik peta untuk titik + input radius (meter)
   - polygon: gambar polygon di peta, minimal 3 titik
   - off: tanpa pengecekan lokasi
   Gunakan Leaflet + OpenStreetMap (leaflet-draw). Validasi juga di backend.
3. Pengaturan jadwal kerja (1 shift): hari kerja, jam masuk, jam pulang, timezone.
4. Pengaturan 3 range keterlambatan (batas menit dan warna per range).
5. Kelola tanggal merah per tahun.
6. Jatah cuti default (12 hari) dan jatah per karyawan.
7. Pengaturan lain: batas hari pengajuan izin/sakit mundur (default 3).
8. Halaman audit log (filter aktor, aksi, tanggal).
Semua perubahan pada 1-7 tercatat di audit log. Cache pengaturan dan invalidate saat diubah.
Tombol Tambah, Ubah, dan Hapus di setiap halaman hanya tampil jika role punya izin aksi
tersebut (create/update/delete) dari B2, dan route-nya diperiksa di server.
```

### B4 — Rules Engine

```
Lanjutan project absensi. Buat service backend untuk aturan absensi, murni logic dengan unit
test lengkap (belum ada endpoint absen).

1. GeofenceService: point (haversine <= radius), polygon (point-in-polygon, ray casting),
   off (selalu lolos).
2. ScheduleService: apakah suatu tanggal hari kerja (hari kerja + tanggal merah + timezone).
3. LatenessService: hitung late_minutes dan range (toleransi/kuning/merah) dari
   lateness_rules dinamis.
4. Pulang awal: hitung early_leave_minutes dari jam pulang jadwal.
5. Dinas: jika ada leave_request tipe dinas berstatus approved pada tanggal tsb, geofence
   di-bypass dan attendance ditandai is_dinas.
Test: tepat di batas radius, titik di dalam/luar polygon (termasuk polygon cekung), batas
toleransi 5/15 menit, tanggal merah, weekend, dinas.
```

### B5 — Face-Service & API Wajah

```
Lanjutan project absensi. Bangun sisi server untuk wajah.

face-service (Python):
- Endpoint /embed (gambar -> embedding) dan /verify (gambar + embedding tersimpan -> skor
  kemiripan + keputusan) memakai OpenCV (detektor YuNet + pengenal SFace dari OpenCV Zoo).
  Catat model_version. Dilindungi shared secret, hanya dipanggil Laravel.
- Tolak gambar tanpa wajah atau dengan lebih dari satu wajah.

Laravel:
- Endpoint enrollment: terima beberapa embedding/foto sampel, simpan embedding terenkripsi di
  face_templates (JANGAN simpan foto permanen). Endpoint unduh template milik sendiri.
- Endpoint verifikasi server yang dipakai alur absen (B6/B7).
- Simpan model_version supaya kompatibilitas dengan model di HP bisa dicek.
Test dengan beberapa foto uji (orang sama vs berbeda, tanpa wajah, banyak wajah).
Jelaskan cara saya menyiapkan foto uji dan model ONNX.
```

### B6 — API Absensi Online + Device

```
Lanjutan project absensi. Bangun API absen masuk/pulang dan device binding.

- POST check-in/check-out: waktu memakai waktu SERVER. Validasi: sudah absen hari itu, hari
  non-kerja, geofence sesuai lokasi karyawan (kecuali dinas/mode off), wajah terdaftar,
  face_score lokal dikirim client. Verifikasi ulang via face-service, simpan
  face_score_server. Foto crop disimpan ke face_captures dengan expires_at = +30 hari.
- Respons memuat status (tepat waktu/telat + warna range).
- Device binding: login pertama menjadikan device utama. Device lain tidak bisa absen
  sebagai utama. Karyawan bisa mendaftarkan 1 device cadangan.
- Absen dari device cadangan: is_backup_device = true, approval_status = pending. Approval
  HANYA bisa dilihat/diputuskan oleh manager department karyawan tersebut (query role +
  department). Approved = hadir; rejected = alfa. Endpoint inbox approval kehadiran (izin attendance_approval.view dan attendance_approval.approve).
- Superadmin reset device dari web (izin devices.update, tercatat di audit log).
Test: manager department lain tidak bisa melihat/approve, device ketiga ditolak, absen dobel.
```

### B7 — API Offline Sync

```
Lanjutan project absensi. Bangun endpoint sync absen offline.

- Endpoint sync batch menerima daftar absen dengan client_uuid (idempotent: kirim ulang tidak
  membuat data dobel), lat/lng, face_score lokal, foto crop, device_uid, dan data waktu:
  elapsedRealtime saat absen, anchor terakhir (waktu server + elapsedRealtime saat sync
  terakhir), dan boot count.
- Server menghitung ulang waktu absen: anchor_server + (elapsed_absen - elapsed_anchor).
  Jika boot count berubah sejak anchor (HP restart), set time_trust = suspect.
- Verifikasi ulang wajah via face-service. Jika tidak cocok atau time_trust = suspect, set
  review_flag (tidak menolak otomatis).
- Terapkan aturan geofence, telat, hari libur, dan device cadangan seperti B6.
- Endpoint waktu server untuk membentuk anchor.
Test: absen offline lalu sync, restart HP, dobel kirim, batch campuran, device cadangan.
```

### B8 — API Cuti, Sakit, Izin, Dinas

```
Lanjutan project absensi. Bangun API pengajuan.

- leave_requests (cuti|sakit|izin|dinas), leave_balances per karyawan per tahun (default 12,
  hangus akhir tahun, diubah superadmin).
- Aturan: cuti hanya memotong hari KERJA (abaikan weekend/tanggal merah) dan tidak boleh
  melebihi saldo. Sakit & izin tidak memotong saldo; sakit boleh lampiran. Izin/sakit boleh
  mundur sesuai batas di settings. Cegah tumpang tindih.
- Approval: karyawan -> manager department yang SAMA. Pengajuan manager -> superadmin (di web
  admin, izin leave_requests.approve). Alasan wajib saat reject.
- Setelah approved: hari tsb tidak dihitung alfa; dinas mengaktifkan bypass lokasi (B4).
- Endpoint: ajukan, riwayat, saldo, inbox approval manager, approve/reject.
Halaman web superadmin untuk menyetujui pengajuan manager.
Test: saldo kurang, rentang melewati weekend/tanggal merah, manager beda department.
```

### B9 — Notifikasi, Ringkasan & Job Terjadwal

```
Lanjutan project absensi. Lengkapi sisi server untuk mobile.

- Push notification via FCM (kirim dari Laravel, token dari push_tokens) dan tabel
  notifications untuk daftar di dalam aplikasi. Event: pengajuan baru ke manager, keputusan
  approval, approval kehadiran device cadangan. Jelaskan langkah manual di Firebase console.
- Endpoint ringkasan absensi sendiri (bulanan: hadir, telat per range, total menit telat,
  cuti/sakit/izin/dinas, libur, alfa, sisa cuti) dan data kalender per hari berwarna.
- Endpoint statistik tim untuk manager (department sendiri): kehadiran hari ini, telat,
  belum absen.
- Job terjadwal harian: hapus face_captures yang melewati expires_at (file + baris),
  tandai alfa untuk hari kerja yang lewat tanpa absen/izin.
Test: purge hanya menghapus yang kedaluwarsa, template wajah tidak ikut terhapus.
```

### B10 — Laporan, Dashboard, Statistik (Web)

```
Lanjutan project absensi. Bangun laporan dan dashboard di web admin (Blade + Chart.js).

- Dashboard: kehadiran hari ini, telat, belum absen, cuti/sakit/izin/dinas, tren 30 hari,
  per department dan per lokasi.
- Rekap harian/bulanan per karyawan, department, lokasi dengan filter periode.
- Daftar "perlu review": lihat foto crop (selama belum kedaluwarsa), skor wajah lokal vs
  server, time_trust. Superadmin hanya menandai valid/tidak valid (izin review.update),
  tidak mengubah jam, tercatat di audit log.
- Ekspor Excel (maatwebsite/excel, cek kompatibilitas Laravel 13) dan PDF (dompdf).
- Query efisien untuk 200-500 karyawan (index, agregasi di database, cache dashboard).
Semua halaman memeriksa izin dari B2.
```

### B11 — Hardening & Gerbang Kelompok 1

```
Lanjutan project absensi. Tahap penutup Kelompok 1 (backend + web).

1. Dokumentasi API otomatis (Scribe atau OpenAPI) + koleksi Postman, lengkap dengan contoh
   respons dan kode error. Ini menjadi kontrak untuk aplikasi mobile.
2. Pastikan seluruh feature test lulus, termasuk matriks akses (tiap role vs tiap endpoint).
3. Review keamanan: rate limit login, validasi upload, enkripsi template wajah, akses antar
   department, shared secret face-service, tidak ada endpoint tanpa pemeriksaan izin.
4. Seeder data dummy realistis (200 karyawan, 2 lokasi, riwayat 2 bulan).
5. Checklist backup database dan penghapusan otomatis foto >30 hari.
6. Ringkasan: daftar endpoint, izin, dan menu mobile (feature_key) yang harus didukung Flutter.
```

> **Gerbang Kelompok 1:** semua API terdokumentasi dan teruji, web admin lengkap. Baru setelah ini mulai Kelompok 2.

---

## 6. Prompt OpenCode — Kelompok 2 (Mobile Flutter)

> Tambahkan di awal setiap sesi: *"Project absensi, Kelompok 2: aplikasi Flutter di folder mobile, memakai API backend Laravel 13 yang sudah selesai (lihat dokumentasi API). Baca ROADMAP.md bagian 0."*

### F0 — Fondasi Flutter

```
Buat folder mobile: `flutter create` untuk Android saja, set minSdk 24 dan pastikan sesuai
flutter.minSdkVersion versi terbaru. Paket dasar: dio, flutter_riverpod, go_router,
flutter_secure_storage.

- Arsitektur feature-first: lib/core, lib/features/{auth,attendance,leave,profile,...}.
- Networking: dio + interceptor token, error handling seragam sesuai kontrak API.
- Tema terang & gelap (ikuti sistem + toggle manual), Material 3.
- Layout responsif HP kecil sampai tablet (LayoutBuilder/breakpoints, jangan hardcode ukuran).
- Komponen reusable: tombol, kartu status, empty/error/loading state.
- Login, token di secure storage.
- NAVIGASI DINAMIS: setelah login panggil GET /api/me/menus dan /api/me/permissions, lalu
  bangun bottom navigation/drawer dari sana (feature_key dipetakan ke layar yang ada; layar
  yang belum dibuat tampil placeholder "segera hadir"; feature_key tak dikenal diabaikan).
  Menu yang dinonaktifkan superadmin tidak boleh tampil. Gunakan /api/me/permissions juga untuk
  menyembunyikan tombol aksi (tambah/ubah/hapus/approve) di layar; API tetap pemutus akhir.
- Firebase Cloud Messaging: minta izin notifikasi, kirim token ke backend.
Belum ada fitur absen.
```

### F1 — Spike Wajah (titik berhenti)

```
RISET, belum membangun fitur. Buktikan pengenalan wajah on-device dengan OpenCV (bukan Google
ML Kit) di Flutter. Evaluasi paket opencv_dart (dartcv) dengan YuNet (deteksi) dan SFace
(pengenal), dibandingkan alternatif TFLite/MobileFaceNet jika opencv_dart tidak memungkinkan.

Penting: embedding di HP harus KOMPATIBEL dengan face-service server (model_version).
Utamakan SFace agar sama dengan server; jika memilih model lain, beri tahu bahwa face-service
perlu disesuaikan.

Ukur: ukuran APK, waktu per frame, akurasi dasar (orang sama vs berbeda), dan kinerja di
HP spek rendah (Android 7). Rekomendasikan pilihan akhir beserta alasan. BERHENTI dan
tunjukkan hasilnya kepada saya sebelum lanjut.
```

### F2 — Enrollment & Liveness

```
Lanjutan Flutter. Berdasarkan hasil F1 yang sudah saya setujui:

1. Liveness aktif (tantangan acak: kedip atau tengok kiri/kanan) sebelum wajah diterima.
2. Alur daftar wajah wajib sebelum bisa absen: ambil beberapa sampel, kirim ke API enrollment
   (B5). Tampilkan layar persetujuan karyawan untuk data biometrik.
3. Unduh template milik sendiri dari server dan simpan terenkripsi di HP untuk pencocokan lokal.
Jangan simpan foto wajah di HP lebih lama dari yang diperlukan.
```

### F3 — Absen Online

```
Lanjutan Flutter. Bangun absen masuk/pulang saat online.

- Layar absen: ambil GPS, tampilkan status lokasi (di dalam/luar area), jalankan liveness +
  pencocokan wajah lokal, kirim ke API check-in/check-out.
- BLOK MOCK LOCATION: deteksi lokasi palsu (Location.isMock/isFromMockProvider, status opsi
  pengembang mock location, aplikasi fake GPS terpasang). Selama terdeteksi, tombol absen
  nonaktif dengan pesan jelas; setelah dimatikan baru bisa absen. Evaluasi geolocator
  (isMocked), safe_device, atau MethodChannel native dan pilih yang paling andal.
- Wajib wajah terdaftar sebelum absen. Tampilkan hasil (tepat waktu/telat + warna range).
```

### F4 — Offline & Sync

```
Lanjutan Flutter. Tambahkan mode offline dengan auto sync sesuai kontrak API B7.

- Database lokal (drift/SQLite) untuk antrian absen (client_uuid, lat/lng, face_score, foto
  crop terenkripsi, device_uid).
- Waktu offline memakai elapsed-realtime. Simpan elapsedRealtime saat absen, anchor terakhir
  dari server (endpoint waktu server) dan boot count.
- Auto sync saat jaringan kembali (workmanager + listener konektivitas), retry dengan backoff,
  idempotent lewat client_uuid.
- Indikator UI: tersimpan offline, menunggu sync, sudah tersinkron.
Test: absen offline lalu online, restart HP saat offline, kirim dobel.
```

### F5 — Device Utama & Cadangan

```
Lanjutan Flutter. Sisi aplikasi untuk device binding sesuai B6.

- device_uid stabil per instalasi. Login dari device lain: tampilkan layar "Daftarkan device
  cadangan" (maksimal 1).
- Absen di device cadangan menampilkan status "menunggu approval manager".
- Manager: inbox approval kehadiran device cadangan (department sendiri), approve/reject.
- Tampilkan notifikasi saat keputusan keluar.
```

### F6 — Pengajuan & Approval

```
Lanjutan Flutter. Bangun pengajuan sesuai API B8.

- Form cuti/sakit/izin/dinas (lampiran untuk sakit), riwayat + status, sisa cuti.
- Validasi tanggal, tumpang tindih, saldo (pesan error dari API ditampilkan dengan jelas).
- Manager: inbox terpadu pengajuan (department sendiri), approve/reject dengan alasan wajib.
- Pengajuan manager disetujui superadmin lewat web, aplikasi hanya menampilkan statusnya.
```

### F7 — Ringkasan, Statistik, Notifikasi

```
Lanjutan Flutter.

- Ringkasan diri sendiri: kalender bulanan berwarna (hadir/telat kuning/merah/cuti/sakit/izin/
  dinas/libur/alfa), total hadir, total telat, total menit telat, sisa cuti.
- Manager: statistik singkat departemennya (fl_chart): kehadiran hari ini, siapa telat/belum absen.
- Daftar notifikasi di dalam aplikasi + penanganan push saat aplikasi terbuka/background.
- Pastikan semua halaman fit di tablet dan mode gelap.
```

### F8 — Hardening & Rilis Lokal

```
Lanjutan Flutter. Tahap akhir.

1. Anti-spoof tambahan: deteksi root/emulator dan perubahan waktu, dilaporkan ke backend
   sebagai flag (bukan hanya blok di UI).
2. Uji performa di HP spek rendah (Android 7, RAM 2GB): waktu buka kamera, verifikasi wajah,
   ukuran APK; optimalkan (resolusi frame, isolate untuk proses wajah).
3. Uji tata letak berbagai ukuran layar termasuk tablet, mode gelap, font besar.
4. Review keamanan: token, penyimpanan template wajah, pinning/HTTPS bila memungkinkan.
5. Build APK release, panduan instalasi karyawan.
```

---

## 7. Checklist Test Manual Utama

**Kelompok 1 (lewat Postman/dokumentasi API + web):**
1. Cabut izin Tambah modul karyawan untuk satu role → tombol Tambah hilang dan POST mengembalikan 403, sementara daftar karyawan tetap bisa dilihat.
2. Cabut izin Lihat modul approval untuk manager → menu hilang dari /api/me/menus dan endpoint-nya mengembalikan 403.
3. Superadmin tidak bisa mencabut izin modul access dan menus miliknya sendiri.
4. Check-in di dalam radius berhasil; di luar radius ditolak; lokasi mode off selalu berhasil; polygon dalam/luar.
5. Telat 4 menit (toleransi), 10 menit (kuning), 20 menit (merah) sesuai pengaturan.
6. Sync offline: kirim dobel tidak membuat data ganda; boot count berubah → time_trust suspect.
7. Cuti melewati weekend/tanggal merah tidak memotong hari libur; saldo habis → ditolak.
8. Manager department lain tidak bisa melihat/approve pengajuan atau kehadiran karyawan.
9. Pengajuan manager muncul di web superadmin saja.
10. Foto crop >30 hari terhapus otomatis, template wajah tetap ada.

**Kelompok 2 (di HP):**
1. Fake GPS aktif → tombol absen terkunci; dimatikan → bisa absen.
2. Matikan internet → absen → hidupkan → tersinkron tanpa dobel.
3. Device cadangan → approval hanya muncul ke manager department yang benar.
4. Menu yang dinonaktifkan superadmin tidak tampil setelah login ulang.
5. Tampilan benar di HP kecil, tablet, mode gelap.

## 8. Catatan Kerja

- Satu milestone per sesi opencode; test manual dulu sebelum lanjut.
- `F1` punya titik berhenti setelah spike. Jangan membangun enrollment sebelum hasilnya memuaskan, karena pilihan library wajah memengaruhi F2–F5 dan bisa berdampak ke face-service di B5.
- Data wajah adalah **data biometrik**: simpan embedding saja secara permanen, minta persetujuan karyawan, batasi akses.
- Akses HP ke backend di jaringan local: `php artisan serve --host=0.0.0.0` dan alamat IP laptop (atau Tailscale).