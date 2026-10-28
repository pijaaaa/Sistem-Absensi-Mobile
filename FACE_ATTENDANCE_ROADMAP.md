# Face Attendance Roadmap (Akurasi Wajah + Liveness Toleh)

> Scope: memperbaiki akurasi pengenalan wajah dan menambah liveness interaktif (toleh kanan/kiri) untuk pendaftaran dan absen.
> Sistem absensi **PT Bumi Siak Pusako** — mobile Flutter + face-service Python (OpenCV) + backend Laravel 13.
> Melengkapi milestone **F1, F2, F3** dan **B5, B6, B7** di `ROADMAP.md`. Absen offline: `OFFLINE_ATTENDANCE_ROADMAP.md`.

---

## 1. Masalah yang Dihadapi

Wajah teman bisa lolos absen memakai akun orang lain (**false accept**). Artinya pengenalan wajah saat ini tidak benar-benar membedakan orang. Target roadmap ini:

1. Wajah orang lain **ditolak** secara konsisten di akun yang bukan miliknya.
2. Pemilik akun **tetap lolos** dengan wajar (cahaya biasa, berkacamata, berhijab, dll.).
3. Pendaftaran dan absen **wajib liveness interaktif** (toleh kanan/kiri) sehingga foto statis tidak cukup.
4. Keputusan akhir ada di **server**, bukan di HP.

### Dugaan penyebab (diverifikasi di fase W0, jangan ditebak)

| # | Dugaan | Cara memeriksa |
|---|---|---|
| 1 | Skor dari HP dipercaya begitu saja, server tidak menolak bila tidak cocok (B6/B7 awalnya hanya "simpan skor", tidak memutuskan) | Baca kode check-in: apakah ada penolakan saat `face_score_server` rendah? |
| 2 | Ambang (threshold) terlalu longgar, atau tidak pernah dipakai untuk memutuskan | Lihat nilai ambang dan di mana dibandingkan |
| 3 | Pembanding tidak membandingkan dengan template milik karyawan yang login (mis. salah `employee_id`, atau membandingkan dengan template terbaru siapa pun) | Telusuri query template |
| 4 | Pra-pemrosesan di HP dan di server berbeda (alignment 5 titik, ukuran 112×112, normalisasi), sehingga skor tidak bermakna | Bandingkan alur `alignCrop` → `feature` di kedua sisi |
| 5 | Embedding tidak dinormalisasi atau salah metrik (cosine vs L2) saat membandingkan | Periksa rumus kemiripan dan arah ambangnya |
| 6 | Template hanya 1 sampel frontal berkualitas rendah | Periksa jumlah dan kualitas sampel enrollment |
| 7 | Liveness tidak mengunci identitas: wajah berbeda bisa muncul di tengah tantangan | Periksa apakah embedding diambil dari frame yang sama dengan frame verifikasi |
| 8 | Kualitas gambar tidak disaring (blur, gelap, wajah kecil), sehingga skor tidak stabil | Periksa gerbang kualitas |

---

## 2. Keputusan Desain

