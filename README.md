# Sistem Absensi

**Stack:** Laravel 13 (API + web admin) · Flutter Android · Python FastAPI + OpenCV (face-service) · MySQL (Laragon)

## Persyaratan

- PHP **8.3+** (cek `php -v`)
- Composer
- Node.js + npm
- Python 3.11+ + pip
- Laragon (Apache + MySQL), atau sertelar MySQL host lain

## Struktur

```
absensi/
├─ backend/        Laravel 13 (API + web admin Blade/Tailwind/Alpine)
├─ mobile/         Flutter Android (dikerjakan nanti)
├─ face-service/   Python FastAPI + OpenCV (service wajah)
└─ README.md
```

## Menjalankan (Windows / Laragon)

### 1. Backend (Laravel)

```bat
cd backend
copy .env.example .env     (atau pastikan .env ada)
edit .env: DB_CONNECTION=mysql, DB_DATABASE=absensi_db, FACE_SERVICE_SECRET=<sama dengan face-service>
php artisan key:generate
php artisan migrate        (konfirmasi "yes" untuk membuat DB)
npm install
npm run build
php artisan serve
```

Akses web admin: http://localhost:8000 (login superadmin, endpoint ditambahkan di milestone B1)

### 2. Face-service (Python)

```bat
cd face-service
python -m venv venv
venv\Scripts\pip install -r requirements.txt
venv\Scripts\activate
copy .env.example .env   (atau edit FACE_SERVICE_SECRET)
python download_models.py      (unduh model ONNX YuNet + SFace dari OpenCV Zoo, sekali saja)
uvicorn main:app --host 127.0.0.1 --port 8001
```

- Model ONNX disimpan di `face-service/models/` dan **tidak** di-commit (lihat `.gitignore`).
- Endpoint: `GET /health`, `POST /embed`, `POST /verify`. Semua butuh header `x-face-secret`.
- `/embed`: kirim `multipart/form-data` field `image` -> `{model_version, embedding[128], dimension}`.
  Gambar tanpa wajah -> `422 {"detail":"no_face"}`; lebih dari satu wajah -> `422 {"detail":"multiple_faces"}`.
- `/verify`: field `image` + form `embedding` (JSON array) -> `{model_version, score, threshold, match}`.

#### Menyiapkan foto uji

Letakkan foto berisi **satu wajah** per file (JPG/PNG), wajah menghadap ke depan. Contoh cepat
memakai gambar uji OpenCV:

```bat
curl -sL -o lena.jpg https://raw.githubusercontent.com/opencv/opencv/master/samples/data/lena.jpg
curl -sL -o messi5.jpg https://raw.githubusercontent.com/opencv/opencv/master/samples/data/messi5.jpg
venv\Scripts\python test_face.py lena.jpg messi5.jpg
```

Output contoh: `lena vs lena -> MATCH (1.0000)`, `lena vs messi5 -> NO MATCH (0.1270)`.
Untuk menguji `/embed` dan `/verify` lewat HTTP, lihat `curl` pada bagian di atas.

### 3. Laravel ↔ Face-service

Laravel memanggil face-service via HTTP client. Secret dan URL diatur di `.env` backend:

```
FACE_SERVICE_URL=http://127.0.0.1:8001
FACE_SERVICE_SECRET=changeme-to-opaque-secret
```

Cek koneksi (dari folder `backend`):

```
php artisan tinker --execute="echo Illuminate\Support\Facades\Http::withHeaders(['x-face-secret'=>config('services.face.secret')])->timeout(3)->get(config('services.face.url').'/health')->body();"
```

Harus mengembalikan `{"status":"ok","service":"face-service"}`.

### 4. Push notification (FCM)

1. Buat project di [Firebase Console](https://console.firebase.google.com), tambahkan app Android.
2. Salin **Server key** (Project Settings → Cloud Messaging) ke `backend/.env`:
   ```
   FCM_SERVER_KEY=AAAA...
   ```
   Jika `FCM_SERVER_KEY` kosong, push dilewati (notifikasi in-app tetap tersimpan di tabel `notifications`).
3. Di aplikasi Flutter (Kelompok 2): ambil token FCM, kirim ke `POST /api/push-tokens`.

> Catatan: implementasi sekarang memakai endpoint FCM legacy. Untuk production, migrasikan ke **HTTP v1** (service account) — kontrak `FcmService` tinggal diganti.

### 5. Job terjadwal

Jalankan scheduler (Windows Task Scheduler atau terminal):

```
php artisan schedule:work
```

- `app:mark-absentees` (harian 00:05) — tandai alfa hari kerja lewat tanpa absen/izin.
- `app:purge-expired-face-captures` (harian 01:00) — hapus foto crop > 30 hari (file + baris); template wajah tidak disentuh.

## Milestone

Lihat ROADMAP.md — tiap sesi kerjakan satu milestone. Kelompok 1 berjalan: B0–B9 selesai (skeleton, master data & auth, manajemen akses & menu, web admin, rules engine, face-service & API wajah, absensi online + device binding, offline sync, cuti/sakit/izin/dinas, notifikasi & job terjadwal).
