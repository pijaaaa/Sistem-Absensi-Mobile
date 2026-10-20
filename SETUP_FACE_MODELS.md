# Setup Model Wajah (Face Recognition Models)

## Model yang Dibutuhkan

Aplikasi ini menggunakan OpenCV dengan model YuNet (deteksi wajah) dan SFace (pengenalan wajah) untuk verifikasi wajah on-device.

### File Model yang Dibutuhkan:

1. **face_detection_yunet_2023mar.onnx** - YuNet face detector
2. **face_recognition_sface_2021dec.onnx** - SFace face recognizer

## Cara Download Model

### Opsi 1: Download dari OpenCV Zoo (Recommended)

```bash
# Download YuNet detector
curl -L "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx" -o "mobile/assets/models/face_detection_yunet_2023mar.onnx"

# Download SFace recognizer
curl -L "https://github.com/opencv/opencv_zoo/raw/main/models/face_recognition_sface/face_recognition_sface_2021dec.onnx" -o "mobile/assets/models/face_recognition_sface_2021dec.onnx"
```

### Opsi 2: Download Manual

1. **YuNet Detector:**
   - URL: https://github.com/opencv/opencv_zoo/tree/main/models/face_detection_yunet
   - Download file: `face_detection_yunet_2023mar.onnx`
   - Simpan di: `mobile/assets/models/`

2. **SFace Recognizer:**
   - URL: https://github.com/opencv/opencv_zoo/tree/main/models/face_recognition_sface
   - Download file: `face_recognition_sface_2021dec.onnx`
   - Simpan di: `mobile/assets/models/`

## Verifikasi

Setelah download, pastikan struktur folder seperti ini:

```
mobile/
├── assets/
│   ├── images/
│   │   └── bsplogo.png
│   └── models/
│       ├── face_detection_yunet_2023mar.onnx  (2-3 MB)
│       └── face_recognition_sface_2021dec.onnx  (40-45 MB)
```

## Catatan Penting

- Model ini **wajib** ada sebelum menjalankan aplikasi
- Ukuran total model sekitar **45-50 MB**
- Model akan di-copy ke temporary directory saat pertama kali digunakan
- Model versi ini **kompatibel** dengan face-service backend (Python FastAPI)
- Jika backend menggunakan model versi berbeda, koordinasikan dengan backend developer

## Troubleshooting

**Error: "Face service initialization error"**
- Cek apakah file model ada di `mobile/assets/models/`
- Pastikan nama file sama persis (case-sensitive)
- Cek ukuran file (YuNet ~2-3MB, SFace ~40-45MB)

**Error: "Unable to load model"**
- Pastikan `pubspec.yaml` sudah include `assets/models/`
- Jalankan `flutter pub get` dan rebuild aplikasi
- Cek izin storage di Android (runtime permission)