| Area | Keputusan |
|---|---|
| Library | **OpenCV**: YuNet (deteksi + 5 landmark) dan **SFace** (pengenal). Model dan pra-pemrosesan di HP **identik** dengan server (satu `model_version`). Jangan memakai Google ML Kit |
| Pra-pemrosesan | Deteksi YuNet → `alignCrop` 5 landmark → `feature` SFace → **normalisasi L2** → kemiripan **cosine**. Alur yang sama di HP dan server |
| Otoritas keputusan | **Server memutuskan.** Skor dari HP hanya untuk gerbang awal (UX) dan absen offline. Skor dari client tidak dipercaya sebagai bukti |
| Template wajah | Beberapa embedding per karyawan dengan label pose (`front`, `left`, `right`), masing-masing dengan skor kualitas. Skor kecocokan = nilai tertinggi (atau rata-rata 2 tertinggi) terhadap template. Hanya embedding yang disimpan (tanpa foto permanen) |
| Ambang (threshold) | **Dikalibrasi dari data tim sendiri** (fase W1), bukan angka tebakan. Titik awal: ambang cosine bawaan SFace di dokumentasi OpenCV Zoo (sekitar 0,363), lalu diperketat sesuai hasil FAR/FRR. Disimpan di settings, bisa diubah superadmin tanpa rilis ulang |
| Dua zona keputusan | `skor ≥ T_pass` → lolos. `T_review ≤ skor < T_pass` → online: minta ulang; offline/sync: lolos dengan `review_flag`. `skor < T_review` → ditolak |
| Gerbang kualitas | Satu wajah, ukuran cukup, tajam (tidak blur), pencahayaan wajar, pose menghadap depan saat mencocokkan. Frame yang tidak lolos tidak dipakai |
| Liveness | Tantangan interaktif acak: **toleh kiri/kanan** (urutan diacak, wajib kembali menghadap depan). Berlaku di **pendaftaran dan absen** |
| Pengukuran toleh | Rasio posisi hidung terhadap titik tengah kedua mata (dari 5 landmark YuNet) dibagi jarak antar mata. Ambang diuji di HP asli |
| Kunci identitas | Embedding frontal sebelum, selama, dan sesudah tantangan harus konsisten (orang yang sama). Pergantian wajah di tengah tantangan = gagal |
| Frame untuk pencocokan | Hanya frame menghadap depan berkualitas baik. Frame saat menoleh tidak dipakai untuk pencocokan di absen (di pendaftaran dipakai sebagai sampel pose) |
| Batas percobaan | Maksimal 3 kali gagal berturut-turut, lalu jeda (mis. 5 menit) dan pesan hubungi admin. Semua percobaan dicatat |
| Deteksi wajah ganda | Saat pendaftaran, embedding baru dibandingkan dengan template karyawan lain; jika sangat mirip, pendaftaran ditahan dan dicatat |
| Daftar ulang wajah | Usulan: setelah terdaftar, daftar ulang/hapus template hanya lewat **superadmin** (tercatat di audit log). Konfirmasi keputusan ini sebelum W4 |
| Absen offline | Tetap sesuai keputusan awal: tersimpan lalu diverifikasi ulang saat sync; tidak cocok → `review_flag`, tidak ditolak otomatis (admin menandai valid/tidak valid) |
| Privasi | Data biometrik: simpan embedding saja secara permanen, persetujuan karyawan (layar F2), foto crop absen 30 hari lalu hapus otomatis, tidak ada data biometrik di log |

### Batas kemampuan yang perlu diketahui

Toleh kanan/kiri efektif menggagalkan **foto cetak atau foto di layar**. Ia **tidak menjamin** menghentikan video rekaman yang menirukan tolehan atau topeng 3D. Pertahanan berlapis yang dipakai: verifikasi ulang di server, foto crop untuk review admin, device binding, batas percobaan, dan (opsional, W6) model anti-spoof pasif. Jangan mengklaim "tidak bisa dipalsukan".

---

## 3. Alur Target

### Pendaftaran wajah (sekali, wajib sebelum bisa absen)

```
Layar persetujuan data biometrik
   -> Posisikan wajah (gerbang kualitas)
   -> Tantangan acak: toleh kiri / toleh kanan (urutan diacak, kembali ke depan)
   -> Ambil sampel: depan (beberapa frame terbaik), kiri, kanan
   -> Cek konsistensi antar sampel (harus orang yang sama)
   -> Kirim ke server (embedding + gambar sampel untuk dihitung ulang server)
   -> Server menghitung ulang, cek duplikat dengan karyawan lain, simpan template
   -> HP mengunduh template milik sendiri (terenkripsi)
```

### Absen (online)

```
Tekan Masuk/Pulang -> cek lokasi
   -> Gerbang kualitas -> Tantangan acak (toleh) -> kembali menghadap depan
   -> Ambil beberapa frame depan terbaik -> cocok lokal (gerbang UX)
   -> Kirim gambar crop ke server -> server menghitung ulang + memutuskan
   -> Lolos / minta ulang / ditolak (ada hitungan percobaan)
```

