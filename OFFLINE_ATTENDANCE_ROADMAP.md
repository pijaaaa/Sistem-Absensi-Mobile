# Offline Attendance Roadmap (Absen Offline + Auto Sync)

> Scope: absen masuk/pulang saat tidak ada jaringan, tersimpan di HP, dikirim otomatis saat jaringan kembali.
> Sistem absensi **PT Bumi Siak Pusako** — mobile Flutter + backend Laravel 13.
> Dokumen ini merinci milestone **F4** di `ROADMAP.md` (sisi aplikasi) dan memakai kontrak API **B7**.
> Panduan pengguna ada di `PANDUAN_ABSEN_OFFLINE.md`.

---

## 1. Prasyarat

| Prasyarat | Status yang dibutuhkan |
|---|---|
| B7 — API sync offline (batch, `client_uuid`, endpoint waktu server, hitung ulang waktu, `time_trust`, `review_flag`) | Selesai dan terdokumentasi |
| F2 — Enrollment & liveness, template wajah tersimpan terenkripsi di HP | Selesai |
| F3 — Absen online (GPS, blok mock location, wajah, check-in/out) | Selesai. Alur ini dipakai ulang, bukan ditulis ulang |
| F5 — Device utama/cadangan | Sebaiknya selesai (item antrian membawa `device_uid`) |
| Design system (U0) dan aturan UI/UX (`ROADMAP.md` bagian 6.0) | Dipakai di semua layar |

Tidak ada perubahan backend di roadmap ini. Jika kontrak B7 kurang dari kebutuhan, catat selisihnya dan putuskan bersama sebelum lanjut.

---

## 2. Keputusan Desain

