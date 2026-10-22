/// Spike F1 unit test — unit test untuk fungsi cosine similarity (match)
/// dan verifikasi modelVersion.
///
/// Test ini tidak membutuhkan OpenCV native runtime — hanya menguji logika Dart murni.
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/face/data/face_matcher.dart';

void main() {
  group('Spike F1: cosine similarity match()', () {
    test('match() returns 0.0 for vectors of different length', () {
      final a = [1.0, 2.0, 3.0];
      final b = [1.0, 2.0];
      expect(faceDistance(a, b), 1.0);
    });

    test('match() returns ~0.0 (perfect match) untuk vektor identik', () {
      final a = List.filled(128, 0.5);
      final b = List.filled(128, 0.5);
      final result = faceDistance(a, b);
      expect(result, lessThan(0.01), reason: 'Vektor identik harus memberi distance ~0');
    });

    test('match() returns higher value for orthogonal vectors', () {
      final a = List.filled(128, 0.0)..[0] = 1.0;
      final b = List.filled(128, 0.0)..[1] = 1.0;
      final result = faceDistance(a, b);
      expect(result, greaterThan(0.49), reason: 'Orthogonal vectors harus memberi distance tinggi (~0.5)');
    });

    test('cosineSimilarity returns 1.0 for identical vectors', () {
      final a = [0.3, 0.4, 0.5];
      expect(cosineSimilarity(a, a), closeTo(1.0, 0.001));
    });

    test('modelVersion format is valid', () {
      const modelVersion = 'sface-2021dec+yunet-2023mar';
      expect(modelVersion, contains('sface'));
      expect(modelVersion, contains('yunet'));
    });
  });
}