### Absen (offline)

Sama seperti online sampai pencocokan lokal. Hasil disimpan ke antrian; server memutuskan saat sync (lihat `OFFLINE_ATTENDANCE_ROADMAP.md`).

---

## 4. Perubahan Data

| Tabel | Perubahan |
|---|---|
| `face_templates` | Dari satu baris per karyawan menjadi beberapa baris: tambah `pose` (`front`/`left`/`right`), `quality_score`. Embedding tetap terenkripsi, `model_version` tetap |
| `face_attempts` (baru) | `id`, `employee_id`, `context` (`enroll`/`checkin`/`checkout`/`sync`), `score`, `decision` (`pass`/`retry`/`reject`/`review`), `reason`, `liveness_ok`, `quality_ok`, `created_at`. Tanpa foto dan tanpa embedding |
| `settings` | `face_threshold_pass`, `face_threshold_review`, `face_max_attempts`, `face_lockout_minutes`, `face_min_face_size`, `face_min_sharpness` |

Perubahan skema lewat migration; template lama (1 sampel) tetap dibaca, tetapi karyawan diminta daftar ulang bila kualitasnya rendah (kebijakan daftar ulang mengikuti keputusan di atas).

---

## 5. Fase Pengerjaan

| Fase | Isi | Selesai kalau |
|---|---|---|
| **W0** | Audit dan diagnosa: temukan penyebab pasti wajah orang lain lolos | Penyebab dibuktikan dengan data/log, laporan disetujui. **Titik berhenti** |
| **W1** | Alat uji dan kalibrasi: kumpulkan pasangan sama/beda, hitung distribusi skor, tentukan ambang | Tabel FAR/FRR dan ambang yang direkomendasikan, disetujui. **Titik berhenti** |
| **W2** | Face-service dan API server: keputusan di server, multi-template, kualitas, duplikat, batas percobaan | Server menolak wajah yang bukan pemilik; uji otomatis lulus |
| **W3** | Mesin liveness di HP: toleh kiri/kanan, kunci identitas, gerbang kualitas | Foto statis gagal, toleh asli lolos; arah toleh benar di HP asli. **Titik berhenti** |
| **W4** | Alur pendaftaran wajah baru | Template multi-pose terdaftar dengan liveness dan cek konsistensi |
| **W5** | Alur absen dengan liveness dan keputusan server (online + jalur offline) | Absen memakai liveness dan keputusan server di semua kondisi |
| **W6** | Hardening dan uji spoof: foto, layar, teman, kondisi sulit, HP lama | Checklist bagian 7 lolos, risiko tersisa terdokumentasi |

Satu fase per sesi agent, test manual dulu sebelum lanjut.

---

## 6. Prompt untuk AI Agent

> Tambahkan di awal setiap sesi: *"Project absensi PT Bumi Siak Pusako: backend Laravel 13 (folder backend), face-service Python OpenCV (folder face-service), mobile Flutter (folder mobile). Baca ROADMAP.md bagian 0 dan 6.0, serta FACE_ATTENDANCE_ROADMAP.md bagian 1–4 sebagai acuan keputusan. Keputusan akhir pengenalan wajah ada di server. Kode harus sederhana dan natural, tanpa abstraksi berlebihan. Kerjakan fase yang diminta saja."*

### W0 — Audit & Diagnosa (titik berhenti)

