# Bluetooth Pendant System - Complete Documentation

## Overview

The Sikizwa system includes a **Bluetooth Low Energy (BLE) smart pendant** that provides emergency SOS functionality. The pendant wirelessly connects to the mobile app via Bluetooth, and when activated by the user, it triggers an emergency distress signal with real-time location tracking.

---

## 1. Phone Permissions Required

### Bluetooth Permissions (Required)
- **`bluetooth_scan`** - Permission to scan for nearby Bluetooth devices
- **`bluetooth_connect`** - Permission to establish Bluetooth connections with pendant devices

### Location Permissions (Required)
- **`location_when_in_use`** (Primary) - Access to GPS location while the app is in use
- **`location`** (Fallback) - General location access

### How Permissions Work
All permissions are requested together when the user initiates pendant operations:

```dart
// From ble_service.dart
final statuses = await [
  Permission.bluetoothScan,
  Permission.bluetoothConnect,
  Permission.locationWhenInUse,
  Permission.location,
].request();
```

If **any required permission is denied**, the system throws an error:
- Missing Bluetooth permissions → `"Bluetooth permissions are required to use the pendant."`
- Missing location permissions → `"Location permission is required to scan for the pendant."`

---

## 2. Pendant Pairing Process

### Step 1: Scanning for Devices
**File**: [lib/src/features/pendant/pendant_pairing_screen.dart](lib/src/features/pendant/pendant_pairing_screen.dart)

1. User taps **"Scan pendants"** button
2. System requests all required permissions
3. Scans for BLE devices within range for **8 seconds** (default timeout)
4. Discovers devices broadcasting as pendant devices
5. Displays list of found devices to user

```dart
Future<void> scanForDevices({Duration timeout = const Duration(seconds: 8)}) async {
  await _ensurePermissions();
  final foundDevices = <String, BluetoothDevice>{};
  
  await FlutterBluePlus.startScan(timeout: timeout);
  await Future<void>.delayed(timeout);
  await FlutterBluePlus.stopScan();
}
```

### Step 2: Connecting to a Pendant
**File**: [lib/src/services/pendant_connection_manager.dart](lib/src/services/pendant_connection_manager.dart)

1. User selects a pendant from the scanned list
2. App attempts to connect with **15-second timeout**
3. System discovers Bluetooth services and characteristics
4. Looks for a characteristic with **notify** or **indicate** properties (SOS characteristic)
5. Enables notifications on the characteristic
6. Saves pendant as "trusted" in local storage (`SharedPreferences`)
7. Registers the pendant with the backend server

```dart
Future<void> connectToDevice(BluetoothDevice device) async {
  await bleService.connect(device);  // 15-second timeout
  await _saveTrustedPendant(device.remoteId.str);  // Save locally
  unawaited(_syncTrustedPendant(device));  // Register with backend
  await _startPacketListener(device.remoteId.str);  // Listen for SOS packets
}
```

### Step 3: Auto-Reconnection
When the app restarts, it automatically reconnects to the saved pendant:

1. Checks local storage for saved pendant ID
2. Scans for 6 seconds to find the saved device nearby
3. If found, automatically reconnects
4. If not found, stores error state: `"Reconnecting to pendant failed."`

---

## 3. Pendant Trust System

### Backend Trust Validation
**File**: [backend/api-server/src/controllers/pendantEmergencyController.js](backend/api-server/src/controllers/pendantEmergencyController.js)

When a pendant SOS is triggered, the backend **validates that the pendant is trusted**:

```javascript
function isTrustedPendant(user, pendantId) {
  const trustedPendants = Array.isArray(user?.metadata?.trustedPendants)
    ? user.metadata.trustedPendants
    : [];

  return trustedPendants.some((entry) => {
    if (typeof entry === 'string') {
      return entry === pendantId;
    }
    return entry.pendantId === pendantId;
  });
}
```

**Security**: Users can only trigger SOS from pendants they have paired. Random pendant IDs are rejected with:
```
Status: 403 Forbidden
Error: "trusted pendant validation failed"
Code: "PENDANT_NOT_TRUSTED"
```

---

## 4. SOS Trigger Flow

### Step 1: Physical Button Press (Pendant Hardware)
1. User presses the SOS button on the physical pendant device
2. Pendant sends an emergency packet via Bluetooth

### Step 2: Packet Reception & Parsing
**File**: [lib/src/services/pendant_connection_manager.dart](lib/src/services/pendant_connection_manager.dart)

The app listens for incoming packets on the notify characteristic:

