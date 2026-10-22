// Pure Dart face matching utilities — tidak bergantung pada OpenCV native libs.
// Memungkinkan unit test terisolasi di CI/desktop tanpa native assets.

/// Hitung cosine similarity antara dua vektor.
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length) return 0.0;

  double dotProduct = 0;
  double normA = 0;
  double normB = 0;
  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  final denom = (normA * normB);
  if (denom == 0) return 0.0;

  return dotProduct / denom;
}

/// Hitung face distance dari dua embedding.
/// Nilai 0 = perfect match, 1 = no match (berdasarkan OpenCV FaceRecognizerSF::match).
double faceDistance(List<double> stored, List<double> live) {
  if (stored.length != live.length) return 1.0;

  final cos = cosineSimilarity(stored, live);
  return ((1 - cos) / 2).clamp(0.0, 1.0);
}