```
Fase W0 absen wajah. JANGAN memperbaiki apa pun dulu. Tugas: buktikan kenapa wajah teman bisa
lolos absen di akun saya.

1. Telusuri alur lengkap, dari HP sampai server:
   - HP: deteksi wajah, alignment, ekstraksi embedding (library/model/versi, ukuran input,
     normalisasi), cara membandingkan dengan template lokal (metrik, ambang), apa yang
     dikirim ke server (gambar? embedding? skor?).
   - Server (face-service dan Laravel): endpoint /embed dan /verify, cara menghitung
     kemiripan (cosine/L2, normalisasi, arah ambang), template mana yang dibandingkan
     (pastikan untuk employee_id akun yang login), nilai ambang dan di mana dipakai, dan
     APAKAH hasil verifikasi benar-benar menolak absen atau hanya disimpan sebagai skor.
   - Liveness yang ada sekarang (jika ada): apa yang diperiksa.
2. Bandingkan pra-pemrosesan HP vs server (model_version, alignCrop 5 titik, 112x112,
   normalisasi L2). Catat setiap perbedaan.
3. Tambahkan log diagnostik sementara (tanpa menyimpan foto/embedding di log): skor, ambang,
   keputusan, employee_id yang dibandingkan, jumlah template, sumber skor (HP atau server).
4. Jalankan skenario: (a) saya absen, (b) teman saya absen di akun saya. Tunjukkan log kedua
   skenario berdampingan.
5. Laporan: penyebab pasti (atau penyebab-penyebab) dengan bukti dari log/kode, urut dari yang
   paling berkontribusi. Gunakan daftar dugaan di FACE_ATTENDANCE_ROADMAP.md bagian 1 sebagai
   titik awal, tetapi hanya laporkan yang terbukti.
BERHENTI dan tunjukkan laporan ke saya. Jangan ubah perilaku aplikasi.
```

### W1 — Alat Uji & Kalibrasi Ambang (titik berhenti)

```
Fase W1 absen wajah. W0 sudah disetujui. Tujuan: menentukan ambang berdasarkan data, bukan
tebakan.

1. Skrip uji Python di folder face-service/tools (berdiri sendiri, memakai pipeline yang SAMA
   dengan produksi: YuNet -> alignCrop -> SFace -> L2 normalize -> cosine):
   - Input: folder per orang (face-service/tools/dataset/<nama>/*.jpg). Folder dataset masuk
     .gitignore dan tidak boleh ikut commit (data biometrik).
   - Hitung skor semua pasangan sama-orang (genuine) dan beda-orang (impostor).
   - Keluaran: ringkasan statistik (min/rata-rata/maks per kelompok), tabel FAR dan FRR untuk
     beberapa ambang (mis. 0,30 sampai 0,70 per langkah 0,02), ambang yang merekomendasikan
     FAR sangat rendah dengan FRR yang masih wajar, dan grafik histogram skor (file PNG).
2. Jelaskan cara saya menyiapkan dataset: berapa orang dan foto minimum (mis. ≥ 8 orang,
   ≥ 10 foto per orang dengan variasi cahaya, jarak, kacamata/hijab/masker bila relevan,
   plus pasangan "teman mirip"/kerabat bila ada), dan peringatan persetujuan: hanya foto
   orang yang setuju.
3. Pastikan skrip bisa menguji pra-pemrosesan HP vs server: sediakan mode yang membandingkan
   embedding dari gambar yang sama lewat dua jalur dan melaporkan selisihnya.
4. Beri rekomendasi T_pass dan T_review beserta alasannya dari tabel FAR/FRR, dan jelaskan
   konsekuensi pilihan (lebih ketat = lebih aman tapi lebih sering minta ulang).
BERHENTI dan tunjukkan hasilnya. Ambang final saya putuskan setelah melihat tabelnya.
```

### W2 — Face-Service & API Server

