import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'offline_database.g.dart';

/// Offline attendance queue table
class OfflineAttendances extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientUuid => text().unique()();
  BoolColumn get isCheckIn => boolean()();
  
  // Location data
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  
  // Face data
  RealColumn get faceScoreLocal => real()();
  TextColumn get faceImagePath => text().nullable()(); // Encrypted image path
  
  // Time tracking (elapsed-realtime based)
  IntColumn get elapsedRealtimeMillis => integer()(); // Elapsed time saat absen
  IntColumn get anchorServerTimeMillis => integer()(); // Server time saat anchor dibuat
  IntColumn get anchorElapsedMillis => integer()(); // Elapsed time saat anchor dibuat
  IntColumn get bootCount => integer()(); // Boot count device
  
  // Device info
  TextColumn get deviceUid => text().nullable()();
  BoolColumn get isBackupDevice => boolean().withDefault(const Constant(false))();
  
  // Sync status
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();
}

/// Server time anchor for elapsed-realtime calculation
class ServerTimeAnchors extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverTimeMillis => integer()(); // Server time in milliseconds since epoch
  IntColumn get elapsedRealtimeMillis => integer()(); // Device elapsed time
  IntColumn get bootCount => integer()(); // Device boot count
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [OfflineAttendances, ServerTimeAnchors])
class OfflineDatabase extends _$OfflineDatabase {
  OfflineDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // === OFFLINE ATTENDANCE OPERATIONS ===
  
  /// Add new offline attendance to queue
  Future<int> addOfflineAttendance(OfflineAttendancesCompanion attendance) {
    return into(offlineAttendances).insert(attendance);
  }

  /// Get all pending (not synced) attendances
  Future<List<OfflineAttendance>> getPendingAttendances() {
    return (select(offlineAttendances)
          ..where((tbl) => tbl.isSynced.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  /// Get attendance by clientUuid (for idempotent check)
  Future<OfflineAttendance?> getAttendanceByUuid(String uuid) {
    return (select(offlineAttendances)
          ..where((tbl) => tbl.clientUuid.equals(uuid)))
        .getSingleOrNull();
  }

  /// Mark attendance as synced
  Future<void> markAsSynced(String clientUuid) {
    return (update(offlineAttendances)
          ..where((tbl) => tbl.clientUuid.equals(clientUuid)))
        .write(
      OfflineAttendancesCompanion(
        isSynced: const Value(true),
      ),
    );
  }

  /// Update sync attempt
  Future<void> updateSyncAttempt(String clientUuid, String? error) async {
    final attendance = await getAttendanceByUuid(clientUuid);
    if (attendance == null) return;
    
    await (update(offlineAttendances)
          ..where((tbl) => tbl.clientUuid.equals(clientUuid)))
        .write(
      OfflineAttendancesCompanion(
        syncAttempts: Value(attendance.syncAttempts + 1),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  /// Get count of pending attendances
  Future<int> getPendingCount() async {
    final count = countAll();
    final query = selectOnly(offlineAttendances)
      ..addColumns([count])
      ..where(offlineAttendances.isSynced.equals(false));
    
    final result = await query.getSingleOrNull();
    return result?.read(count) ?? 0;
  }

  /// Delete synced attendances older than N days
  Future<int> deleteSyncedOlderThan(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (delete(offlineAttendances)
          ..where((tbl) =>
              tbl.isSynced.equals(true) & tbl.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }

  // === SERVER TIME ANCHOR OPERATIONS ===

  /// Save server time anchor
  Future<int> saveServerTimeAnchor(ServerTimeAnchorsCompanion anchor) {
    return into(serverTimeAnchors).insert(anchor);
  }

  /// Get latest server time anchor
  Future<ServerTimeAnchor?> getLatestAnchor() {
    return (select(serverTimeAnchors)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Delete old anchors (keep only latest 5)
  Future<void> cleanOldAnchors() async {
    final anchors = await (select(serverTimeAnchors)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(5))
        .get();
    
    if (anchors.isEmpty) return;
    
    final oldestToKeep = anchors.last.id;
    await (delete(serverTimeAnchors)
          ..where((tbl) => tbl.id.isSmallerThanValue(oldestToKeep)))
        .go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'offline_attendance.db'));
    return NativeDatabase(file);
  });
}
