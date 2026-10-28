import json
import os
from functools import lru_cache

import cv2
import numpy as np
from dotenv import load_dotenv
from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile

load_dotenv()

TOKEN = os.environ.get("FACE_SERVICE_SECRET", "")
MODEL_DIR = os.environ.get("FACE_MODEL_DIR", os.path.join(os.path.dirname(__file__), "models"))
DETECTOR_FILE = os.environ.get("FACE_DETECTOR_FILE", "face_detection_yunet_2023mar.onnx")
RECOGNIZER_FILE = os.environ.get("FACE_RECOGNIZER_FILE", "face_recognition_sface_2021dec.onnx")
COSINE_THRESHOLD = float(os.environ.get("FACE_MATCH_THRESHOLD", "0.363"))
MODEL_VERSION = os.environ.get(
    "FACE_MODEL_VERSION", "sface-2021dec+yunet-2023mar"
)

app = FastAPI(title="Face Service", version="0.2")


def _check_secret(secret: str | None) -> None:
    if secret != TOKEN:
        raise HTTPException(status_code=401, detail="Unauthorized")


@lru_cache(maxsize=1)
def detector():
    path = os.path.join(MODEL_DIR, DETECTOR_FILE)
    if not os.path.exists(path):
        raise HTTPException(status_code=503, detail=f"Detector model tidak ditemukan: {path}")
    return cv2.FaceDetectorYN.create(path, "", (320, 320), score_threshold=0.7)


@lru_cache(maxsize=1)
def recognizer():
    path = os.path.join(MODEL_DIR, RECOGNIZER_FILE)
    if not os.path.exists(path):
        raise HTTPException(status_code=503, detail=f"Recognizer model tidak ditemukan: {path}")
    return cv2.FaceRecognizerSF.create(path, "")


def _decode(image_bytes: bytes) -> np.ndarray:
    arr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise HTTPException(status_code=422, detail="Gambar tidak bisa dibaca.")
    return img


def _detect_single_face(img: np.ndarray):
    det = detector()
    h, w = img.shape[:2]
    det.setInputSize((w, h))
    _, faces = det.detect(img)

    if faces is None or len(faces) == 0:
        raise HTTPException(status_code=422, detail="no_face")

    if len(faces) > 1:
        raise HTTPException(status_code=422, detail="multiple_faces")

    return faces[0]


def _compute_quality(img: np.ndarray, face: np.ndarray) -> dict:
    # face[0:4] = x, y, w, h
    x, y, w, h = map(int, face[:4])
    h_img, w_img = img.shape[:2]
    x1, y1 = max(0, x), max(0, y)
    x2, y2 = min(w_img, x + w), min(h_img, y + h)
    
    crop = img[y1:y2, x1:x2]
    if crop.size == 0:
        return {"sharpness": 0.0, "size": 0.0, "brightness": 0.0}

    gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
    sharpness = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    brightness = float(gray.mean())
    size_ratio = float((w * h) / (w_img * h_img))

    return {
        "sharpness": sharpness,
        "size": size_ratio,
        "brightness": brightness,
    }


def _embedding_from_file(image_bytes: bytes) -> dict:
    img = _decode(image_bytes)
    face = _detect_single_face(img)
    quality = _compute_quality(img, face)
    aligned = recognizer().alignCrop(img, face)
    feature = recognizer().feature(aligned)
    embedding = feature.flatten().astype(float).tolist()
    return {
        "embedding": embedding,
        "quality": quality,
    }


@app.get("/health")
async def health(x_face_secret: str = Header(default=None, alias="x-face-secret")):
    _check_secret(x_face_secret)
    return {"status": "ok", "service": "face-service", "model_version": MODEL_VERSION}


@app.post("/embed")
async def embed(
    image: UploadFile = File(...),
    x_face_secret: str = Header(default=None, alias="x-face-secret"),
):
    _check_secret(x_face_secret)
    data = await image.read()
    res = _embedding_from_file(data)
    embedding = res["embedding"]
    return {
        "model_version": MODEL_VERSION,
        "embedding": embedding,
        "dimension": len(embedding),
        "quality": res["quality"],
    }


@app.post("/verify")
async def verify(
    image: UploadFile = File(...),
    embedding: str = Form(...),
    x_face_secret: str = Header(default=None, alias="x-face-secret"),
):
    _check_secret(x_face_secret)

    try:
        stored = np.array(json.loads(embedding), dtype=np.float32).reshape(1, -1)
    except (ValueError, TypeError):
        raise HTTPException(status_code=422, detail="Embedding tidak valid.")

    data = await image.read()
    img = _decode(data)
    face = _detect_single_face(img)
    quality = _compute_quality(img, face)
    aligned = recognizer().alignCrop(img, face)
    feature = recognizer().feature(aligned)
    live = feature.flatten().astype(np.float32).reshape(1, -1)

    score = float(recognizer().match(stored, live, cv2.FaceRecognizerSF_FR_COSINE))

    return {
        "model_version": MODEL_VERSION,
        "score": score,
        "threshold": COSINE_THRESHOLD,
        "match": score >= COSINE_THRESHOLD,
        "quality": quality,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)

