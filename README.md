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
venv\Scripts\pip install -r requirements.txt   (fastapi uvicorn opencv-python-headless numpy python-multipart python-dotenv)
venv\Scripts\activate
copy .env.example .env   (atau edit FACE_SERVICE_SECRET)
uvicorn main:app --host 127.0.0.1 --port 8001
```

- Endpoint kesehatan: `GET http://127.0.0.1:8001/health`  
  Header `x-face-secret: <FACE_SERVICE_SECRET>` wajib.

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

## Milestone

Lihat ROADMAP.md — tiap sesi kerjakan satu milestone. B0 (setup skeleton) adalah titik saat ini.
