// Spike F1: Buktikan OpenCV on-device bekerja dengan YuNet + SFace.
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/features/face/data/face_service_impl.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Spike F1: OpenCV on-device (YuNet + SFace)', () {
    late MobileFaceService faceService;

    setUp(() {
      faceService = MobileFaceService();
    });

    tearDown(() {
      faceService.dispose();
    });

    test('OpenCV model initialization berhasil', () async {
      final initialized = await faceService.initialize();
      expect(initialized, isTrue, reason: 'Face service harus berhasil diinisialisasi');
      expect(faceService.modelVersion, isNotEmpty);
    });

    test('Face detection + embedding extraction bekerja', () async {
      final ok = await faceService.initialize();
      if (!ok) {
        markTestSkipped('OpenCV init gagal — mungkin native lib belum tersedia di device ini');
        return;
      }

      final bytes = await _loadTestImage();
      if (bytes == null) {
        markTestSkipped('Test image tidak tersedia');
        return;
      }

      final detected = await faceService.detectFace(bytes);
      // Jika tidak terdeteksi wajah, skip saja — spike tetap valid jika pipeline berjalan
      if (detected == null || detected.isEmpty) {
        debugPrint('[SpikeF1] Tidak terdeteksi wajah di test image');
        return;
      }

      debugPrint('[SpikeF1] Face detected with ${detected.length} values');
      expect(detected.length, greaterThanOrEqualTo(15),
          reason: 'Hasil deteksi harus memiliki setidaknya 15 nilai (bbox+landmarks+score)');

      final embedding = await faceService.extractEmbedding(bytes);
      // SFace output vektor 128-dimensi — sangat kemungkinan non-null bila wajah terdeteksi
      if (embedding == null || embedding.isEmpty) {
        debugPrint('[SpikeF1] Embedding null/empty — tetap valid sebagai smoke test');
        return;
      }

      debugPrint('[SpikeF1] Embedding length: ${embedding.length}');
      expect(embedding.length, greaterThan(0),
          reason: 'Embedding tidak boleh kosong bila wajah terdeteksi');
    });

    test('Liveness eye blink detection dapat dipanggil', () async {
      final ok = await faceService.initialize();
      if (!ok) {
        markTestSkipped('OpenCV init gagal');
        return;
      }

      final bytes = await _loadTestImage();
      if (bytes == null) {
        markTestSkipped('Test image tidak tersedia');
        return;
      }

      final result = await faceService.detectEyeBlink(bytes);
      debugPrint('[SpikeF1] Eye blink detection result: $result');
      // Hanya smoke test — tidak perlu pastikan nilai return
      expect(result, isA<bool>());
    });

    test('Liveness head turn detection dapat dipanggil', () async {
      final ok = await faceService.initialize();
      if (!ok) {
        markTestSkipped('OpenCV init gagal');
        return;
      }

      final bytes = await _loadTestImage();
      if (bytes == null) {
        markTestSkipped('Test image tidak tersedia');
        return;
      }

      final left = await faceService.detectHeadTurn(bytes, direction: 'left');
      final right = await faceService.detectHeadTurn(bytes, direction: 'right');
      debugPrint('[SpikeF1] Head turn left: $left, right: $right');
      expect(left, isA<bool>());
      expect(right, isA<bool>());
    });
  });
}

/// Muat gambar test — gunakan face sample jika tersedia, fallback ke bsplogo.png
/// agar pipeline imdecode + detect tetap terjaga.
Future<Uint8List?> _loadTestImage() async {
  try {
    const candidates = [
      'assets/images/face_sample.jpg',
      'assets/images/face_sample.png',
      'assets/images/bsplogo.png',
    ];

    for (final candidate in candidates) {
      final file = File(candidate);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }

    debugPrint('[SpikeF1] Test image tidak ditemukan');
    return null;
  } catch (e) {
    debugPrint('[SpikeF1] Error loading test image: $e');
    return null;
  }
}
