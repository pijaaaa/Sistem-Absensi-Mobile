"""Uji manual face-service dengan foto nyata (tanpa server).

    python test_face.py foto_orang_A.jpg foto_orang_B.jpg

- embed A, lalu:
  - verify A terhadap embedding A  -> harus match (skor tinggi)
  - verify B terhadap embedding A  -> seharusnya tidak match (orang berbeda)
Cetak skor kemiripan kosinus.
"""

import json
import os
import sys

import cv2
import numpy as np
from dotenv import load_dotenv

load_dotenv()

from main import COSINE_THRESHOLD, MODEL_VERSION, _embedding_from_file, recognizer

BASE = os.path.dirname(__file__)


def _load(path: str) -> np.ndarray:
    with open(path, "rb") as fh:
        data = fh.read()
    img = cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_COLOR)
    if img is None:
        raise SystemExit(f"Gagal baca gambar: {path}")
    return img


def _to_matrix(embedding: list[float]) -> np.ndarray:
    return np.array(embedding, dtype=np.float32).reshape(1, -1)


def _similarity(a: list[float], b: list[float]) -> float:
    return float(recognizer().match(_to_matrix(a), _to_matrix(b), cv2.FaceRecognizerSF_FR_COSINE))


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)

    img_a, img_b = sys.argv[1], sys.argv[2]
    print(f"model_version: {MODEL_VERSION}, threshold: {COSINE_THRESHOLD}")

    emb_a = _embedding_from_file(open(img_a, "rb").read())
    emb_b = _embedding_from_file(open(img_b, "rb").read())
    print(f"dimensi embedding: {len(emb_a)}")

    same = _similarity(emb_a, emb_a)
    diff = _similarity(emb_a, emb_b)
    print(f"skor A vs A (harus ~1.0, match): {same:.4f} -> {'MATCH' if same >= COSINE_THRESHOLD else 'NO'}")
    print(f"skor A vs B (orang beda): {diff:.4f} -> {'MATCH' if diff >= COSINE_THRESHOLD else 'NO MATCH'}")


if __name__ == "__main__":
    main()
