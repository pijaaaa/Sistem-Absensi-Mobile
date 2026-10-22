import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/face/data/face_data_source.dart';
import 'package:mobile/features/face/data/face_service.dart';
import 'package:mobile/features/face/data/face_service_impl.dart';
import 'package:mobile/features/face/data/face_service_stub.dart';
import 'package:mobile/core/network/providers.dart';

/// Factory: choose implementation based on platform
BaseFaceService createFaceService() {
  if (kIsWeb) return StubFaceService();
  return MobileFaceService();
}

final faceServiceProvider = Provider<BaseFaceService>((ref) {
  final service = createFaceService();
  ref.onDispose(() => service.dispose());
  return service;
});

final faceDataSourceProvider = Provider<FaceDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return FaceDataSourceImpl(dio: dio);
});

final faceServiceInitProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(faceServiceProvider);
  return await service.initialize();
});

/// Face enrollment state
class FaceEnrollmentState {
  final bool isInitialized;
  final bool isInEnrollment;
  final int samplesTaken;
  final int totalSamples;
  final String livenessChallenge;
  final bool livenessPassed;
  final DateTime? livenessStartedAt;
  final String? errorMessage;

  FaceEnrollmentState({
    this.isInitialized = false,
    this.isInEnrollment = false,
    this.samplesTaken = 0,
    this.totalSamples = 5,
    this.livenessChallenge = '',
    this.livenessPassed = false,
    this.livenessStartedAt,
    this.errorMessage,
  });

  FaceEnrollmentState copyWith({
    bool? isInitialized,
    bool? isInEnrollment,
    int? samplesTaken,
    int? totalSamples,
    String? livenessChallenge,
    bool? livenessPassed,
    DateTime? livenessStartedAt,
    String? errorMessage,
  }) {
    return FaceEnrollmentState(
      isInitialized: isInitialized ?? this.isInitialized,
      isInEnrollment: isInEnrollment ?? this.isInEnrollment,
      samplesTaken: samplesTaken ?? this.samplesTaken,
      totalSamples: totalSamples ?? this.totalSamples,
      livenessChallenge: livenessChallenge ?? this.livenessChallenge,
      livenessPassed: livenessPassed ?? this.livenessPassed,
      livenessStartedAt: livenessStartedAt ?? this.livenessStartedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FaceEnrollmentNotifier extends StateNotifier<FaceEnrollmentState> {
  FaceEnrollmentNotifier() : super(FaceEnrollmentState());

  void startEnrollment() {
    state = state.copyWith(
      isInEnrollment: true,
      samplesTaken: 0,
      livenessChallenge: '',
      livenessPassed: false,
      errorMessage: null,
    );
  }

  void setLivenessChallenge(String challenge) {
    state = state.copyWith(
      livenessChallenge: challenge,
      livenessStartedAt: DateTime.now(),
    );
  }

  void completeLiveness() {
    state = state.copyWith(livenessPassed: true);
  }

  void addSample() {
    final newCount = state.samplesTaken + 1;
    state = state.copyWith(
      samplesTaken: newCount,
      livenessPassed: false,
    );
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void completeEnrollment() {
    state = state.copyWith(
      isInEnrollment: false,
      isInitialized: true,
      samplesTaken: 0,
      livenessPassed: false,
    );
  }

  void reset() {
    state = FaceEnrollmentState();
  }
}

final faceEnrollmentProvider =
    StateNotifierProvider<FaceEnrollmentNotifier, FaceEnrollmentState>((ref) {
  return FaceEnrollmentNotifier();
});
