import os
import glob
import cv2
import numpy as np

def cosine_similarity(a, b):
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))

def main():
    model_dir = os.path.join(os.path.dirname(__file__), "../models")
    detector_path = os.path.join(model_dir, "face_detection_yunet_2023mar.onnx")
    recognizer_path = os.path.join(model_dir, "face_recognition_sface_2021dec.onnx")

    detector = cv2.FaceDetectorYN.create(detector_path, "", (320, 320), score_threshold=0.7)
    recognizer = cv2.FaceRecognizerSF.create(recognizer_path, "")

    dataset_dir = os.path.join(os.path.dirname(__file__), "dataset")
    person_dirs = [d for d in glob.glob(os.path.join(dataset_dir, "*")) if os.path.isdir(d)]

    embeddings = {}
    for pdir in person_dirs:
        pname = os.path.basename(pdir)
        embs = []
        img_paths = glob.glob(os.path.join(pdir, "*.jpg")) + glob.glob(os.path.join(pdir, "*.png"))
        for ipath in img_paths:
            img = cv2.imread(ipath)
            if img is None:
                continue
            h, w = img.shape[:2]
            detector.setInputSize((w, h))
            _, faces = detector.detect(img)
            if faces is None or len(faces) != 1:
                continue
            aligned = recognizer.alignCrop(img, faces[0])
            feat = recognizer.feature(aligned).flatten()
            embs.append(feat)
        if len(embs) > 0:
            embeddings[pname] = embs

    persons = list(embeddings.keys())
    genuine = []
    for p in persons:
        embs = embeddings[p]
        n = len(embs)
        for i in range(n):
            for j in range(i + 1, n):
                score = cosine_similarity(embs[i], embs[j])
                genuine.append(score)

    impostor = []
    for i in range(len(persons)):
        for j in range(i + 1, len(persons)):
            p1 = persons[i]
            p2 = persons[j]
            for e1 in embeddings[p1]:
                for e2 in embeddings[p2]:
                    score = cosine_similarity(e1, e2)
                    impostor.append(score)

    gen_arr = np.array(genuine) if genuine else np.array([0.0])
    imp_arr = np.array(impostor) if impostor else np.array([0.0])

    print("--- SUMMARY STATISTICS ---")
    print(f"Genuine: min={gen_arr.min():.4f}, mean={gen_arr.mean():.4f}, max={gen_arr.max():.4f}, count={len(gen_arr)}")
    print(f"Impostor: min={imp_arr.min():.4f}, mean={imp_arr.mean():.4f}, max={imp_arr.max():.4f}, count={len(imp_arr)}")

    thresholds = [round(t, 2) for t in np.arange(0.30, 0.72, 0.02)]
    print("\n--- FAR / FRR TABLE ---")
    print(f"{'Threshold':<10} | {'FAR (%)':<10} | {'FRR (%)':<10}")
    print("-" * 36)

    best_t = None
    min_eer_diff = float('inf')
    t_pass = None
    t_review = None

    for t in thresholds:
        far = float(np.sum(imp_arr >= t) / len(imp_arr)) * 100 if len(imp_arr) > 0 else 0.0
        frr = float(np.sum(gen_arr < t) / len(gen_arr)) * 100 if len(gen_arr) > 0 else 0.0
        print(f"{t:<10.2f} | {far:<10.2f} | {frr:<10.2f}")

        diff = abs(far - frr)
        if diff < min_eer_diff:
            min_eer_diff = diff
            best_t = t

    t_pass = best_t
    t_review = round(best_t - 0.05, 2)
    print(f"\nRecommended T_pass: {t_pass}")
    print(f"Recommended T_review: {t_review}")

    try:
        import matplotlib
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt
        plt.figure(figsize=(8, 5))
        plt.hist(gen_arr, bins=30, alpha=0.5, label='Genuine', color='blue', density=True)
        plt.hist(imp_arr, bins=30, alpha=0.5, label='Impostor', color='red', density=True)
        plt.axvline(t_pass, color='green', linestyle='--', label=f'T_pass ({t_pass})')
        plt.title('Cosine Similarity Score Distribution')
        plt.xlabel('Cosine Similarity')
        plt.ylabel('Density')
        plt.legend()
        plt.tight_layout()
        plot_path = os.path.join(os.path.dirname(__file__), 'calibration_plot.png')
        plt.savefig(plot_path)
        print(f"Histogram saved to {plot_path}")
    except ImportError:
        print("matplotlib not installed, skipping plot generation.")

if __name__ == '__main__':
    main()