```
Fase W2 absen wajah. W1 sudah selesai dan ambang disetujui. Jadikan server pemutus akhir.

FACE-SERVICE
- Endpoint analisis gambar yang mengembalikan: jumlah wajah, bounding box, 5 landmark,
  metrik kualitas (ukuran wajah, ketajaman/blur, kecerahan), embedding ternormalisasi L2, dan
  model_version. Tolak: tanpa wajah, lebih dari satu wajah, kualitas di bawah ambang.
- Pra-pemrosesan identik dengan yang dipakai skrip W1. Tetap dilindungi shared secret.

LARAVEL
1. Skema (migration): face_templates multi-baris (pose, quality_score), tabel face_attempts,
   dan settings ambang (nilai default dari W1). Template lama tetap terbaca.
2. Enrollment: terima sampel (depan, kiri, kanan), hitung ulang embedding di server (jangan
   percaya embedding dari HP), cek konsistensi antar sampel (kemiripan antar sampel harus
   di atas batas), cek duplikat terhadap template karyawan lain (sangat mirip -> tahan dan
   catat, jangan simpan), simpan embedding terenkripsi per pose. Tidak menyimpan foto
   permanen.
3. Verifikasi absen: ambil gambar crop dari HP, hitung embedding di server, bandingkan HANYA
   dengan template employee_id akun yang login. Skor = nilai tertinggi (atau rata-rata dua
   tertinggi, pilih yang terbukti lebih stabil di data W1).
   - skor >= T_pass: lolos
   - T_review <= skor < T_pass: online -> respons "coba lagi"; sync offline -> lolos dengan
     review_flag
   - skor < T_review: ditolak
   Check-in/check-out memakai hasil ini; skor dari client hanya disimpan sebagai
   face_score_local dan tidak ikut memutuskan.
4. Batas percobaan: hitung gagal berturut-turut per karyawan (face_attempts). Setelah
   face_max_attempts, kunci sementara selama face_lockout_minutes dan kembalikan pesan jelas.
   Setiap percobaan dicatat (tanpa foto/embedding).
5. Jalur sync offline (B7): verifikasi ulang memakai aturan keputusan yang sama; tidak cocok
   -> review_flag (tidak menolak otomatis, sesuai keputusan awal).
6. Pengaturan ambang dan batas di web superadmin (izin settings.*, audit log, cache
   di-invalidate saat diubah).
7. Daftar ulang/hapus template hanya untuk superadmin (izin dan audit log). Jangan buka
   endpoint karyawan untuk menghapus templatenya sendiri.

TEST (feature test + face-service test dengan foto uji dari dataset W1)
- Wajah pemilik lolos; wajah orang lain di akun pemilik ditolak.
- Banyak wajah, tanpa wajah, gambar blur/gelap: ditolak dengan alasan jelas.
- Skor di zona review: online minta ulang, sync offline diberi review_flag.
- Sampel enrollment tidak konsisten: ditolak. Wajah yang sudah dipakai karyawan lain: ditahan.
- Percobaan gagal berurutan memicu kunci sementara.
- Skor dari client dimanipulasi: tidak berpengaruh pada keputusan.
- Template karyawan lain tidak pernah dipakai untuk membandingkan.
```

### W3 — Mesin Liveness di HP (titik berhenti)