| Area | Keputusan |
|---|---|
| Sumber waktu | **Tidak memakai jam sistem HP.** Waktu absen = patokan server + selisih `elapsedRealtime`. Dihitung final oleh server |
| Patokan waktu (anchor) | Pasangan `(serverTime, elapsedRealtime, bootCount)` diambil dari endpoint waktu server saat online: setelah login, saat aplikasi dibuka online, dan setelah tiap sync sukses |
| Restart HP | `bootCount` berubah sejak anchor → server menandai `time_trust = suspect`, absen masuk antrean review. Aplikasi tidak menolak sendiri dan tidak menampilkan istilah teknis |
| Tanpa anchor | Absen offline **tidak diizinkan**. Pesan: hubungkan internet minimal sekali sebelum memakai absen offline |
| Hasil di layar | "Tersimpan offline, menunggu sinkron" + jam perkiraan. Status tepat waktu/terlambat final hanya dari server setelah sync |
| Validasi lokal | GPS, blok mock location, liveness, cocok wajah lokal, geofence (data lokasi di-cache), cegah absen ganda. Server tetap memeriksa ulang semuanya |
| Penyimpanan antrian | drift/SQLite. Foto crop terenkripsi di penyimpanan privat aplikasi, kunci di `flutter_secure_storage`, dihapus segera setelah `synced` |
| Idempotensi | `client_uuid` (UUID v4) per absen. Kirim ulang aman, tidak membuat data ganda |
| Pemicu sync | Konektivitas kembali, aplikasi dibuka/resume, setelah absen bila online, workmanager periodik (cadangan saat aplikasi tertutup), tombol manual |
| Kegagalan | Backoff eksponensial (30 dtk → 1 → 2 → 5 → maks 15 menit). Hanya error jaringan/5xx yang di-retry otomatis. 401 → alur logout yang ada. 403/422 level request → error jelas, bukan loop |
| Logout dengan antrian | Dialog konfirmasi berisi jumlah item. Antrian tidak dihapus. Hanya akun pemilik item yang bisa menyinkronkannya |
| Penanda "Perlu review" | Bahasa netral, tidak menuduh karyawan. Alasan teknis tidak ditampilkan |
| Push hasil sync | Tidak dibuat di roadmap ini. Ada di `PUSH_NOTIFICATION_ROADMAP.md` Fase 2 (#15) |

---

## 3. Rumus Waktu

```
waktu_absen (dihitung server) = anchor_server + (elapsed_saat_absen - elapsed_anchor)

Tampilan di HP (hanya perkiraan) = anchor_server + (elapsed_sekarang - elapsed_anchor)
```

Jika `boot_count_saat_absen != boot_count_anchor` → `time_trust = suspect` → `review_flag`.

---

## 4. Model Data Antrian Lokal

| Kolom | Keterangan |
|---|---|
| `client_uuid` | UUID v4, dibuat saat absen |
| `employee_id` | Pemilik item |
| `type` | masuk / pulang |
| `lat`, `lng` | Koordinat saat absen |
| `face_score_local` | Skor cocok wajah di HP |
| `photo_path` | Path foto crop terenkripsi (dihapus setelah `synced`) |
| `device_uid` | Identitas device |
| `elapsed_realtime` | Dari native saat absen |
| `boot_count` | Dari native saat absen |
| `anchor_server_time`, `anchor_elapsed`, `anchor_boot_count` | Salinan anchor yang dipakai |
| `status` | `pending` / `syncing` / `synced` / `rejected` / `needs_review` |
| `attempts`, `last_error` | Untuk retry dan tampilan |
| `server_message` | Alasan dari server (untuk `rejected`) |
| `created_at`, `synced_at` | Untuk pengurutan dan pembersihan |

Template wajah dan data biometrik lain **tidak** disimpan di tabel ini.

### Status item

| Status | Arti | Tampilan ke karyawan |
|---|---|---|
| `pending` | Menunggu dikirim | Menunggu sinkron |
| `syncing` | Sedang dikirim (dikembalikan ke `pending` bila aplikasi mati saat mengirim) | Menyinkronkan… |
| `synced` | Diterima server (termasuk respons duplikat) | Tersinkron |
| `needs_review` | Diterima, ditandai perlu review | Perlu review |
| `rejected` | Ditolak validasi server | Ditolak + alasan ramah |

---

## 5. Fase Pengerjaan

| Fase | Isi | Selesai kalau |
|---|---|---|
| **O0** | Audit kode dan kontrak B7 | Ringkasan temuan disetujui, tidak ada kode diubah |
| **O1** | Fondasi waktu: native `elapsedRealtime` + `bootCount`, anchor | Anchor tersimpan dan terbarui; jam perkiraan benar saat jam HP diubah |
| **O2** | Antrian lokal + absen offline | Absen offline tersimpan dengan semua validasi lokal, layar hasil varian offline |
| **O3** | Mesin sinkron | Antrian terkirim otomatis dengan semua pemicu, retry, dan pemetaan status |
| **O4** | UI/UX | Badge, riwayat, daftar antrian, dialog logout, semua state lengkap |
| **O5** | Hardening & uji | Semua skenario di bagian 7 lolos di HP asli, termasuk HP lama |

Satu fase per sesi agent, test manual dulu sebelum lanjut. **O0, O1** dan **O3** adalah titik berhenti untuk review.

---

## 6. Prompt untuk AI Agent

> Tambahkan di awal setiap sesi: *"Project absensi PT Bumi Siak Pusako: mobile Flutter di folder mobile, backend Laravel 13 di folder backend. Baca ROADMAP.md bagian 0 dan 6.0, serta OFFLINE_ATTENDANCE_ROADMAP.md bagian 2–4 sebagai acuan keputusan. Jangan mengubah backend. Kode harus sederhana dan natural, tanpa abstraksi berlebihan. Kerjakan fase yang diminta saja."*

### O0 — Audit (titik berhenti)

```
Fase O0 absen offline. JANGAN ubah kode, hanya baca dan laporkan.

1. Backend: baca dokumentasi API/kode untuk endpoint sync batch dan endpoint waktu server
   (B7). Catat persis: format request (field per item, format waktu, cara upload foto),
   format respons per item (sukses, duplikat, ditolak + alasan, perlu review), kode error,
   batas ukuran batch dan foto, dan apakah item boleh dikirim urut dalam satu batch
   (masuk lalu pulang).
2. Mobile: baca kode absen online (F3): alur GPS, liveness + cocok wajah lokal, pemanggilan
   check-in/check-out, layar hasil, penyimpanan data lokasi kerja/jadwal/template wajah,
   alur token/logout, dan konfigurasi go_router. Catat bagian yang akan dipakai ulang dan
   bagian yang akan disentuh.
3. Cek: apakah data lokasi kerja (mode point/polygon/off, koordinat, radius) dan informasi
   dinas sudah di-cache di HP untuk geofence lokal? Jika belum, catat apa yang perlu ditambah.
4. Daftar pertanyaan atau ketidaksesuaian antara kontrak B7 dan keputusan di
   OFFLINE_ATTENDANCE_ROADMAP.md bagian 2–3.
Laporkan dalam ringkasan singkat. BERHENTI dan tunjukkan ke saya sebelum lanjut.
```

### O1 — Fondasi Waktu (titik berhenti)

```
Fase O1 absen offline. Bangun fondasi waktu, belum ada antrian dan belum ada UI baru.

1. MethodChannel native Android (Kotlin, sederhana) yang mengembalikan
   SystemClock.elapsedRealtime() dan boot count (Settings.Global "boot_count"). Tangani
   kasus boot count tidak tersedia (kembalikan null dan jelaskan perilaku yang dipilih).
2. Service TimeAnchor di Dart:
   - ambil waktu dari endpoint waktu server (B7), simpan (serverTime, elapsedRealtime,
     bootCount) di penyimpanan lokal (secure storage atau shared_preferences yang sudah
     dipakai project)
   - method untuk memperbarui anchor: dipanggil setelah login, saat aplikasi dibuka dalam
     keadaan online, dan setelah sync sukses (dipasang di fase O3)
   - method untuk menghitung waktu perkiraan sekarang: anchor + (elapsed sekarang - elapsed
     anchor)
   - method hasAnchor dan isAnchorUsable (bootCount saat ini sama dengan anchor atau
     tidak). Jika boot count berubah, anchor tetap bisa dipakai untuk menyimpan absen
     (server yang menandai suspect), tetapi sediakan informasinya
3. Pemakaian jam sistem (DateTime.now) tidak boleh dipakai untuk menentukan waktu absen
   offline. Cari pemakaian yang ada dan catat.
4. Tes unit untuk perhitungan waktu perkiraan (termasuk bila jam sistem diubah) dan untuk
   penentuan anchor usable.
5. Halaman debug sementara (hanya mode debug) yang menampilkan: anchor, elapsed sekarang,
   boot count, waktu perkiraan, dan jam sistem, agar mudah diverifikasi manual.
BERHENTI setelah halaman debug jadi, tunjukkan ke saya. Beri tahu cara mengujinya (ubah
jam HP, mode pesawat, restart HP).
```

### O2 — Antrian Lokal & Absen Offline

```
Fase O2 absen offline. O0 dan O1 sudah disetujui. Bangun antrian lokal dan alur absen offline.

ANTRIAN (drift/SQLite)
- Tabel sesuai model data di OFFLINE_ATTENDANCE_ROADMAP.md bagian 4. Status awal 'pending'.
- Foto crop wajah disimpan terenkripsi di penyimpanan privat aplikasi, kunci di
  flutter_secure_storage. Template wajah tidak masuk tabel.
- Cegah absen ganda secara lokal: maksimal satu masuk dan satu pulang per karyawan per hari
  (gabungkan antrian + status hari ini yang tersimpan). Pulang tidak boleh sebelum masuk.
- Item terikat employee_id pemilik akun.

ALUR ABSEN OFFLINE (pakai ulang alur F3, jangan tulis ulang)
- Saat tidak ada koneksi, alur tetap berjalan: GPS, blok mock location, liveness, cocok
  wajah lokal.
- Geofence dicek lokal dengan data lokasi kerja yang di-cache (point/polygon/off). Di luar
  area ditolak seperti online. Jika data lokasi belum ada di cache, tambahkan penyimpanannya
  (diisi saat online) dan jelaskan perubahannya.
- Tanpa anchor (hasAnchor false): tolak dengan pesan ramah "Hubungkan internet minimal
  sekali sebelum memakai absen offline".
- Saat sukses: buat client_uuid, ambil elapsedRealtime + bootCount, salin anchor yang
  dipakai, simpan foto terenkripsi, tulis item ke antrian dengan status pending.
- Layar hasil varian offline (komponen design system): "Tersimpan offline, menunggu
  sinkron", jam perkiraan berlabel "waktu perkiraan", lokasi, penjelasan singkat bahwa data
  dikirim otomatis. Haptic ringan. JANGAN menampilkan status tepat waktu/terlambat final.
- Jika saat absen ternyata koneksi ada, tetap pakai alur online F3 (bukan antrian).

KETENTUAN
- Ubah seminimal mungkin pada kode absen online. Dependensi baru: drift dan paket enkripsi
  sederhana; jelaskan alasannya sebelum menambah yang lain.

UJI
- Mode pesawat -> absen masuk -> item pending tersimpan, foto terenkripsi ada.
- Absen masuk kedua kali ditolak lokal; pulang sebelum masuk ditolak.
- Di luar area ditolak; mock location tetap memblokir.
- Tanpa anchor ditolak dengan pesan benar.
- Ubah jam HP lalu absen offline: elapsedRealtime dan anchor tetap benar.
Beri tahu saya apa yang perlu saya cek manual di HP.
```

### O3 — Mesin Sinkron (titik berhenti)

```
Fase O3 absen offline. O2 sudah selesai dan lolos uji. Bangun mesin sinkron sesuai kontrak
B7 yang dicatat di O0.

PEMICU
- connectivity_plus: jaringan kembali. Aplikasi dibuka/resume. Setelah absen bila online.
- workmanager periodik (constraint network connected) sebagai cadangan saat aplikasi
  tertutup.
- Method syncNow() untuk tombol manual dan pull-to-refresh.

PROSES
- Satu sync pada satu waktu (mutex) agar pemicu bersamaan tidak mengirim dobel. Saat
  aplikasi mulai, item berstatus syncing dikembalikan ke pending.
- Ambil item pending milik akun yang sedang login, urut created_at, kirim dalam batch sesuai
  kontrak B7. Ubah status menjadi syncing saat mengirim.
- Respons per item: sukses atau duplikat -> synced; ditandai review -> needs_review;
  ditolak validasi -> rejected + simpan alasan dari server. Pemetaan persis mengikuti
  kontrak B7.
- Error jaringan/timeout/5xx: tetap pending, attempts +1, retry dengan backoff (30 dtk, 1,
  2, 5 menit, maksimal 15 menit). 401: ikuti alur logout yang sudah ada tanpa menghapus
  antrian. 403/422 pada level request: simpan error yang jelas, jangan retry otomatis.
- Setelah sukses: perbarui anchor (TimeAnchor dari O1), hapus foto lokal item synced,
  segarkan data Home/Riwayat, simpan jejak item synced 7 hari lalu bersihkan.
- Alur ini tidak boleh membuat login/logout atau memicu loop pada redirect go_router.

UJI (laporkan satu per satu)
1. Absen offline -> nyalakan jaringan -> terkirim otomatis, tanpa data ganda.
2. Aplikasi ditutup total, jaringan kembali: terkirim lewat workmanager atau saat aplikasi
   dibuka.
3. Kirim ulang item yang sama (simulasi): tetap satu data di server.
4. Batch campuran (sebagian sukses, sebagian ditolak): status per item benar.
5. Server mati/timeout: tetap pending, retry dengan backoff, baterai tidak terkuras.
6. Aplikasi dimatikan paksa saat syncing: setelah dibuka, item kembali pending dan terkirim.
7. Dua pemicu bersamaan: hanya satu proses sync berjalan.
8. HP restart saat offline lalu absen: server menandai perlu review, status di aplikasi
   needs_review.
BERHENTI dan tunjukkan hasilnya ke saya, termasuk log ringkas tiap skenario.
```

### O4 — UI/UX

```
Fase O4 absen offline. O3 sudah disetujui. Bangun tampilan, ikuti ROADMAP.md bagian 6.0 dan
komponen design system (jangan hardcode warna/ukuran).

- Badge koneksi di Home: Online / Offline / "n menunggu sync". Ketuk membuka daftar antrian.
- Riwayat: item antrian tampil bersama data server dengan StatusChip: Tersimpan offline,
  Menunggu sinkron, Tersinkron, Perlu review (netral, tidak menuduh), Ditolak (alasan
  ramah). Pull-to-refresh memicu syncNow().
- Layar daftar antrian: item, jenis, jam perkiraan, status, jumlah percobaan yang ramah,
  tombol "Coba lagi" untuk yang gagal, tombol "Sinkronkan sekarang". Hanya item akun
  yang login.
- Dialog saat logout bila masih ada item pending/syncing: sebutkan jumlahnya, tawarkan
  "Sinkronkan dulu" dan "Tetap keluar". Antrian tidak dihapus apa pun pilihannya.
- Pesan ramah berbahasa Indonesia untuk setiap status dan error. Jangan menampilkan istilah
  teknis (time_trust, boot count, anchor).
- Semua state: loading (skeleton), kosong, error, sukses. Uji di HP kecil/tablet, terang/
  gelap, font scale 1.3x.
Beri tahu saya apa yang perlu saya cek manual.
```

### O5 — Hardening & Uji

```
Fase O5 absen offline. Tahap akhir.

1. Jalankan seluruh checklist di OFFLINE_ATTENDANCE_ROADMAP.md bagian 7 dan laporkan hasil
   satu per satu. Perbaiki yang gagal dengan perubahan seminimal mungkin.
2. Uji di HP spek rendah (Android 7, RAM 2GB): waktu buka kamera, ukuran database, dan
   penggunaan baterai saat retry.
3. Uji penghemat baterai agresif (Xiaomi/Oppo/Vivo bila tersedia): catat perilaku
   workmanager dan tambahkan petunjuk ramah di aplikasi bila sync latar belakang tertunda.
4. Uji data: antrian besar (mis. 50 item), foto besar, penyimpanan penuh (tangani dengan
   pesan jelas, jangan crash).
5. Review keamanan: foto terenkripsi, kunci di secure storage, tidak ada data biometrik
   di log, antrian tidak bisa dikirim akun lain.
6. Pastikan tidak ada pemakaian jam sistem untuk waktu absen offline dan tidak ada log
   debug tersisa; hapus halaman debug dari O1.
Beri ringkasan: apa yang lolos, apa yang masih berisiko.
```

---

## 7. Checklist Uji Manual

1. Online → mode pesawat → absen masuk → "Tersimpan offline" → matikan mode pesawat → tersinkron otomatis tanpa data ganda.
2. Absen offline, tutup aplikasi total, nyalakan internet → terkirim (saat aplikasi tertutup atau begitu dibuka).
3. Ubah jam sistem HP (maju/mundur) saat offline lalu absen → waktu di server tetap benar.
4. Restart HP saat offline lalu absen → tersimpan, ditandai "Perlu review", tidak ditolak.
5. Kirim ulang item yang sama → tidak ada data ganda.
6. Batch campuran (sebagian di luar area) → status per item benar dengan alasan ramah.
7. Server mati saat sync → tetap pending, retry dengan jeda makin lama.
8. Belum pernah online (tanpa anchor) → absen offline ditolak dengan pesan jelas.
9. Logout dengan antrian → ada dialog konfirmasi, antrian tidak hilang; login akun lain tidak mengirim antrian akun pertama.
10. Absen masuk dua kali offline → ditolak lokal.
11. Pulang offline tanpa masuk → ditolak lokal.
12. Mock location aktif saat offline → tombol absen terkunci.
13. Di luar area kerja saat offline → ditolak seperti online.
14. Foto crop lokal terhapus setelah item `synced`.
15. Layar antrian, riwayat, dan badge benar di HP kecil, tablet, terang/gelap, font 1.3x.

---

## 8. Risiko & Catatan

| Risiko | Mitigasi |
|---|---|
| Penghemat baterai HP menunda workmanager | Sync juga dipicu saat aplikasi dibuka dan lewat tombol manual; beri petunjuk ramah di O5 |
| Boot count tidak tersedia di sebagian HP | Tentukan perilaku di O1 (mis. dianggap tidak dapat diverifikasi) dan sepakati dengan server lewat `time_trust` |
| Foto/antrian menumpuk di penyimpanan | Hapus foto setelah `synced`, bersihkan jejak `synced` setelah 7 hari, tangani penyimpanan penuh |
| Pemicu sync bersamaan menimbulkan kiriman dobel | Mutex di aplikasi + idempotensi `client_uuid` di server |
| Loop pada alur login/redirect akibat 401 saat sync | 401 hanya memicu alur logout yang sudah ada; sync tidak memanggil navigasi |
| Karyawan salah paham soal "Perlu review" | Bahasa netral di aplikasi, jelaskan di panduan pengguna |

Catatan kerja:
- Satu fase per sesi agent; uji manual dulu sebelum lanjut.
- Uji di HP asli, bukan hanya emulator, karena waktu dan baterai berperilaku berbeda.
- Jangan mengubah backend; jika kontrak B7 kurang, catat selisihnya dan putuskan bersama.
- Panduan karyawan: `PANDUAN_ABSEN_OFFLINE.md`. Notifikasi hasil sync: `PUSH_NOTIFICATION_ROADMAP.md` (#15).
