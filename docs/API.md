# Kontrak API — Sistem Absensi (Kelompok 1)

Base URL: `http://<host>:8000/api`
Auth mobile: **Bearer token** (Sanctum) dari `POST /auth/login`.
Semua respons JSON. Sukses: `{ "success": true, "message": "...", "data": ... }`.
Error: `{ "success": false, "message": "...", "errors": { ... } }` dengan status 401/403/404/422/429.

> Menyembunyikan tombol di aplikasi **bukan** pengamanan. Server tetap memeriksa izin; endpoint
> mengembalikan **403** bila izin tidak ada. Aplikasi memakai `GET /me/permissions` untuk
> menyembunyikan tombol (tambah/ubah/hapus/approve).

## Auth

| Method | Path | Izin | Keterangan |
|---|---|---|---|
| POST | `/auth/login` | – | Body: `login` (email/NIP), `password`, `device_uid?`, `device_name?`. Device pertama = utama. Rate limit 6/menit. |
| POST | `/auth/logout` | – | Hapus token aktif. |
| GET | `/me` | – | Profil: role, employee, department, work_location. |
| GET | `/me/menus` | – | Menu mobile sesuai role (terfilter izin view + aktif). |
| GET | `/me/permissions` | – | `{ is_superadmin, keys: [...] }`. |

## Wajah

| Method | Path | Izin | Keterangan |
|---|---|---|---|
| POST | `/face/enroll` | – | `photos[]` (di-embed server) atau `embeddings[]`. Simpan template terenkripsi. |
| GET | `/face/template` | – | Unduh template sendiri (embedding + model_version). |
| POST | `/face/verify` | – | `photo` -> `{ score, threshold, match }`. |

Error wajah: `422` message "Wajah tidak terdeteksi." / "Terdeteksi lebih dari satu wajah." / "Wajah belum terdaftar."

## Device

| Method | Path | Izin | Keterangan |
|---|---|---|---|
| GET | `/devices` | – | Device milik sendiri. |
| POST | `/devices/register-backup` | – | `device_uid`, `name?`. Maks 1 cadangan. |

## Absensi

| Method | Path | Izin | Keterangan |
|---|---|---|---|
| GET | `/time` | – | `{ server_time, timezone }` untuk anchor offline. |
| POST | `/attendance/check-in` | `attendance.create` | `lat`, `lng`, `device_uid`, `photo`, `face_score_local?`. Respons: status/telat/warna, approval_status. |
| POST | `/attendance/check-out` | `attendance.create` | Sama. Respons early_leave_minutes. |
| POST | `/attendance/sync` | `attendance.create` | Batch offline idempoten (client_uuid). Lihat struktur di bawah. |
| GET | `/attendance/summary` | `attendance.view` | `?year=&month=` ringkasan bulanan + kalender harian. |

`POST /attendance/sync` body:
```json
{
  "anchor": { "server_time": "2026-10-19T08:00:00+07:00", "elapsed_realtime": 1000, "boot_count": 5 },
  "boot_count": 5,
  "items": [
    { "client_uuid": "uuid", "type": "in", "lat": -6.2, "lng": 106.8,
      "elapsed_realtime": 601000, "device_uid": "abc", "face_score_local": 0.9,
      "photo": "<base64>" }
  ]
}
```
Respons `data[]`: `{ client_uuid, status: created|duplicate|skipped_existing, review_flag, time_trust }`.

## Approval Kehadiran (device cadangan)

| Method | Path | Izin | Keterangan |
|---|---|---|---|
| GET | `/attendance-approval` | `attendance_approval.view` | Pending department sendiri (manager). |
| POST | `/attendance-approval/{id}/approve` | `attendance_approval.approve` | Hanya manager department yang sama. |
| POST | `/attendance-approval/{id}/reject` | `attendance_approval.approve` | |

## Pengajuan (cuti/sakit/izin/dinas)

| Method | Path | Izin | Keterangan |
|---|---|---|---|
| POST | `/leave-requests` | `leave_requests.create` | `type`, `start_date`, `end_date`, `reason?`, `attachment?` (sakit). |
| GET | `/leave-requests` | `leave_requests.view` | Riwayat sendiri. |
| GET | `/leave-balance` | `leave_requests.view` | `{ year, quota, used, remaining }`. |
| GET | `/leave-approval` | `leave_requests.approve` | Inbox manager (karyawan department sama). |
| POST | `/leave-approval/{id}/approve` | `leave_requests.approve` | |
| POST | `/leave-approval/{id}/reject` | `leave_requests.approve` | Body `reason` **wajib**. |

## Statistik & Notifikasi

| Method | Path | Izin | Keterangan |
|---|---|---|---|
| GET | `/team-stats` | `team_stats.view` | Manager: hadir/telat/belum absen hari ini. |
| POST | `/push-tokens` | – | `token`, `platform`. |
| GET | `/notifications` | – | Daftar notifikasi. |
| POST | `/notifications/read-all` | – | Tandai semua dibaca. |
| POST | `/notifications/{id}/read` | – | Tandai satu dibaca. |

## Menu mobile (feature_key) yang harus didukung Flutter

Dari seeder `MenuSeeder` (platform `mobile`):

| feature_key | Label | Role |
|---|---|---|
| `home` | Beranda | karyawan, manager |
| `attendance` | Absensi | karyawan, manager |
| `history` | Riwayat | karyawan, manager |
| `leave` | Pengajuan | karyawan, manager |
| `approval` | Approval | manager |
| `team_stats` | Statistik Tim | manager |
| `notifications` | Notifikasi | karyawan, manager |
| `profile` | Profil | karyawan, manager |

`GET /me/menus` mengembalikan daftar ini sudah terfilter izin view & status aktif (superadmin bisa menonaktifkan dari web).