```
Fase W3 absen wajah. W2 sudah selesai. Bangun mesin liveness toleh kiri/kanan di Flutter,
dipakai bersama oleh pendaftaran (W4) dan absen (W5). Belum mengubah layar absen yang ada;
buat halaman debug (hanya mode debug) untuk mengujinya.

DETEKSI & KUALITAS
- Pakai library OpenCV yang sudah dipilih di F1 (YuNet untuk deteksi + 5 landmark, SFace
  untuk embedding) dengan pra-pemrosesan identik server (alignCrop -> feature -> L2).
- Gerbang kualitas per frame: tepat satu wajah, ukuran minimal (relatif lebar frame),
  ketajaman (mis. varians Laplacian), kecerahan wajar, wajah di dalam bingkai. Beri umpan
  balik jelas ("Dekatkan wajah", "Cari cahaya lebih terang", "Tahan posisi").
- Proses frame di isolate atau dengan throttling (mis. 8-12 fps cukup) agar UI tidak patah
  dan HP lama tetap mulus.

PENGUKURAN TOLEH
- Dari 5 landmark YuNet hitung rasio yaw = (nose_x - mid_eyes_x) / jarak_antar_mata.
  Klasifikasi: depan (|rasio| kecil), kiri, kanan, dengan ambang yang bisa dikonfigurasi dan
  diperhalus (rata-rata beberapa frame terakhir, histeresis agar tidak berkedip).
- PERHATIAN arah: pratinjau kamera depan biasanya mirror. Definisikan "toleh kiri/kanan"
  dari sudut pandang pengguna, uji di HP asli, dan pastikan instruksi di layar sesuai gerakan.

TANTANGAN LIVENESS
- Urutan acak tiap sesi dari {kiri, kanan} (mis. kiri lalu kanan, atau kanan lalu kiri),
  setiap langkah wajib dicapai lalu KEMBALI menghadap depan sebelum langkah berikutnya.
  Batas waktu per langkah (mis. 6 detik) dan total sesi; gagal waktu -> ulang dari awal.
- Kunci identitas: ambil embedding frontal sebelum tantangan, setelah tiap langkah, dan di
  akhir. Jika kemiripan antar embedding ini turun di bawah batas (orang berganti), sesi
  gagal. Jangan membandingkan dengan template di tahap ini; ini hanya konsistensi dalam sesi.
- Keluaran mesin: sukses/gagal beserta alasan, dan frame depan terbaik (beberapa kandidat)
  untuk dipakai pencocokan. Frame saat menoleh TIDAK dipakai untuk pencocokan absen.
- Mesin tidak menyimpan frame ke disk. Semua di memori dan dibuang setelah sesi.

HALAMAN DEBUG
- Pratinjau kamera dengan nilai yaw, status kualitas, langkah tantangan, dan hasil sesi.

TES
- Unit test untuk klasifikasi yaw (data landmark sintetis), urutan acak (tidak selalu sama),
  dan kunci identitas.
BERHENTI setelah halaman debug jadi. Beri tahu saya cara mengujinya: foto cetak, foto di
layar HP lain, saya sendiri menoleh dengan benar, teman menggantikan di tengah tantangan.
```

### W4 — Alur Pendaftaran Wajah

```
Fase W4 absen wajah. W3 sudah disetujui. Bangun ulang alur pendaftaran wajah memakai mesin
liveness W3. Ikuti ROADMAP.md bagian 6.0 (design system, semua state UI).

1. Pendaftaran wajib sebelum bisa absen. Karyawan yang belum terdaftar diarahkan ke alur ini
   dari Home dan dari tombol absen, dengan penjelasan singkat dan ramah.
2. Layar persetujuan data biometrik (dari F2) tampil sebelum kamera dibuka.
3. Langkah-langkah (stepper): posisi wajah -> tantangan toleh acak -> ambil sampel depan,
   kiri, kanan (beberapa frame terbaik per pose, lolos gerbang kualitas) -> ringkasan.
4. Cek konsistensi antar sampel di HP (orang yang sama) sebelum dikirim. Jika tidak
   konsisten, ulangi dengan pesan jelas.
5. Kirim sampel ke API enrollment (W2). Tangani respons: sukses, ditolak kualitas, ditahan
   karena duplikat dengan karyawan lain (pesan netral: hubungi admin; jangan menyebut nama
   karyawan lain), server tidak terjangkau (tidak boleh pendaftaran offline).
6. Setelah sukses, unduh template milik sendiri dan simpan terenkripsi di HP (jaga
   kompatibilitas model_version). Hapus semua frame/gambar sementara.
7. Pendaftaran ulang: tidak tersedia di aplikasi. Tampilkan info "hubungi admin" bila perlu.
8. Umpan balik visual: bingkai oval berubah warna (netral -> hijau saat lolos kualitas),
   instruksi besar ("Toleh ke kiri"), indikator langkah, haptic ringan pada tiap langkah
   sukses. Hormati reduce motion dan font scale.

UJI
- Pendaftaran penuh berhasil; template terdownload dan tersimpan.
- Foto statis gagal di tantangan. Wajah berganti di tengah sesi gagal.
- Pendaftaran dua akun dengan wajah yang sama: yang kedua ditahan.
- Cahaya buruk/wajah kecil: umpan balik jelas, tidak crash.
- Tampilan benar di HP kecil/tablet, terang/gelap.
Beri tahu saya apa yang perlu saya cek manual di HP.
```

