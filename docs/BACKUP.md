# Checklist Backup & Pemeliharaan

## 1. Backup database (MySQL/Laragon)

Harian (jadwalkan Task Scheduler):

```bat
"C:\laragon\bin\mysql\mysql-8.0.30-winx64\bin\mysqldump.exe" -u root absensi_db > "D:\backup\absensi_%DATE%.sql"
```

Simpan minimal 14 hari terakhir, salin ke lokasi terpisah. Uji restore berkala:

```bat
mysql -u root absensi_db < D:\backup\absensi_2026-10-19.sql
```

## 2. File storage

Folder `backend/storage/app/private/`:

- `face_captures/` — foto crop absen, **dihapus otomatis** setelah 30 hari.
- `leave_attachments/` — lampiran sakit/izin (kebijakan retensi diserahkan ke perusahaan).
- `face_templates` disimpan di **database** (terenkripsi), bukan file.

Backup folder ini bila lampiran cuti dibutuhkan; foto crop tidak wajib (umur 30 hari).

## 3. Job otomatis (jalankan scheduler)

```
php artisan schedule:work
```

- `app:mark-absentees` (00:05) — tandai alfa hari kerja terlewat.
- `app:purge-expired-face-captures` (01:00) — hapus foto crop > 30 hari (file + baris). Template wajah **tidak** ikut terhapus.

Manual:

```
php artisan app:purge-expired-face-captures
php artisan app:mark-absentees --date=2026-10-18
```

## 4. Checklist keamanan (sudah diterapkan)

- [x] Rate limit login API (6/menit) & web (5/menit); absen/sync 30/menit.
- [x] Password di-hash (bcrypt); token Sanctum; sesi web untuk superadmin.
- [x] Enkripsi embedding wajah di database (`encrypted:array`).
- [x] Shared secret face-service (`x-face-secret`) — Laravel saja yang memanggil.
- [x] Setiap endpoint API memeriksa izin (`permission:modul.aksi`) atau auth; web admin memeriksa izin per aksi.
- [x] Scope data manager (hanya department sendiri) untuk approval, statistik, laporan.
- [x] Upload divalidasi (tipe gambar, ukuran maks 5 MB).
- [x] Foto crop punya `expires_at` + purge otomatis.
- [x] Audit log untuk perubahan master data, izin, menu, approval, review, reset device.
- [ ] Produksi: HTTPS, ganti `APP_DEBUG=false`, rotasi `FACE_SERVICE_SECRET`, pindah FCM ke HTTP v1.

## 5. Data dummy (opsional)

```
php artisan app:seed-dummy --employees=200 --days=60
```

Membuat 200 karyawan + manager + riwayat absensi 2 bulan untuk uji performa laporan/dashboard.
