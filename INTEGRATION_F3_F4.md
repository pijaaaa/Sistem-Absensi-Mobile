# Integration F3 + F4 - Offline Mode Complete

## Status: ✅ SELESAI

Attendance flow sekarang **fully support offline mode** dengan auto-sync.

## Changes Summary

### 1. ✅ Updated: `attendance_flow_screen.dart`

**Method `_submitAttendance()` - Smart Online/Offline Branch:**

```dart
// Check connectivity
final offlineService = ref.read(offlineAttendanceServiceProvider);
final isOnline = await offlineService.isOnline();

if (isOnline) {
  // Online: submit langsung ke API (existing F3 logic)
  final result = await flowService.submitAttendance(...);
} else {
  // Offline: save ke database lokal (new F4 logic)
  final uuid = await offlineService.saveOfflineAttendance(
    isCheckIn: widget.isCheckIn,
    lat: lat,
    lng: lng,
    faceScore: faceScore,
    faceImageBytes: _capturedImageBytes,
  );
  
  // Return success dengan flag is_offline
  _attendanceResult = AttendanceResult(
    success: true,
    data: {
      'message': 'Absensi tersimpan offline',
      'time': DateTime.now().toString().substring(11, 16),
      'status': 'Akan disinkronkan otomatis',
      'is_offline': true,
    },
  );
}
```

**Result Screen - Offline UI:**
- Icon: `cloud_off` (orange) jika offline, `check_circle` (hijau) jika online
- Title: "Tersimpan Offline" vs "Absensi Berhasil!"
- Info box orange dengan pesan: "Data akan disinkronkan otomatis saat terhubung ke internet"
- Waktu ditampilkan, status hanya tampil jika online

### 2. ✅ Auto-Sync Flow

**User Journey:**

1. **Offline Attendance:**
   - User buka attendance flow
   - GPS check → OK
   - Face verification → OK
   - Submit → detect offline
   - **Save to local database** (elapsed-realtime, anchor, face image)
   - Show "Tersimpan Offline" dengan icon cloud_off

2. **Auto-Sync (Background):**
   - User kembali ke home
   - **Badge muncul**: "Offline: 1 menunggu sync"
   - Workmanager running setiap 15 menit
   - Saat online → **auto-sync ke server**
   - Server time calculated dari anchor + elapsed-realtime
   - Success → badge hilang

3. **Manual Sync (Optional):**
   - User tap badge offline
   - Dialog "Sync Data Offline"
   - Tap "Sync Sekarang"
   - **Immediate sync** via one-time workmanager
   - Success message → dialog close

### 3. ✅ Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    ATTENDANCE FLOW                          │
└─────────────────────────────────────────────────────────────┘
                            │
                    Check Connectivity
                            │
                ┌───────────┴───────────┐
                │                       │
            [ONLINE]               [OFFLINE]
                │                       │
                │                       │
        ┌───────▼────────┐      ┌──────▼──────┐
        │  Direct API    │      │  Save Local │
        │  check-in/out  │      │  Database   │
        └───────┬────────┘      └──────┬──────┘
                │                       │
                │                       │
        ┌───────▼────────┐      ┌──────▼──────────────┐
        │  Show Result   │      │  Encrypted Face Img │
        │  (success/     │      │  + Elapsed-realtime │
        │   late status) │      │  + Anchor Data      │
        └────────────────┘      └──────┬──────────────┘
                                       │
                                       │
                            ┌──────────▼─────────────┐
                            │  Background Workmanager│
                            │  (Every 15 min)        │
                            └──────────┬─────────────┘
                                       │
                                       │ [When Online]
                                       │
                            ┌──────────▼─────────────┐
                            │ Calculate Server Time  │
                            │ from Anchor + Elapsed  │
                            └──────────┬─────────────┘
                                       │
                            ┌──────────▼─────────────┐
                            │ POST /sync-offline     │
                            │ (client_uuid, time,    │
                            │  is_suspect, etc)      │
                            └──────────┬─────────────┘
                                       │
                            ┌──────────▼─────────────┐
                            │ Mark as Synced         │
                            │ Delete Face Image      │
                            │ Update Badge Count     │
                            └────────────────────────┘