### W5 — Alur Absen dengan Liveness & Keputusan Server

```
Fase W5 absen wajah. W4 sudah selesai. Pasang liveness dan keputusan server ke alur absen
(F3), jangan menulis ulang bagian GPS/mock location.

ONLINE
1. Setelah cek lokasi lolos: gerbang kualitas -> tantangan toleh acak (W3) -> ambil beberapa
   frame depan terbaik -> cocok lokal dengan template (gerbang UX; jika jauh di bawah
   ambang lokal, minta ulang tanpa memanggil server).
2. Kirim gambar crop terbaik ke API check-in/check-out. Server menghitung ulang dan
   memutuskan (W2). Tampilkan hasil sesuai respons: lolos (lanjut ke layar hasil),
   coba lagi (sisa percobaan ditampilkan ramah), ditolak, terkunci sementara (hitung
   mundur dan pesan hubungi admin).
3. Jika tantangan gagal, ulang dari awal tanpa menghitung sebagai percobaan wajah gagal
   (hitungan percobaan hanya untuk ketidakcocokan wajah di server).

OFFLINE
4. Alur sama sampai pencocokan lokal. Hasil masuk antrian (OFFLINE_ATTENDANCE_ROADMAP.md),
   termasuk foto crop terenkripsi dan skor lokal. Server memutuskan saat sync; tidak cocok
   -> review_flag, tampil di aplikasi sebagai "Perlu review" (bahasa netral).

LAINNYA
5. Wajib terdaftar sebelum absen (alihkan ke W4 bila belum).
6. Tidak ada foto/frame yang disimpan di HP kecuali foto crop di antrian offline
   (terenkripsi, dihapus setelah synced).
7. Pesan error berbahasa Indonesia yang ramah, jangan menampilkan skor atau istilah teknis
   ke karyawan.

UJI
- Pemilik absen sukses (online dan offline).
- Teman memakai akun saya: ditolak server, hitungan percobaan naik, terkunci setelah batas.
- Foto cetak dan foto di layar gagal di tantangan toleh.
- Skor client dimanipulasi: server tetap memutuskan sendiri.
- Offline lalu sync wajah orang lain: ditandai review_flag, tidak lolos diam-diam.
- Jaringan putus di tengah pengiriman: tidak menghitung sebagai gagal wajah.
Beri tahu saya apa yang perlu saya cek manual di HP.
```

### W6 — Hardening & Uji Spoof

```
Fase W6 absen wajah. Tahap akhir.

1. Jalankan seluruh checklist di FACE_ATTENDANCE_ROADMAP.md bagian 7 dan laporkan hasil satu
   per satu. Perbaiki yang gagal dengan perubahan seminimal mungkin.
2. Ulangi kalibrasi (alat W1) dengan data baru dari pemakaian nyata (face_attempts, tanpa
   foto). Sesuaikan ambang bila FAR/FRR bergeser, lewat settings (tanpa rilis ulang).
3. Uji kondisi sulit: cahaya redup/kontra cahaya, kacamata, hijab, masker (catat batas
   kemampuan), jarak berbeda, HP kamera rendah.
4. Uji performa di HP spek rendah (Android 7, RAM 2GB): waktu dari buka kamera sampai hasil,
   suhu/baterai, memori. Optimalkan resolusi frame dan frekuensi proses bila perlu.
5. Opsional (diskusikan dulu, jangan langsung dibangun): model anti-spoof pasif (mis. berbasis
   tekstur/refleksi) sebagai lapis tambahan terhadap video replay; evaluasi ukuran model,
   akurasi, dan dampak performa di HP lama.
6. Dashboard web (B10): daftar "perlu review" menampilkan foto crop, skor lokal vs server,
   dan alasan, plus ringkasan harian jumlah percobaan gagal per karyawan untuk mendeteksi
   pola mencurigakan (tanpa menampilkan embedding).
7. Review keamanan dan privasi: template terenkripsi, tidak ada biometrik di log, foto crop
   dihapus setelah 30 hari, akses template hanya pemilik/server, rate limit endpoint wajah.
Beri ringkasan: apa yang lolos, apa yang masih berisiko, dan batas kemampuan sistem.
```

