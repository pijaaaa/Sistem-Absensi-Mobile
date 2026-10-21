// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_database.dart';

// ignore_for_file: type=lint
class $OfflineAttendancesTable extends OfflineAttendances
    with TableInfo<$OfflineAttendancesTable, OfflineAttendance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineAttendancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _clientUuidMeta =
      const VerificationMeta('clientUuid');
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
      'client_uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _isCheckInMeta =
      const VerificationMeta('isCheckIn');
  @override
  late final GeneratedColumn<bool> isCheckIn = GeneratedColumn<bool>(
      'is_check_in', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_check_in" IN (0, 1))'));
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _faceScoreLocalMeta =
      const VerificationMeta('faceScoreLocal');
  @override
  late final GeneratedColumn<double> faceScoreLocal = GeneratedColumn<double>(
      'face_score_local', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _faceImagePathMeta =
      const VerificationMeta('faceImagePath');
  @override
  late final GeneratedColumn<String> faceImagePath = GeneratedColumn<String>(
      'face_image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _elapsedRealtimeMillisMeta =
      const VerificationMeta('elapsedRealtimeMillis');
  @override
  late final GeneratedColumn<int> elapsedRealtimeMillis = GeneratedColumn<int>(
      'elapsed_realtime_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _anchorServerTimeMillisMeta =
      const VerificationMeta('anchorServerTimeMillis');
  @override
  late final GeneratedColumn<int> anchorServerTimeMillis = GeneratedColumn<int>(
      'anchor_server_time_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _anchorElapsedMillisMeta =
      const VerificationMeta('anchorElapsedMillis');
  @override
  late final GeneratedColumn<int> anchorElapsedMillis = GeneratedColumn<int>(
      'anchor_elapsed_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bootCountMeta =
      const VerificationMeta('bootCount');
  @override
  late final GeneratedColumn<int> bootCount = GeneratedColumn<int>(
      'boot_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deviceUidMeta =
      const VerificationMeta('deviceUid');
  @override
  late final GeneratedColumn<String> deviceUid = GeneratedColumn<String>(
      'device_uid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isBackupDeviceMeta =
      const VerificationMeta('isBackupDevice');
  @override
  late final GeneratedColumn<bool> isBackupDevice = GeneratedColumn<bool>(
      'is_backup_device', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_backup_device" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncAttemptsMeta =
      const VerificationMeta('syncAttempts');
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
      'sync_attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastSyncAttemptMeta =
      const VerificationMeta('lastSyncAttempt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>('last_sync_attempt', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncErrorMeta =
      const VerificationMeta('syncError');
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
      'sync_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clientUuid,
        isCheckIn,
        latitude,
        longitude,
        faceScoreLocal,
        faceImagePath,
        elapsedRealtimeMillis,
        anchorServerTimeMillis,
        anchorElapsedMillis,
        bootCount,
        deviceUid,
        isBackupDevice,
        isSynced,
        syncAttempts,
        createdAt,
        lastSyncAttempt,
        syncError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_attendances';
  @override
  VerificationContext validateIntegrity(Insertable<OfflineAttendance> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
          _clientUuidMeta,
          clientUuid.isAcceptableOrUnknown(
              data['client_uuid']!, _clientUuidMeta));
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('is_check_in')) {
      context.handle(
          _isCheckInMeta,
          isCheckIn.isAcceptableOrUnknown(
              data['is_check_in']!, _isCheckInMeta));
    } else if (isInserting) {
      context.missing(_isCheckInMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('face_score_local')) {
      context.handle(
          _faceScoreLocalMeta,
          faceScoreLocal.isAcceptableOrUnknown(
              data['face_score_local']!, _faceScoreLocalMeta));
    } else if (isInserting) {
      context.missing(_faceScoreLocalMeta);
    }
    if (data.containsKey('face_image_path')) {
      context.handle(
          _faceImagePathMeta,
          faceImagePath.isAcceptableOrUnknown(
              data['face_image_path']!, _faceImagePathMeta));
    }
    if (data.containsKey('elapsed_realtime_millis')) {
      context.handle(
          _elapsedRealtimeMillisMeta,
          elapsedRealtimeMillis.isAcceptableOrUnknown(
              data['elapsed_realtime_millis']!, _elapsedRealtimeMillisMeta));
    } else if (isInserting) {
      context.missing(_elapsedRealtimeMillisMeta);
    }
    if (data.containsKey('anchor_server_time_millis')) {
      context.handle(
          _anchorServerTimeMillisMeta,
          anchorServerTimeMillis.isAcceptableOrUnknown(
              data['anchor_server_time_millis']!, _anchorServerTimeMillisMeta));
    } else if (isInserting) {
      context.missing(_anchorServerTimeMillisMeta);
    }
    if (data.containsKey('anchor_elapsed_millis')) {
      context.handle(
          _anchorElapsedMillisMeta,
          anchorElapsedMillis.isAcceptableOrUnknown(
              data['anchor_elapsed_millis']!, _anchorElapsedMillisMeta));
    } else if (isInserting) {
      context.missing(_anchorElapsedMillisMeta);
    }
    if (data.containsKey('boot_count')) {
      context.handle(_bootCountMeta,
          bootCount.isAcceptableOrUnknown(data['boot_count']!, _bootCountMeta));
    } else if (isInserting) {
      context.missing(_bootCountMeta);
    }
    if (data.containsKey('device_uid')) {
      context.handle(_deviceUidMeta,
          deviceUid.isAcceptableOrUnknown(data['device_uid']!, _deviceUidMeta));
    }
    if (data.containsKey('is_backup_device')) {
      context.handle(
          _isBackupDeviceMeta,
          isBackupDevice.isAcceptableOrUnknown(
              data['is_backup_device']!, _isBackupDeviceMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
          _syncAttemptsMeta,
          syncAttempts.isAcceptableOrUnknown(
              data['sync_attempts']!, _syncAttemptsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
          _lastSyncAttemptMeta,
          lastSyncAttempt.isAcceptableOrUnknown(
              data['last_sync_attempt']!, _lastSyncAttemptMeta));
    }
    if (data.containsKey('sync_error')) {
      context.handle(_syncErrorMeta,
          syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineAttendance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineAttendance(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      clientUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_uuid'])!,
      isCheckIn: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_check_in'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      faceScoreLocal: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}face_score_local'])!,
      faceImagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}face_image_path']),
      elapsedRealtimeMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}elapsed_realtime_millis'])!,
      anchorServerTimeMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}anchor_server_time_millis'])!,
      anchorElapsedMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}anchor_elapsed_millis'])!,
      bootCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}boot_count'])!,
      deviceUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_uid']),
      isBackupDevice: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_backup_device'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncAttempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_attempts'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_sync_attempt']),
      syncError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_error']),
    );
  }

  @override
  $OfflineAttendancesTable createAlias(String alias) {
    return $OfflineAttendancesTable(attachedDatabase, alias);
  }
}

class OfflineAttendance extends DataClass
    implements Insertable<OfflineAttendance> {
  final int id;
  final String clientUuid;
  final bool isCheckIn;
  final double latitude;
  final double longitude;
  final double faceScoreLocal;
  final String? faceImagePath;
  final int elapsedRealtimeMillis;
  final int anchorServerTimeMillis;
  final int anchorElapsedMillis;
  final int bootCount;
  final String? deviceUid;
  final bool isBackupDevice;
  final bool isSynced;
  final int syncAttempts;
  final DateTime createdAt;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  const OfflineAttendance(
      {required this.id,
      required this.clientUuid,
      required this.isCheckIn,
      required this.latitude,
      required this.longitude,
      required this.faceScoreLocal,
      this.faceImagePath,
      required this.elapsedRealtimeMillis,
      required this.anchorServerTimeMillis,
      required this.anchorElapsedMillis,
      required this.bootCount,
      this.deviceUid,
      required this.isBackupDevice,
      required this.isSynced,
      required this.syncAttempts,
      required this.createdAt,
      this.lastSyncAttempt,
      this.syncError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_uuid'] = Variable<String>(clientUuid);
    map['is_check_in'] = Variable<bool>(isCheckIn);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['face_score_local'] = Variable<double>(faceScoreLocal);
    if (!nullToAbsent || faceImagePath != null) {
      map['face_image_path'] = Variable<String>(faceImagePath);
    }
    map['elapsed_realtime_millis'] = Variable<int>(elapsedRealtimeMillis);
    map['anchor_server_time_millis'] = Variable<int>(anchorServerTimeMillis);
    map['anchor_elapsed_millis'] = Variable<int>(anchorElapsedMillis);
    map['boot_count'] = Variable<int>(bootCount);
    if (!nullToAbsent || deviceUid != null) {
      map['device_uid'] = Variable<String>(deviceUid);
    }
    map['is_backup_device'] = Variable<bool>(isBackupDevice);
    map['is_synced'] = Variable<bool>(isSynced);
    map['sync_attempts'] = Variable<int>(syncAttempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  OfflineAttendancesCompanion toCompanion(bool nullToAbsent) {
    return OfflineAttendancesCompanion(
      id: Value(id),
      clientUuid: Value(clientUuid),
      isCheckIn: Value(isCheckIn),
      latitude: Value(latitude),
      longitude: Value(longitude),
      faceScoreLocal: Value(faceScoreLocal),
      faceImagePath: faceImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(faceImagePath),
      elapsedRealtimeMillis: Value(elapsedRealtimeMillis),
      anchorServerTimeMillis: Value(anchorServerTimeMillis),
      anchorElapsedMillis: Value(anchorElapsedMillis),
      bootCount: Value(bootCount),
      deviceUid: deviceUid == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceUid),
      isBackupDevice: Value(isBackupDevice),
      isSynced: Value(isSynced),
      syncAttempts: Value(syncAttempts),
      createdAt: Value(createdAt),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory OfflineAttendance.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineAttendance(
      id: serializer.fromJson<int>(json['id']),
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      isCheckIn: serializer.fromJson<bool>(json['isCheckIn']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      faceScoreLocal: serializer.fromJson<double>(json['faceScoreLocal']),
      faceImagePath: serializer.fromJson<String?>(json['faceImagePath']),
      elapsedRealtimeMillis:
          serializer.fromJson<int>(json['elapsedRealtimeMillis']),
      anchorServerTimeMillis:
          serializer.fromJson<int>(json['anchorServerTimeMillis']),
      anchorElapsedMillis:
          serializer.fromJson<int>(json['anchorElapsedMillis']),
      bootCount: serializer.fromJson<int>(json['bootCount']),
      deviceUid: serializer.fromJson<String?>(json['deviceUid']),
      isBackupDevice: serializer.fromJson<bool>(json['isBackupDevice']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientUuid': serializer.toJson<String>(clientUuid),
      'isCheckIn': serializer.toJson<bool>(isCheckIn),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'faceScoreLocal': serializer.toJson<double>(faceScoreLocal),
      'faceImagePath': serializer.toJson<String?>(faceImagePath),
      'elapsedRealtimeMillis': serializer.toJson<int>(elapsedRealtimeMillis),
      'anchorServerTimeMillis': serializer.toJson<int>(anchorServerTimeMillis),
      'anchorElapsedMillis': serializer.toJson<int>(anchorElapsedMillis),
      'bootCount': serializer.toJson<int>(bootCount),
      'deviceUid': serializer.toJson<String?>(deviceUid),
      'isBackupDevice': serializer.toJson<bool>(isBackupDevice),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  OfflineAttendance copyWith(
          {int? id,
          String? clientUuid,
          bool? isCheckIn,
          double? latitude,
          double? longitude,
          double? faceScoreLocal,
          Value<String?> faceImagePath = const Value.absent(),
          int? elapsedRealtimeMillis,
          int? anchorServerTimeMillis,
          int? anchorElapsedMillis,
          int? bootCount,
          Value<String?> deviceUid = const Value.absent(),
          bool? isBackupDevice,
          bool? isSynced,
          int? syncAttempts,
          DateTime? createdAt,
          Value<DateTime?> lastSyncAttempt = const Value.absent(),
          Value<String?> syncError = const Value.absent()}) =>
      OfflineAttendance(
        id: id ?? this.id,
        clientUuid: clientUuid ?? this.clientUuid,
        isCheckIn: isCheckIn ?? this.isCheckIn,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        faceScoreLocal: faceScoreLocal ?? this.faceScoreLocal,
        faceImagePath:
            faceImagePath.present ? faceImagePath.value : this.faceImagePath,
        elapsedRealtimeMillis:
            elapsedRealtimeMillis ?? this.elapsedRealtimeMillis,
        anchorServerTimeMillis:
            anchorServerTimeMillis ?? this.anchorServerTimeMillis,
        anchorElapsedMillis: anchorElapsedMillis ?? this.anchorElapsedMillis,
        bootCount: bootCount ?? this.bootCount,
        deviceUid: deviceUid.present ? deviceUid.value : this.deviceUid,
        isBackupDevice: isBackupDevice ?? this.isBackupDevice,
        isSynced: isSynced ?? this.isSynced,
        syncAttempts: syncAttempts ?? this.syncAttempts,
        createdAt: createdAt ?? this.createdAt,
        lastSyncAttempt: lastSyncAttempt.present
            ? lastSyncAttempt.value
            : this.lastSyncAttempt,
        syncError: syncError.present ? syncError.value : this.syncError,
      );
  OfflineAttendance copyWithCompanion(OfflineAttendancesCompanion data) {
    return OfflineAttendance(
      id: data.id.present ? data.id.value : this.id,
      clientUuid:
          data.clientUuid.present ? data.clientUuid.value : this.clientUuid,
      isCheckIn: data.isCheckIn.present ? data.isCheckIn.value : this.isCheckIn,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      faceScoreLocal: data.faceScoreLocal.present
          ? data.faceScoreLocal.value
          : this.faceScoreLocal,
      faceImagePath: data.faceImagePath.present
          ? data.faceImagePath.value
          : this.faceImagePath,
      elapsedRealtimeMillis: data.elapsedRealtimeMillis.present
          ? data.elapsedRealtimeMillis.value
          : this.elapsedRealtimeMillis,
      anchorServerTimeMillis: data.anchorServerTimeMillis.present
          ? data.anchorServerTimeMillis.value
          : this.anchorServerTimeMillis,
      anchorElapsedMillis: data.anchorElapsedMillis.present
          ? data.anchorElapsedMillis.value
          : this.anchorElapsedMillis,
      bootCount: data.bootCount.present ? data.bootCount.value : this.bootCount,
      deviceUid: data.deviceUid.present ? data.deviceUid.value : this.deviceUid,
      isBackupDevice: data.isBackupDevice.present
          ? data.isBackupDevice.value
          : this.isBackupDevice,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineAttendance(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('isCheckIn: $isCheckIn, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('faceScoreLocal: $faceScoreLocal, ')
          ..write('faceImagePath: $faceImagePath, ')
          ..write('elapsedRealtimeMillis: $elapsedRealtimeMillis, ')
          ..write('anchorServerTimeMillis: $anchorServerTimeMillis, ')
          ..write('anchorElapsedMillis: $anchorElapsedMillis, ')
          ..write('bootCount: $bootCount, ')
          ..write('deviceUid: $deviceUid, ')
          ..write('isBackupDevice: $isBackupDevice, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      clientUuid,
      isCheckIn,
      latitude,
      longitude,
      faceScoreLocal,
      faceImagePath,
      elapsedRealtimeMillis,
      anchorServerTimeMillis,
      anchorElapsedMillis,
      bootCount,
      deviceUid,
      isBackupDevice,
      isSynced,
      syncAttempts,
      createdAt,
      lastSyncAttempt,
      syncError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineAttendance &&
          other.id == this.id &&
          other.clientUuid == this.clientUuid &&
          other.isCheckIn == this.isCheckIn &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.faceScoreLocal == this.faceScoreLocal &&
          other.faceImagePath == this.faceImagePath &&
          other.elapsedRealtimeMillis == this.elapsedRealtimeMillis &&
          other.anchorServerTimeMillis == this.anchorServerTimeMillis &&
          other.anchorElapsedMillis == this.anchorElapsedMillis &&
          other.bootCount == this.bootCount &&
          other.deviceUid == this.deviceUid &&
          other.isBackupDevice == this.isBackupDevice &&
          other.isSynced == this.isSynced &&
          other.syncAttempts == this.syncAttempts &&
          other.createdAt == this.createdAt &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError);
}

class OfflineAttendancesCompanion extends UpdateCompanion<OfflineAttendance> {
  final Value<int> id;
  final Value<String> clientUuid;
  final Value<bool> isCheckIn;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> faceScoreLocal;
  final Value<String?> faceImagePath;
  final Value<int> elapsedRealtimeMillis;
  final Value<int> anchorServerTimeMillis;
  final Value<int> anchorElapsedMillis;
  final Value<int> bootCount;
  final Value<String?> deviceUid;
  final Value<bool> isBackupDevice;
  final Value<bool> isSynced;
  final Value<int> syncAttempts;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  const OfflineAttendancesCompanion({
    this.id = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.isCheckIn = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.faceScoreLocal = const Value.absent(),
    this.faceImagePath = const Value.absent(),
    this.elapsedRealtimeMillis = const Value.absent(),
    this.anchorServerTimeMillis = const Value.absent(),
    this.anchorElapsedMillis = const Value.absent(),
    this.bootCount = const Value.absent(),
    this.deviceUid = const Value.absent(),
    this.isBackupDevice = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
  });
  OfflineAttendancesCompanion.insert({
    this.id = const Value.absent(),
    required String clientUuid,
    required bool isCheckIn,
    required double latitude,
    required double longitude,
    required double faceScoreLocal,
    this.faceImagePath = const Value.absent(),
    required int elapsedRealtimeMillis,
    required int anchorServerTimeMillis,
    required int anchorElapsedMillis,
    required int bootCount,
    this.deviceUid = const Value.absent(),
    this.isBackupDevice = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
  })  : clientUuid = Value(clientUuid),
        isCheckIn = Value(isCheckIn),
        latitude = Value(latitude),
        longitude = Value(longitude),
        faceScoreLocal = Value(faceScoreLocal),
        elapsedRealtimeMillis = Value(elapsedRealtimeMillis),
        anchorServerTimeMillis = Value(anchorServerTimeMillis),
        anchorElapsedMillis = Value(anchorElapsedMillis),
        bootCount = Value(bootCount);
  static Insertable<OfflineAttendance> custom({
    Expression<int>? id,
    Expression<String>? clientUuid,
    Expression<bool>? isCheckIn,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? faceScoreLocal,
    Expression<String>? faceImagePath,
    Expression<int>? elapsedRealtimeMillis,
    Expression<int>? anchorServerTimeMillis,
    Expression<int>? anchorElapsedMillis,
    Expression<int>? bootCount,
    Expression<String>? deviceUid,
    Expression<bool>? isBackupDevice,
    Expression<bool>? isSynced,
    Expression<int>? syncAttempts,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (isCheckIn != null) 'is_check_in': isCheckIn,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (faceScoreLocal != null) 'face_score_local': faceScoreLocal,
      if (faceImagePath != null) 'face_image_path': faceImagePath,
      if (elapsedRealtimeMillis != null)
        'elapsed_realtime_millis': elapsedRealtimeMillis,
      if (anchorServerTimeMillis != null)
        'anchor_server_time_millis': anchorServerTimeMillis,
      if (anchorElapsedMillis != null)
        'anchor_elapsed_millis': anchorElapsedMillis,
      if (bootCount != null) 'boot_count': bootCount,
      if (deviceUid != null) 'device_uid': deviceUid,
      if (isBackupDevice != null) 'is_backup_device': isBackupDevice,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
    });
  }

  OfflineAttendancesCompanion copyWith(
      {Value<int>? id,
      Value<String>? clientUuid,
      Value<bool>? isCheckIn,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<double>? faceScoreLocal,
      Value<String?>? faceImagePath,
      Value<int>? elapsedRealtimeMillis,
      Value<int>? anchorServerTimeMillis,
      Value<int>? anchorElapsedMillis,
      Value<int>? bootCount,
      Value<String?>? deviceUid,
      Value<bool>? isBackupDevice,
      Value<bool>? isSynced,
      Value<int>? syncAttempts,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastSyncAttempt,
      Value<String?>? syncError}) {
    return OfflineAttendancesCompanion(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      isCheckIn: isCheckIn ?? this.isCheckIn,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      faceScoreLocal: faceScoreLocal ?? this.faceScoreLocal,
      faceImagePath: faceImagePath ?? this.faceImagePath,
      elapsedRealtimeMillis:
          elapsedRealtimeMillis ?? this.elapsedRealtimeMillis,
      anchorServerTimeMillis:
          anchorServerTimeMillis ?? this.anchorServerTimeMillis,
      anchorElapsedMillis: anchorElapsedMillis ?? this.anchorElapsedMillis,
      bootCount: bootCount ?? this.bootCount,
      deviceUid: deviceUid ?? this.deviceUid,
      isBackupDevice: isBackupDevice ?? this.isBackupDevice,
      isSynced: isSynced ?? this.isSynced,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      createdAt: createdAt ?? this.createdAt,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (isCheckIn.present) {
      map['is_check_in'] = Variable<bool>(isCheckIn.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (faceScoreLocal.present) {
      map['face_score_local'] = Variable<double>(faceScoreLocal.value);
    }
    if (faceImagePath.present) {
      map['face_image_path'] = Variable<String>(faceImagePath.value);
    }
    if (elapsedRealtimeMillis.present) {
      map['elapsed_realtime_millis'] =
          Variable<int>(elapsedRealtimeMillis.value);
    }
    if (anchorServerTimeMillis.present) {
      map['anchor_server_time_millis'] =
          Variable<int>(anchorServerTimeMillis.value);
    }
    if (anchorElapsedMillis.present) {
      map['anchor_elapsed_millis'] = Variable<int>(anchorElapsedMillis.value);
    }
    if (bootCount.present) {
      map['boot_count'] = Variable<int>(bootCount.value);
    }
    if (deviceUid.present) {
      map['device_uid'] = Variable<String>(deviceUid.value);
    }
    if (isBackupDevice.present) {
      map['is_backup_device'] = Variable<bool>(isBackupDevice.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineAttendancesCompanion(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('isCheckIn: $isCheckIn, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('faceScoreLocal: $faceScoreLocal, ')
          ..write('faceImagePath: $faceImagePath, ')
          ..write('elapsedRealtimeMillis: $elapsedRealtimeMillis, ')
          ..write('anchorServerTimeMillis: $anchorServerTimeMillis, ')
          ..write('anchorElapsedMillis: $anchorElapsedMillis, ')
          ..write('bootCount: $bootCount, ')
          ..write('deviceUid: $deviceUid, ')
          ..write('isBackupDevice: $isBackupDevice, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }
}

class $ServerTimeAnchorsTable extends ServerTimeAnchors
    with TableInfo<$ServerTimeAnchorsTable, ServerTimeAnchor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServerTimeAnchorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverTimeMillisMeta =
      const VerificationMeta('serverTimeMillis');
  @override
  late final GeneratedColumn<int> serverTimeMillis = GeneratedColumn<int>(
      'server_time_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _elapsedRealtimeMillisMeta =
      const VerificationMeta('elapsedRealtimeMillis');
  @override
  late final GeneratedColumn<int> elapsedRealtimeMillis = GeneratedColumn<int>(
      'elapsed_realtime_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bootCountMeta =
      const VerificationMeta('bootCount');
  @override
  late final GeneratedColumn<int> bootCount = GeneratedColumn<int>(
      'boot_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, serverTimeMillis, elapsedRealtimeMillis, bootCount, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'server_time_anchors';
  @override
  VerificationContext validateIntegrity(Insertable<ServerTimeAnchor> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_time_millis')) {
      context.handle(
          _serverTimeMillisMeta,
          serverTimeMillis.isAcceptableOrUnknown(
              data['server_time_millis']!, _serverTimeMillisMeta));
    } else if (isInserting) {
      context.missing(_serverTimeMillisMeta);
    }
    if (data.containsKey('elapsed_realtime_millis')) {
      context.handle(
          _elapsedRealtimeMillisMeta,
          elapsedRealtimeMillis.isAcceptableOrUnknown(
              data['elapsed_realtime_millis']!, _elapsedRealtimeMillisMeta));
    } else if (isInserting) {
      context.missing(_elapsedRealtimeMillisMeta);
    }
    if (data.containsKey('boot_count')) {
      context.handle(_bootCountMeta,
          bootCount.isAcceptableOrUnknown(data['boot_count']!, _bootCountMeta));
    } else if (isInserting) {
      context.missing(_bootCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServerTimeAnchor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerTimeAnchor(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverTimeMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}server_time_millis'])!,
      elapsedRealtimeMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}elapsed_realtime_millis'])!,
      bootCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}boot_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ServerTimeAnchorsTable createAlias(String alias) {
    return $ServerTimeAnchorsTable(attachedDatabase, alias);
  }
}

class ServerTimeAnchor extends DataClass
    implements Insertable<ServerTimeAnchor> {
  final int id;
  final int serverTimeMillis;
  final int elapsedRealtimeMillis;
  final int bootCount;
  final DateTime createdAt;
  const ServerTimeAnchor(
      {required this.id,
      required this.serverTimeMillis,
      required this.elapsedRealtimeMillis,
      required this.bootCount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_time_millis'] = Variable<int>(serverTimeMillis);
    map['elapsed_realtime_millis'] = Variable<int>(elapsedRealtimeMillis);
    map['boot_count'] = Variable<int>(bootCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ServerTimeAnchorsCompanion toCompanion(bool nullToAbsent) {
    return ServerTimeAnchorsCompanion(
      id: Value(id),
      serverTimeMillis: Value(serverTimeMillis),
      elapsedRealtimeMillis: Value(elapsedRealtimeMillis),
      bootCount: Value(bootCount),
      createdAt: Value(createdAt),
    );
  }

  factory ServerTimeAnchor.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerTimeAnchor(
      id: serializer.fromJson<int>(json['id']),
      serverTimeMillis: serializer.fromJson<int>(json['serverTimeMillis']),
      elapsedRealtimeMillis:
          serializer.fromJson<int>(json['elapsedRealtimeMillis']),
      bootCount: serializer.fromJson<int>(json['bootCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverTimeMillis': serializer.toJson<int>(serverTimeMillis),
      'elapsedRealtimeMillis': serializer.toJson<int>(elapsedRealtimeMillis),
      'bootCount': serializer.toJson<int>(bootCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ServerTimeAnchor copyWith(
          {int? id,
          int? serverTimeMillis,
          int? elapsedRealtimeMillis,
          int? bootCount,
          DateTime? createdAt}) =>
      ServerTimeAnchor(
        id: id ?? this.id,
        serverTimeMillis: serverTimeMillis ?? this.serverTimeMillis,
        elapsedRealtimeMillis:
            elapsedRealtimeMillis ?? this.elapsedRealtimeMillis,
        bootCount: bootCount ?? this.bootCount,
        createdAt: createdAt ?? this.createdAt,
      );
  ServerTimeAnchor copyWithCompanion(ServerTimeAnchorsCompanion data) {
    return ServerTimeAnchor(
      id: data.id.present ? data.id.value : this.id,
      serverTimeMillis: data.serverTimeMillis.present
          ? data.serverTimeMillis.value
          : this.serverTimeMillis,
      elapsedRealtimeMillis: data.elapsedRealtimeMillis.present
          ? data.elapsedRealtimeMillis.value
          : this.elapsedRealtimeMillis,
      bootCount: data.bootCount.present ? data.bootCount.value : this.bootCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerTimeAnchor(')
          ..write('id: $id, ')
          ..write('serverTimeMillis: $serverTimeMillis, ')
          ..write('elapsedRealtimeMillis: $elapsedRealtimeMillis, ')
          ..write('bootCount: $bootCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, serverTimeMillis, elapsedRealtimeMillis, bootCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerTimeAnchor &&
          other.id == this.id &&
          other.serverTimeMillis == this.serverTimeMillis &&
          other.elapsedRealtimeMillis == this.elapsedRealtimeMillis &&
          other.bootCount == this.bootCount &&
          other.createdAt == this.createdAt);
}

class ServerTimeAnchorsCompanion extends UpdateCompanion<ServerTimeAnchor> {
  final Value<int> id;
  final Value<int> serverTimeMillis;
  final Value<int> elapsedRealtimeMillis;
  final Value<int> bootCount;
  final Value<DateTime> createdAt;
  const ServerTimeAnchorsCompanion({
    this.id = const Value.absent(),
    this.serverTimeMillis = const Value.absent(),
    this.elapsedRealtimeMillis = const Value.absent(),
    this.bootCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ServerTimeAnchorsCompanion.insert({
    this.id = const Value.absent(),
    required int serverTimeMillis,
    required int elapsedRealtimeMillis,
    required int bootCount,
    this.createdAt = const Value.absent(),
  })  : serverTimeMillis = Value(serverTimeMillis),
        elapsedRealtimeMillis = Value(elapsedRealtimeMillis),
        bootCount = Value(bootCount);
  static Insertable<ServerTimeAnchor> custom({
    Expression<int>? id,
    Expression<int>? serverTimeMillis,
    Expression<int>? elapsedRealtimeMillis,
    Expression<int>? bootCount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverTimeMillis != null) 'server_time_millis': serverTimeMillis,
      if (elapsedRealtimeMillis != null)
        'elapsed_realtime_millis': elapsedRealtimeMillis,
      if (bootCount != null) 'boot_count': bootCount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ServerTimeAnchorsCompanion copyWith(
      {Value<int>? id,
      Value<int>? serverTimeMillis,
      Value<int>? elapsedRealtimeMillis,
      Value<int>? bootCount,
      Value<DateTime>? createdAt}) {
    return ServerTimeAnchorsCompanion(
      id: id ?? this.id,
      serverTimeMillis: serverTimeMillis ?? this.serverTimeMillis,
      elapsedRealtimeMillis:
          elapsedRealtimeMillis ?? this.elapsedRealtimeMillis,
      bootCount: bootCount ?? this.bootCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverTimeMillis.present) {
      map['server_time_millis'] = Variable<int>(serverTimeMillis.value);
    }
    if (elapsedRealtimeMillis.present) {
      map['elapsed_realtime_millis'] =
          Variable<int>(elapsedRealtimeMillis.value);
    }
    if (bootCount.present) {
      map['boot_count'] = Variable<int>(bootCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServerTimeAnchorsCompanion(')
          ..write('id: $id, ')
          ..write('serverTimeMillis: $serverTimeMillis, ')
          ..write('elapsedRealtimeMillis: $elapsedRealtimeMillis, ')
          ..write('bootCount: $bootCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$OfflineDatabase extends GeneratedDatabase {
  _$OfflineDatabase(QueryExecutor e) : super(e);
  $OfflineDatabaseManager get managers => $OfflineDatabaseManager(this);
  late final $OfflineAttendancesTable offlineAttendances =
      $OfflineAttendancesTable(this);
  late final $ServerTimeAnchorsTable serverTimeAnchors =
      $ServerTimeAnchorsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [offlineAttendances, serverTimeAnchors];
}

typedef $$OfflineAttendancesTableCreateCompanionBuilder
    = OfflineAttendancesCompanion Function({
  Value<int> id,
  required String clientUuid,
  required bool isCheckIn,
  required double latitude,
  required double longitude,
  required double faceScoreLocal,
  Value<String?> faceImagePath,
  required int elapsedRealtimeMillis,
  required int anchorServerTimeMillis,
  required int anchorElapsedMillis,
  required int bootCount,
  Value<String?> deviceUid,
  Value<bool> isBackupDevice,
  Value<bool> isSynced,
  Value<int> syncAttempts,
  Value<DateTime> createdAt,
  Value<DateTime?> lastSyncAttempt,
  Value<String?> syncError,
});
typedef $$OfflineAttendancesTableUpdateCompanionBuilder
    = OfflineAttendancesCompanion Function({
  Value<int> id,
  Value<String> clientUuid,
  Value<bool> isCheckIn,
  Value<double> latitude,
  Value<double> longitude,
  Value<double> faceScoreLocal,
  Value<String?> faceImagePath,
  Value<int> elapsedRealtimeMillis,
  Value<int> anchorServerTimeMillis,
  Value<int> anchorElapsedMillis,
  Value<int> bootCount,
  Value<String?> deviceUid,
  Value<bool> isBackupDevice,
  Value<bool> isSynced,
  Value<int> syncAttempts,
  Value<DateTime> createdAt,
  Value<DateTime?> lastSyncAttempt,
  Value<String?> syncError,
});

class $$OfflineAttendancesTableFilterComposer
    extends Composer<_$OfflineDatabase, $OfflineAttendancesTable> {
  $$OfflineAttendancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCheckIn => $composableBuilder(
      column: $table.isCheckIn, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get faceScoreLocal => $composableBuilder(
      column: $table.faceScoreLocal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get faceImagePath => $composableBuilder(
      column: $table.faceImagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedRealtimeMillis => $composableBuilder(
      column: $table.elapsedRealtimeMillis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get anchorServerTimeMillis => $composableBuilder(
      column: $table.anchorServerTimeMillis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get anchorElapsedMillis => $composableBuilder(
      column: $table.anchorElapsedMillis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bootCount => $composableBuilder(
      column: $table.bootCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceUid => $composableBuilder(
      column: $table.deviceUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isBackupDevice => $composableBuilder(
      column: $table.isBackupDevice,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncAttempts => $composableBuilder(
      column: $table.syncAttempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
      column: $table.lastSyncAttempt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnFilters(column));
}

class $$OfflineAttendancesTableOrderingComposer
    extends Composer<_$OfflineDatabase, $OfflineAttendancesTable> {
  $$OfflineAttendancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCheckIn => $composableBuilder(
      column: $table.isCheckIn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get faceScoreLocal => $composableBuilder(
      column: $table.faceScoreLocal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get faceImagePath => $composableBuilder(
      column: $table.faceImagePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedRealtimeMillis => $composableBuilder(
      column: $table.elapsedRealtimeMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get anchorServerTimeMillis => $composableBuilder(
      column: $table.anchorServerTimeMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get anchorElapsedMillis => $composableBuilder(
      column: $table.anchorElapsedMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bootCount => $composableBuilder(
      column: $table.bootCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceUid => $composableBuilder(
      column: $table.deviceUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBackupDevice => $composableBuilder(
      column: $table.isBackupDevice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
      column: $table.syncAttempts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
      column: $table.lastSyncAttempt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnOrderings(column));
}

class $$OfflineAttendancesTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $OfflineAttendancesTable> {
  $$OfflineAttendancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => column);

  GeneratedColumn<bool> get isCheckIn =>
      $composableBuilder(column: $table.isCheckIn, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get faceScoreLocal => $composableBuilder(
      column: $table.faceScoreLocal, builder: (column) => column);

  GeneratedColumn<String> get faceImagePath => $composableBuilder(
      column: $table.faceImagePath, builder: (column) => column);

  GeneratedColumn<int> get elapsedRealtimeMillis => $composableBuilder(
      column: $table.elapsedRealtimeMillis, builder: (column) => column);

  GeneratedColumn<int> get anchorServerTimeMillis => $composableBuilder(
      column: $table.anchorServerTimeMillis, builder: (column) => column);

  GeneratedColumn<int> get anchorElapsedMillis => $composableBuilder(
      column: $table.anchorElapsedMillis, builder: (column) => column);

  GeneratedColumn<int> get bootCount =>
      $composableBuilder(column: $table.bootCount, builder: (column) => column);

  GeneratedColumn<String> get deviceUid =>
      $composableBuilder(column: $table.deviceUid, builder: (column) => column);

  GeneratedColumn<bool> get isBackupDevice => $composableBuilder(
      column: $table.isBackupDevice, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
      column: $table.syncAttempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
      column: $table.lastSyncAttempt, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$OfflineAttendancesTableTableManager extends RootTableManager<
    _$OfflineDatabase,
    $OfflineAttendancesTable,
    OfflineAttendance,
    $$OfflineAttendancesTableFilterComposer,
    $$OfflineAttendancesTableOrderingComposer,
    $$OfflineAttendancesTableAnnotationComposer,
    $$OfflineAttendancesTableCreateCompanionBuilder,
    $$OfflineAttendancesTableUpdateCompanionBuilder,
    (
      OfflineAttendance,
      BaseReferences<_$OfflineDatabase, $OfflineAttendancesTable,
          OfflineAttendance>
    ),
    OfflineAttendance,
    PrefetchHooks Function()> {
  $$OfflineAttendancesTableTableManager(
      _$OfflineDatabase db, $OfflineAttendancesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineAttendancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineAttendancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineAttendancesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> clientUuid = const Value.absent(),
            Value<bool> isCheckIn = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<double> faceScoreLocal = const Value.absent(),
            Value<String?> faceImagePath = const Value.absent(),
            Value<int> elapsedRealtimeMillis = const Value.absent(),
            Value<int> anchorServerTimeMillis = const Value.absent(),
            Value<int> anchorElapsedMillis = const Value.absent(),
            Value<int> bootCount = const Value.absent(),
            Value<String?> deviceUid = const Value.absent(),
            Value<bool> isBackupDevice = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> syncAttempts = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastSyncAttempt = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
          }) =>
              OfflineAttendancesCompanion(
            id: id,
            clientUuid: clientUuid,
            isCheckIn: isCheckIn,
            latitude: latitude,
            longitude: longitude,
            faceScoreLocal: faceScoreLocal,
            faceImagePath: faceImagePath,
            elapsedRealtimeMillis: elapsedRealtimeMillis,
            anchorServerTimeMillis: anchorServerTimeMillis,
            anchorElapsedMillis: anchorElapsedMillis,
            bootCount: bootCount,
            deviceUid: deviceUid,
            isBackupDevice: isBackupDevice,
            isSynced: isSynced,
            syncAttempts: syncAttempts,
            createdAt: createdAt,
            lastSyncAttempt: lastSyncAttempt,
            syncError: syncError,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String clientUuid,
            required bool isCheckIn,
            required double latitude,
            required double longitude,
            required double faceScoreLocal,
            Value<String?> faceImagePath = const Value.absent(),
            required int elapsedRealtimeMillis,
            required int anchorServerTimeMillis,
            required int anchorElapsedMillis,
            required int bootCount,
            Value<String?> deviceUid = const Value.absent(),
            Value<bool> isBackupDevice = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> syncAttempts = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastSyncAttempt = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
          }) =>
              OfflineAttendancesCompanion.insert(
            id: id,
            clientUuid: clientUuid,
            isCheckIn: isCheckIn,
            latitude: latitude,
            longitude: longitude,
            faceScoreLocal: faceScoreLocal,
            faceImagePath: faceImagePath,
            elapsedRealtimeMillis: elapsedRealtimeMillis,
            anchorServerTimeMillis: anchorServerTimeMillis,
            anchorElapsedMillis: anchorElapsedMillis,
            bootCount: bootCount,
            deviceUid: deviceUid,
            isBackupDevice: isBackupDevice,
            isSynced: isSynced,
            syncAttempts: syncAttempts,
            createdAt: createdAt,
            lastSyncAttempt: lastSyncAttempt,
            syncError: syncError,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OfflineAttendancesTableProcessedTableManager = ProcessedTableManager<
    _$OfflineDatabase,
    $OfflineAttendancesTable,
    OfflineAttendance,
    $$OfflineAttendancesTableFilterComposer,
    $$OfflineAttendancesTableOrderingComposer,
    $$OfflineAttendancesTableAnnotationComposer,
    $$OfflineAttendancesTableCreateCompanionBuilder,
    $$OfflineAttendancesTableUpdateCompanionBuilder,
    (
      OfflineAttendance,
      BaseReferences<_$OfflineDatabase, $OfflineAttendancesTable,
          OfflineAttendance>
    ),
    OfflineAttendance,
    PrefetchHooks Function()>;
typedef $$ServerTimeAnchorsTableCreateCompanionBuilder
    = ServerTimeAnchorsCompanion Function({
  Value<int> id,
  required int serverTimeMillis,
  required int elapsedRealtimeMillis,
  required int bootCount,
  Value<DateTime> createdAt,
});
typedef $$ServerTimeAnchorsTableUpdateCompanionBuilder
    = ServerTimeAnchorsCompanion Function({
  Value<int> id,
  Value<int> serverTimeMillis,
  Value<int> elapsedRealtimeMillis,
  Value<int> bootCount,
  Value<DateTime> createdAt,
});

class $$ServerTimeAnchorsTableFilterComposer
    extends Composer<_$OfflineDatabase, $ServerTimeAnchorsTable> {
  $$ServerTimeAnchorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverTimeMillis => $composableBuilder(
      column: $table.serverTimeMillis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedRealtimeMillis => $composableBuilder(
      column: $table.elapsedRealtimeMillis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bootCount => $composableBuilder(
      column: $table.bootCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ServerTimeAnchorsTableOrderingComposer
    extends Composer<_$OfflineDatabase, $ServerTimeAnchorsTable> {
  $$ServerTimeAnchorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverTimeMillis => $composableBuilder(
      column: $table.serverTimeMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedRealtimeMillis => $composableBuilder(
      column: $table.elapsedRealtimeMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bootCount => $composableBuilder(
      column: $table.bootCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ServerTimeAnchorsTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $ServerTimeAnchorsTable> {
  $$ServerTimeAnchorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverTimeMillis => $composableBuilder(
      column: $table.serverTimeMillis, builder: (column) => column);

  GeneratedColumn<int> get elapsedRealtimeMillis => $composableBuilder(
      column: $table.elapsedRealtimeMillis, builder: (column) => column);

  GeneratedColumn<int> get bootCount =>
      $composableBuilder(column: $table.bootCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ServerTimeAnchorsTableTableManager extends RootTableManager<
    _$OfflineDatabase,
    $ServerTimeAnchorsTable,
    ServerTimeAnchor,
    $$ServerTimeAnchorsTableFilterComposer,
    $$ServerTimeAnchorsTableOrderingComposer,
    $$ServerTimeAnchorsTableAnnotationComposer,
    $$ServerTimeAnchorsTableCreateCompanionBuilder,
    $$ServerTimeAnchorsTableUpdateCompanionBuilder,
    (
      ServerTimeAnchor,
      BaseReferences<_$OfflineDatabase, $ServerTimeAnchorsTable,
          ServerTimeAnchor>
    ),
    ServerTimeAnchor,
    PrefetchHooks Function()> {
  $$ServerTimeAnchorsTableTableManager(
      _$OfflineDatabase db, $ServerTimeAnchorsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServerTimeAnchorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServerTimeAnchorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServerTimeAnchorsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> serverTimeMillis = const Value.absent(),
            Value<int> elapsedRealtimeMillis = const Value.absent(),
            Value<int> bootCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ServerTimeAnchorsCompanion(
            id: id,
            serverTimeMillis: serverTimeMillis,
            elapsedRealtimeMillis: elapsedRealtimeMillis,
            bootCount: bootCount,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int serverTimeMillis,
            required int elapsedRealtimeMillis,
            required int bootCount,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ServerTimeAnchorsCompanion.insert(
            id: id,
            serverTimeMillis: serverTimeMillis,
            elapsedRealtimeMillis: elapsedRealtimeMillis,
            bootCount: bootCount,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ServerTimeAnchorsTableProcessedTableManager = ProcessedTableManager<
    _$OfflineDatabase,
    $ServerTimeAnchorsTable,
    ServerTimeAnchor,
    $$ServerTimeAnchorsTableFilterComposer,
    $$ServerTimeAnchorsTableOrderingComposer,
    $$ServerTimeAnchorsTableAnnotationComposer,
    $$ServerTimeAnchorsTableCreateCompanionBuilder,
    $$ServerTimeAnchorsTableUpdateCompanionBuilder,
    (
      ServerTimeAnchor,
      BaseReferences<_$OfflineDatabase, $ServerTimeAnchorsTable,
          ServerTimeAnchor>
    ),
    ServerTimeAnchor,
    PrefetchHooks Function()>;

class $OfflineDatabaseManager {
  final _$OfflineDatabase _db;
  $OfflineDatabaseManager(this._db);
  $$OfflineAttendancesTableTableManager get offlineAttendances =>
      $$OfflineAttendancesTableTableManager(_db, _db.offlineAttendances);
  $$ServerTimeAnchorsTableTableManager get serverTimeAnchors =>
      $$ServerTimeAnchorsTableTableManager(_db, _db.serverTimeAnchors);
}