```dart
Future<void> _startPacketListener(String deviceId) async {
  _packetSubscription = bleService.packetStream.listen((packet) async {
    final parsed = _parseSosPacket(packet);
    if (parsed == null) return;
    
    await sosService.activateFromPendant(
      pendantId: deviceId,
      batteryLevel: parsed['batteryLevel'] ?? 100,
    );
  });
}
```

### Packet Format Detection
The app looks for SOS trigger keywords in the packet:

```dart
Map<String, dynamic>? _parseSosPacket(List<int> packet) {
  final decoded = String.fromCharCodes(packet).trim();
  final lower = decoded.toLowerCase();
  
  // Checks for: "sos", "panic", "emergency"
  if (!lower.contains('sos') && 
      !lower.contains('panic') && 
      !lower.contains('emergency')) {
    return null;  // Not a trigger packet
  }
  
  // Try to parse as JSON to get battery level
  try {
    final json = jsonDecode(decoded);
    return json as Map<String, dynamic>;
  } catch (_) {
    return {'batteryLevel': 100};  // Default if not valid JSON
  }
}
```

### Step 3: Location Capture & SOS Activation
**File**: [lib/src/services/emergency_sos_service.dart](lib/src/services/emergency_sos_service.dart)

```dart
Future<void> activateFromPendant({
  required String pendantId,
  required int batteryLevel,
}) async {
  // 1. Check for duplicate triggers (within 15 seconds)
  if (_lastTriggerAt != null &&
      now.difference(_lastTriggerAt!).inSeconds < 15 &&
      state.value.isActive) {
    return;  // Suppress duplicate trigger
  }

  // 2. Check internet connectivity
  final connectivity = await Connectivity().checkConnectivity();
  if (connectivity.contains(ConnectivityResult.none)) {
    throw StateError('No internet connection...');
  }

  // 3. Extract user ID from JWT token
  final userId = await _extractUserId();

  // 4. Get current GPS location
  final position = await _getCurrentPosition();

  // 5. Build SOS payload
  final payload = {
    'userId': userId,
    'pendantId': pendantId,
    'latitude': position.latitude,
    'longitude': position.longitude,
    'timestamp': now.toIso8601String(),
    'batteryLevel': batteryLevel,
  };

  // 6. Send to backend
  await api.post('/api/emergency/pendant-sos', data: payload);

  // 7. Enable screen lock (prevent accidental dismissal)
  await WakelockPlus.enable();

  // 8. Vibrate phone for user feedback
  HapticFeedback.vibrate();

  // 9. Start continuous location updates every 5 seconds
  _startLocationUpdates(pendantId: pendantId, userId: userId);
}
```

---

## 5. Duplicate Prevention

The system prevents accidental multiple SOS triggers:

```javascript
// Backend checks for duplicate within 15 seconds
const recentSignal = await DistressSignal.findOne({
  user: req.user._id,
  pendantId: parsedPendantId,
  source: 'BLE_PENDANT',
  status: 'active',
  createdAt: { $gte: new Date(Date.now() - 15 * 1000) }
}).sort({ createdAt: -1 });

if (recentSignal) {
  return res.json(buildSuccessResponse({
    duplicate: true,
    message: 'Duplicate pendant SOS request suppressed.'
  }));
}
```

---

## 6. Real-Time Location Tracking

### Continuous Updates During Emergency
Once SOS is triggered, the app sends location updates **every 5 seconds**:

```dart
void _startLocationUpdates({
  required String pendantId,
  required String userId,
}) {
  _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
    try {
      final position = await _getCurrentPosition();
      await api.post('/api/emergency/location-update', data: {
        'userId': userId,
        'pendantId': pendantId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Transient errors don't stop location updates
    }
  });
}
```

### Location Accuracy
```dart
locationSettings: const LocationSettings(
  accuracy: LocationAccuracy.best,  // Uses GPS only
  timeLimit: Duration(seconds: 10),  // 10-second timeout
)
```

### GPS Requirements
Before location is captured:

1. **Check GPS enabled**: `Geolocator.isLocationServiceEnabled()`
2. **Request permission** if needed
3. **Get best accuracy position** from GPS
4. **Error handling**: If GPS is disabled → `"GPS is unavailable. Please enable location services..."`

---

## 7. Backend SOS Processing

### Initial SOS Creation
**File**: [backend/api-server/src/controllers/pendantEmergencyController.js](backend/api-server/src/controllers/pendantEmergencyController.js)

