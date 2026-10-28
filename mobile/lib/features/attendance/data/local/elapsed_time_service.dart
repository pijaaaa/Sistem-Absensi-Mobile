import 'dart:io';
import 'package:flutter/services.dart';

/// Service untuk tracking waktu menggunakan elapsed-realtime
/// Elapsed-realtime: waktu sejak device boot (tidak terpengaruh perubahan waktu sistem)
class ElapsedTimeService {
  static const MethodChannel _channel = MethodChannel('com.bsp.absensi/elapsed_time');
  
  // Fallback stopwatch untuk uptime lokal yang aman dari perubahan jam sistem
  static final Stopwatch _fallbackStopwatch = Stopwatch()..start();

  /// Get elapsed realtime in milliseconds (Android: SystemClock.elapsedRealtime())
  /// Returns milliseconds since device boot
  Future<int> getElapsedRealtimeMillis() async {
    if (Platform.isAndroid) {
      try {
        final int elapsedMillis = await _channel.invokeMethod('getElapsedRealtime');
        return elapsedMillis;
      } catch (e) {
        // Fallback: gunakan Stopwatch uptime (TIDAK terpengaruh perubahan jam sistem)
        return _fallbackStopwatch.elapsedMilliseconds;
      }
    } else {
      // iOS/other: gunakan Stopwatch uptime
      return _fallbackStopwatch.elapsedMilliseconds;
    }
  }

  /// Get boot count (jumlah restart device)
  /// Digunakan untuk detect apakah device sudah restart sejak anchor dibuat
  Future<int> getBootCount() async {
    if (Platform.isAndroid) {
      try {
        final int bootCount = await _channel.invokeMethod('getBootCount');
        return bootCount;
      } catch (e) {
        return 0; // Fallback
      }
    } else {
      return 0;
    }
  }

  /// Calculate server time dari elapsed-realtime anchor
  /// 
  /// Formula:
  /// server_time = anchor_server_time + (current_elapsed - anchor_elapsed)
  /// 
  /// Returns:
  /// - calculatedServerTime: waktu server yang dihitung
  /// - isSuspect: true jika boot count berubah (device restart)
  Future<TimeCalculationResult> calculateServerTime({
    required int anchorServerTimeMillis,
    required int anchorElapsedMillis,
    required int anchorBootCount,
  }) async {
    final currentElapsed = await getElapsedRealtimeMillis();
    final currentBootCount = await getBootCount();

    // Check if device restarted
    final isSuspect = currentBootCount != anchorBootCount;

    // Calculate server time
    final elapsedDiff = currentElapsed - anchorElapsedMillis;
    final calculatedServerTime = anchorServerTimeMillis + elapsedDiff;

    return TimeCalculationResult(
      calculatedServerTimeMillis: calculatedServerTime,
      isSuspect: isSuspect,
      currentElapsedMillis: currentElapsed,
      currentBootCount: currentBootCount,
    );
  }
}

class TimeCalculationResult {
  final int calculatedServerTimeMillis;
  final bool isSuspect;
  final int currentElapsedMillis;
  final int currentBootCount;

  TimeCalculationResult({
    required this.calculatedServerTimeMillis,
    required this.isSuspect,
    required this.currentElapsedMillis,
    required this.currentBootCount,
  });

  DateTime get calculatedServerTime =>
      DateTime.fromMillisecondsSinceEpoch(calculatedServerTimeMillis);
}
