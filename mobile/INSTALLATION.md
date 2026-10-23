# Panduan Instalasi Aplikasi Absensi Mobile
**PT Bumi Siak Pusako** — Versi 1.0.0

## Persyaratan Sistem
- **Sistem Operasi:** Android 7.0 (API 24) keatas
- **RAM:** Minimal 2GB (disarankan 3GB+)
- **Penyimpanan:** Minimal 100MB tersedia
- **Kamera:** Ya (wajib untuk verifikasi wajah)
- **Lokasi/GPS:** Ya (wajib untuk absen)

## Langkah Instalasi

### 1. Unduh APK
- Dapatkan file APK dari admin/HR
- Nama file: `app-release.apk`

### 2. Aktifkan Sumber Tidak Dikenal
1. Buka **Pengaturan** > **Keamanan**
2. Aktifkan ** Instal dari sumber tidak dikenal** (atau **Instal aplikasi tidak dikenal** di Android 8+)
3. Pilih browser/file manager yang akan digunakan untuk mengunduh APK

### 3. Instal Aplikasi
1. Buka **File Manager**
2. Cari file APK di folder **Downloads**
3. Klik file `app-release.apk`
4. Klik **Instal** dan tunggu proses instalasi selesai
5. Klik **Buka** setelah instalasi berhasil

### 4. Login
1. Buka aplikasi **Absensi - PT Bumi Siak Pusako**
2. Masukkan **NIP** dan **password** yang diberikan HR
3. Jika ini device pertama, device akan otomatis terdaftar sebagai **Device Utama**
4. Jika device cadangan, hubungi manager untuk registrasi

## Panduan Penggunaan

### Absen Masuk/Pulang
1. Buka aplikasi, pastikan berada di area kerja
2. Klik tombol **Masuk** (pagi) atau **Pulang** (sore)
3. Ikuti tantangan liveness (kedip mata, putar kepala)
4. Tunggu konfirmasi keberhasilan

### Offline Mode
- Jika tidak ada jaringan, absen akan tersimpan otomatis
- Data akan sync saat kembali online

### Pengajuan Cuti/Sakit/Izin/Dinas
1. Buka menu **Pengajuan**
2. Klik **+** untuk membuat pengajuan baru
3. Pilih jenis, tanggal, dan alasan
4. Kirim pengajuan
5. Tunggu persetujuan dari manager

## Troubleshooting

### Kamera tidak berfungsi
- Pastikan izin kamera sudah diberikan
- Restart aplikasi dan coba lagi

### Verifikasi wajah gagal
- Pastikan wajah jelas terlihat di dalam bingkai
- Pastikan pencahayaan cukup
- Pastikan tidak ada kacamata atau penutup muka lainnya

### Lokasi tidak terdeteksi
- Pastikan GPS sudah aktif
- Aktifkan **Layanan Lokasi** di Pengaturan
- Keluar dan buka aplikasi kembali

### Absen offline tidak sync
- Pastikan koneksi internet tersedia
- Buka aplikasi dan pull-to-refresh pada halaman utama
- Jika masih gagal, hubungi admin

## Keamanan

### Device Binding
- Setiap akun hanya bisa login di 1 device utama
- Device cadangan tersedia maksimal 1, membutuhkan approval manager

### Data Biometrik
- Template wajah disimpan terenkripsi di server
- Foto wajah hanya disimpan 30 hari
- Data wajah tidak pernah disimpan sebagai foto permanen di device

## Kontak Dukungan
- Email: admin@bumnisakap.com
- Telpon: (000) 1234-5678 (HR Department)