```javascript
async function createPendantSOS(req, res) {
  // 1. Validate userId is valid MongoDB ObjectId
  // 2. Verify userId matches authenticated user (security)
  // 3. Validate pendant is trusted
  // 4. Parse and validate coordinates (lat: -90 to 90, lng: -180 to 180)
  // 5. Validate timestamp is not in future
  // 6. Validate battery level (0-100)
  // 7. Check for recent duplicate (15-second window)
  // 8. Create DistressSignal document

  const signal = await DistressSignal.create({
    user: req.user._id,
    lat: parsedLat,
    lng: parsedLng,
    timestamp: parsedTimestamp,
    status: 'active',
    severity: 'critical',
    isLockedModeActive: true,
    source: 'BLE_PENDANT',
    pendantId: parsedPendantId,
    batteryLevel: parsedBatteryLevel,
  });

  // 9. Broadcast to emergency monitoring dashboard via WebSocket
  broadcastDistressSignal(signal);

  return res.status(201).json(buildSuccessResponse({...}, 'Pendant SOS created successfully.'));
}
```

### Location Update Handler
```javascript
async function updatePendantLocation(req, res) {
  // 1. Same validations as SOS creation
  // 2. Find existing active distress signal for this user/pendant
  // 3. If exists: update location and timestamp
  // 4. If not exists: create new signal (fallback)
  // 5. Broadcast update via WebSocket with isLiveUpdate: true

  signal.lat = parsedLat;
  signal.lng = parsedLng;
  signal.timestamp = parsedTimestamp;
  await signal.save();

  broadcastDistressSignal(signal, true);  // true = live update flag
}
```

---

## 8. Real-Time Broadcasting (WebSocket)

The emergency monitoring dashboard receives live updates:

```javascript
function broadcastDistressSignal(signal, isLiveUpdate = false) {
  const io = getSocket();
  
  io.to('emergency-monitoring').emit('distress_signal', {
    id: signal._id,
    user_id: signal.user.toString(),
    lat: signal.lat,
    lng: signal.lng,
    timestamp: signal.timestamp,
    severity: signal.severity,
    status: signal.status,
    isLockedModeActive: signal.isLockedModeActive,
    source: signal.source,
    pendantId: signal.pendantId,
    batteryLevel: signal.batteryLevel,
    isLiveUpdate,  // Indicates if this is a location update vs initial SOS
  });
}
```

**Broadcasting happens**:
- ✅ On initial SOS creation
- ✅ On each location update (every 5 seconds)
- ✅ Real-time dashboard monitoring through WebSockets

---

## 9. Emergency Resolution

### App Side
```dart
Future<void> resolveEmergency() async {
  _locationUpdateTimer?.cancel();  // Stop location updates
  _locationUpdateTimer = null;
  await WakelockPlus.disable();  // Release screen lock
  
  state.value = state.value.copyWith(
    isActive: false,
    statusMessage: 'Emergency mode resolved. The pendant is still connected.',
  );
}
```

### Backend (Must be called by admin/responder)
The distress signal status is updated from `'active'` to `'resolved'` (not shown in provided code, but follows same pattern).

---

## 10. Connection States & Status Messages

### Mobile App States

| State | Message | Behavior |
|-------|---------|----------|
| Disconnected | "No pendant connected." | Idle state |
| Scanning | "Scanning for nearby pendants..." | Device discovery in progress |
| Connecting | "Connecting to [device name]..." | BLE connection establishing |
| Connected | "Connected to [device name]." | Ready for SOS triggers |
| Reconnecting | "Reconnecting to pendant..." | Auto-reconnect to saved device |
| SOS Active | "Pendant SOS sent. Live location updates are active." | Emergency mode active |
| SOS Resolved | "Emergency mode resolved. The pendant is still connected." | Emergency handled |

### Error States
- Connection failed: `"Failed to connect to the pendant."`
- No SOS characteristic: `"The pendant is not advertising a supported SOS characteristic."`
- Pendant not found: `"Saved pendant is not nearby."`
- Reconnection failed: `"Reconnecting to pendant failed."`

---