---

## 7. Checklist Uji Manual

**Identitas (inti masalah)**
1. Pemilik akun absen → lolos.
2. Teman memakai akun pemilik (online) → ditolak, percobaan tercatat.
3. Teman memakai akun pemilik (offline lalu sync) → ditandai "perlu review", tidak lolos diam-diam.
4. Gagal beruntun melewati batas → terkunci sementara dengan pesan jelas.
5. Skor dari HP dimanipulasi (uji dengan klien palsu/Postman) → keputusan server tidak terpengaruh.
6. Mendaftarkan wajah yang sama di dua akun → pendaftaran kedua ditahan.

**Liveness**
7. Foto cetak → gagal di tantangan toleh.
8. Foto/video di layar HP lain → gagal (catat bila video replay lolos; itu batas kemampuan, bukan bug diam-diam).
9. Toleh sesuai instruksi (kiri/kanan, urutan berbeda tiap sesi) → lolos; arah instruksi cocok dengan gerakan di HP asli.
10. Wajah berganti di tengah tantangan → gagal.
11. Tidak kembali menghadap depan → tidak lolos langkah berikutnya.

**Kualitas & kenyamanan**
12. Cahaya redup, kontra cahaya, kacamata, hijab → umpan balik jelas, pemilik tetap bisa lolos pada kondisi wajar.
13. Wajah terlalu jauh/kecil/blur → frame tidak dipakai, ada petunjuk.
14. Tampilan benar di HP kecil/tablet, terang/gelap, font 1.3x.
15. HP spek rendah (Android 7, RAM 2GB): proses lancar, tidak panas berlebihan.

**Privasi**
16. Tidak ada foto/embedding di log; foto sementara hilang setelah sesi; foto crop absen terhapus setelah 30 hari; template wajah tetap ada.

---

## 8. Keputusan yang Perlu Dikonfirmasi

| # | Keputusan | Usulan |
|---|---|---|
| 1 | Daftar ulang wajah | Hanya lewat superadmin (audit log). Alternatif: boleh oleh karyawan dengan approval manager |
| 2 | Jeda saat terkunci | 5 menit setelah 3 kali gagal |
| 3 | Skor kecocokan | Nilai tertinggi atau rata-rata 2 tertinggi, dipilih dari data W1 |
| 4 | Pendaftaran duplikat | Ditahan + dicatat, dilaporkan ke superadmin (bukan ditolak diam-diam) |
| 5 | Anti-spoof pasif (W6 opsional) | Evaluasi dulu setelah W0–W5 stabil |
| 6 | Absen offline dengan wajah tidak cocok | Tetap diterima dengan `review_flag` (sesuai keputusan awal); risikonya: orang bisa "menitip absen" lewat jalur offline sampai admin menandai tidak valid. Pertimbangkan batas jumlah absen offline per hari bila ini jadi masalah |

---

## 9. Catatan Kerja

- Uji identitas harus memakai orang sungguhan (teman, dengan persetujuan). Emulator dan foto saja tidak cukup untuk menilai akurasi.
- Dataset wajah untuk W1 adalah data biometrik: simpan di luar git, minta persetujuan, hapus setelah kalibrasi selesai.
- Angka ambang bukan konstanta universal; selalu kalibrasi dengan pipeline dan kamera yang benar-benar dipakai.
- Jangan mengubah model atau pra-pemrosesan di satu sisi saja; HP dan server harus berubah bersamaan dan `model_version` dinaikkan.
- Satu fase per sesi agent; uji manual dulu sebelum lanjut. W0, W1, W3 adalah titik berhenti.
