"""Unduh model ONNX dari OpenCV Zoo (YuNet + SFace). Jalankan sekali.

    python download_models.py
"""

import os
import urllib.request

MODELS = {
    "face_detection_yunet_2023mar.onnx": (
        "https://github.com/opencv/opencv_zoo/raw/main/models/"
        "face_detection_yunet/face_detection_yunet_2023mar.onnx"
    ),
    "face_recognition_sface_2021dec.onnx": (
        "https://github.com/opencv/opencv_zoo/raw/main/models/"
        "face_recognition_sface/face_recognition_sface_2021dec.onnx"
    ),
}


def main() -> None:
    target = os.path.join(os.path.dirname(__file__), "models")
    os.makedirs(target, exist_ok=True)

    for name, url in MODELS.items():
        dest = os.path.join(target, name)
        if os.path.exists(dest):
            print(f"skip {name} (sudah ada)")
            continue
        print(f"unduh {name} ...")
        urllib.request.urlretrieve(url, dest)
        print(f"  -> {dest}")


if __name__ == "__main__":
    main()