```

## Testing Scenarios

### ✅ Scenario 1: Normal Offline → Auto-Sync
1. **Setup**: Matikan wifi/data
2. **Action**: Lakukan absen masuk
3. **Expected Result**:
   - ✅ Lokasi checked (GPS tetap jalan offline)
   - ✅ Face verified
   - ✅ Result screen: icon cloud_off (orange)
   - ✅ Title: "Tersimpan Offline"
   - ✅ Info box: "Data akan disinkronkan otomatis..."
   - ✅ Waktu ditampilkan (device time)
4. **Back to Home**:
   - ✅ Badge muncul: "Offline: 1 menunggu sync"
5. **Turn On Wifi**:
   - ✅ Dalam 15 menit, badge hilang (synced)
   - ✅ Check backend: data masuk dengan calculated server time

### ✅ Scenario 2: Manual Sync
1. **With pending offline data**
2. **Tap offline badge**
3. **Dialog opens**: "Ada 1 absensi offline yang belum tersinkron"
4. **Tap "Sync Sekarang"**
5. **Expected**:
   - ✅ Loading indicator
   - ✅ Success message: "Berhasil sync 1, gagal 0"
   - ✅ Dialog auto-close setelah 2 detik
   - ✅ Badge hilang dari home

### ✅ Scenario 3: Online (Normal Flow)
1. **Setup**: Wifi/data ON
2. **Action**: Lakukan absen masuk
3. **Expected Result**:
   - ✅ Direct API call (no database save)
   - ✅ Result screen: icon check_circle (hijau)
   - ✅ Title: "Absensi Berhasil!"
   - ✅ Status dari backend: "Tepat Waktu" / "Telat 5 menit"
   - ✅ NO offline badge

### ✅ Scenario 4: Device Restart (Suspect Flag)
1. **Offline absen** → get anchor (boot_count = 5)
2. **Restart device** (boot_count = 6)
3. **Device online** → auto-sync
4. **Expected**:
   - ✅ `is_suspect = true` sent to backend
   - ✅ Backend flags for review (B7)
   - ✅ Sync still success, marked as synced

### ✅ Scenario 5: Connection Lost Mid-Flow
1. **Start absen** dengan wifi ON
2. **Location check** → OK
3. **Matikan wifi** sebelum submit
4. **Face verify** → OK
5. **Submit** → detect offline
6. **Expected**:
   - ✅ Graceful fallback ke offline mode
   - ✅ Save to database
   - ✅ Show "Tersimpan Offline"

## Technical Details

### Offline Save Process
```dart
// 1. Get/Create anchor
final anchor = await offlineService.getOrCreateAnchor();

// 2. Capture elapsed-realtime
final elapsedMillis = await elapsedTimeService.getElapsedRealtimeMillis();
final bootCount = await elapsedTimeService.getBootCount();

// 3. Save face image encrypted
final faceImagePath = await _saveFaceImage(uuid, imageBytes);

// 4. Insert to database
await database.addOfflineAttendance(
  clientUuid: uuid,
  isCheckIn: true,
  latitude: lat,
  longitude: lng,
  faceScoreLocal: faceScore,
  faceImagePath: faceImagePath,
  elapsedRealtimeMillis: elapsedMillis,
  anchorServerTimeMillis: anchor.serverTimeMillis,
  anchorElapsedMillis: anchor.elapsedRealtimeMillis,
  bootCount: bootCount,
);
```

### Sync Process
```dart
// 1. Get pending from database
final pending = await database.getPendingAttendances();

// 2. For each attendance:
for (final attendance in pending) {
  // Calculate server time
  final timeResult = await elapsedTimeService.calculateServerTime(
    anchorServerTimeMillis: attendance.anchorServerTimeMillis,
    anchorElapsedMillis: attendance.anchorElapsedMillis,
    anchorBootCount: attendance.bootCount,
  );
  
  // Call API
  await repository.syncOfflineAttendance(
    clientUuid: attendance.clientUuid,
    calculatedServerTimeMillis: timeResult.calculatedServerTimeMillis,
    isSuspect: timeResult.isSuspect,
    ...
  );
  
  // Mark synced
  await database.markAsSynced(attendance.clientUuid);
  
  // Delete face image
  await _deleteFaceImage(attendance.faceImagePath);
}
```

## Benefits

✅ **Seamless UX**: User tidak perlu tahu tentang online/offline, app handle automatically

✅ **Data Integrity**: Elapsed-realtime ensures accurate timestamp even if device clock changed

✅ **Reliability**: Auto-retry dengan exponential backoff, background workmanager

✅ **Transparency**: Badge shows pending count, manual sync available

✅ **Security**: Face image encrypted, auto-deleted after sync

✅ **Efficiency**: Old synced data auto-purged (>7 hari)

## Files Modified

- `lib/features/attendance/presentation/screens/attendance_flow_screen.dart`
  - Updated `_submitAttendance()` - online/offline branch
  - Updated `_buildResultStep()` - offline UI variant

## Build Status

✅ No compilation errors
✅ All dependencies resolved
✅ Ready for testing

## Next Steps

**Current Progress: F0 → U0 → U1 → F1 → F2 (partial) → F3 → F4 → ✅ F3+F4 Integrated**

**Remaining Milestones:**
- **F5** - Device Utama & Cadangan (device binding, approval)
- **F6** - Pengajuan & Approval (connect UI to API)
- **F7** - Ringkasan, Statistik, Notifikasi
- **F8** - Hardening & Rilis

**Ready to continue? Pick next:**
1. **F5** - Device binding (1 device utama, 1 cadangan, approval)
2. **F6** - Pengajuan (cuti/sakit/izin/dinas) + approval manager