## 11. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    PENDANT HARDWARE                              │
│  [SOS Button] → Sends BLE Packet (SOS + Battery Level)           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ↓ Bluetooth Connection
┌─────────────────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter)                          │
│                                                                  │
│  BLEService                                                      │
│  ├─ Scan for devices (flashcards bluetooth)                      │
│  ├─ Connect to device                                            │
│  └─ Listen to notify characteristic                              │
│                    ↓                                             │
│  PendantConnectionManager                                        │
│  ├─ Parse SOS packets                                            │
│  ├─ Manage connection state                                      │
│  └─ Save trusted pendant locally                                 │
│                    ↓                                             │
│  EmergencySOSService                                             │
│  ├─ Validate trigger (duplicate prevention)                      │
│  ├─ Get GPS location                                             │
│  ├─ Extract user ID from JWT token                               │
│  ├─ POST /api/emergency/pendant-sos                              │
│  └─ START periodic location updates (5sec)                       │
│      └─ POST /api/emergency/location-update (every 5 sec)        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ↓ HTTPS API Calls
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND (Node.js)                           │
│                                                                  │
│  PendantEmergency Routes                                         │
│  ├─ POST /api/emergency/pendant-sos                              │
│  └─ POST /api/emergency/location-update                          │
│                    ↓                                             │
│  PendantEmergency Controller                                     │
│  ├─ Validate user authentication                                 │
│  ├─ Verify pendant is trusted                                    │
│  ├─ Check for duplicate (15-second window)                       │
│  ├─ Parse & validate coordinates & timestamp                     │
│  └─ Create/Update DistressSignal in MongoDB                      │
│                    ↓                                             │
│  DistressSignal Collection (MongoDB)                             │
│  └─ Store emergency with full location history                   │
│                    ↓                                             │
│  WebSocket Broadcast (Socket.io)                                 │
│  └─ Emit to 'emergency-monitoring' room                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│            ADMIN DASHBOARD (Real-time updates)                   │
│  ├─ Receives initial SOS event                                   │
│  ├─ Receives location updates (every 5 seconds)                  │
│  ├─ Shows live position on map                                   │
│  ├─ Shows battery level                                          │
│  └─ Can mark as resolved                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 12. Security Features

### 1. **Authentication**
- All endpoints require `requireAuth` middleware
- User ID extracted from JWT token

### 2. **Trust Validation**
- Only registered (trusted) pendants can trigger SOS
- Backend validates pendant ID against user's `metadata.trustedPendants`

### 3. **User Ownership**
- Users can only trigger SOS from their own account
- `userId` must match authenticated user: `userId !== req.user._id.toString()` → 403 Forbidden

### 4. **Coordinate Validation**
- Latitude: -90 to 90
- Longitude: -180 to 180
- Invalid coordinates rejected

### 5. **Timestamp Validation**
- Must be valid ISO 8601 format
- Cannot be more than 5 minutes in future (prevents spoofing)
- Must be parseable date

### 6. **Rate Limiting**
- `emergencyLimiter` middleware prevents abuse
- `idempotencyMiddleware(30)` prevents duplicate processing within 30 seconds

### 7. **Duplicate Prevention**
- 15-second window for duplicate detection
- Prevents accidental double-SOS triggers

---

## 13. Error Handling

### Client-Side
- Bluetooth permission denial → Operation blocked
- Location permission denial → Operation blocked
- No internet connection → SOS fails with error
- GPS disabled → Location capture fails
- Device not found → Reconnection fails
- Connection timeout (15 sec) → Connection fails

### Server-Side
| Status | Scenario |
|--------|----------|
| 400 | Missing required fields, invalid coordinates, invalid timestamp, invalid battery level |
| 403 | User mismatch, pendant not trusted, user unauthorized |
| 500 | Database error, unexpected server error |

All errors include:
- `statusCode` - HTTP status
- `message` - Human-readable error
- `errorCode` - Machine-readable error code (e.g., `PENDANT_NOT_TRUSTED`)

---

## 14. Battery Level Tracking

### From Pendant
- Extracted from BLE packet during SOS trigger
- Defaults to 100% if not provided in packet

### Stored in Database
- Each distress signal records the battery level at trigger time
- Helps responders understand device status

### Display
- Shown in emergency dashboard
- Helps with resource allocation

---

## 15. Testing Considerations

### What to Test
1. ✅ Bluetooth scan finds devices
2. ✅ Connection establishes within timeout
3. ✅ Auto-reconnection works
4. ✅ SOS packet parsing (handles different formats)
5. ✅ Duplicate prevention (15-second window)
6. ✅ Location capture (GPS timeout, accuracy)
7. ✅ Backend trust validation
8. ✅ WebSocket broadcasting to dashboard
9. ✅ Location updates every 5 seconds
10. ✅ Emergency resolution stops location tracking

---

## Summary

The Bluetooth pendant system is a **complete emergency response solution** that:

1. 📱 **Pairs** wirelessly with the mobile app via BLE
2. 🔐 **Validates** that only trusted pendants can trigger SOS
3. 🆘 **Triggers** emergency through physical button press
4. 📍 **Tracks** location in real-time (every 5 seconds)
5. 🚨 **Broadcasts** to emergency monitoring dashboard
6. 🔒 **Secures** against unauthorized access
7. ⏱️ **Prevents** duplicate triggers
8. 🌐 **Requires** Bluetooth + Location permissions
9. 📶 **Maintains** connection even after app restart
10. 🎯 **Provides** complete audit trail in database

