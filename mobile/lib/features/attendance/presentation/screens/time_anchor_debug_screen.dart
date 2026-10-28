import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:mobile/features/attendance/data/local/elapsed_time_service.dart';
import 'package:mobile/features/attendance/data/local/offline_database.dart';

class TimeAnchorDebugScreen extends ConsumerStatefulWidget {
  const TimeAnchorDebugScreen({super.key});

  @override
  ConsumerState<TimeAnchorDebugScreen> createState() => _TimeAnchorDebugScreenState();
}

class _TimeAnchorDebugScreenState extends ConsumerState<TimeAnchorDebugScreen> {
  bool _isLoading = false;
  ServerTimeAnchor? _currentAnchor;
  TimeCalculationResult? _calculationResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnchorStats();
  }

  Future<void> _loadAnchorStats() async {
    if (!kDebugMode) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final offlineService = ref.read(offlineAttendanceServiceProvider);
      final elapsedTimeService = ref.read(elapsedTimeServiceProvider);
      
      final anchor = await offlineService.getOrCreateAnchor();
      final calc = await elapsedTimeService.calculateServerTime(
        anchorServerTimeMillis: anchor.serverTimeMillis,
        anchorElapsedMillis: anchor.elapsedRealtimeMillis,
        anchorBootCount: anchor.bootCount,
      );

      setState(() {
        _currentAnchor = anchor;
        _calculationResult = calc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug mode only')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeAnchor Debug (Fase O1)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnchorStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stored Anchor Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Divider(),
                              Text('Anchor ID: ${_currentAnchor?.id ?? "-"}'),
                              Text('Server Time (Anchor): ${_currentAnchor != null ? DateTime.fromMillisecondsSinceEpoch(_currentAnchor!.serverTimeMillis) : "-"}'),
                              Text('Elapsed Realtime (Anchor): ${_currentAnchor?.elapsedRealtimeMillis ?? "-"} ms'),
                              Text('Boot Count (Anchor): ${_currentAnchor?.bootCount ?? "-"}'),
                              Text('Created At: ${_currentAnchor?.createdAt ?? "-"}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Status & Calculation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Divider(),
                              Text('Current Elapsed Realtime: ${_calculationResult?.currentElapsedMillis ?? "-"} ms'),
                              Text('Current Boot Count: ${_calculationResult?.currentBootCount ?? "-"}'),
                              const SizedBox(height: 8),
                              Text(
                                'Estimated Server Time:\n${_calculationResult?.calculatedServerTime ?? "-"}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Anchor Usability / Suspect: '),
                                  Chip(
                                    label: Text(
                                      (_calculationResult?.isSuspect ?? false) ? 'SUSPECT (Boot Changed)' : 'VALID',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: (_calculationResult?.isSuspect ?? false) ? Colors.red : Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
