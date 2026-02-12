# Arduino BLE Signal Loss Detection, Recovery & Cleanup Analysis
**Project:** Cricket iOS & macOS
**Component:** BluetoothViewModel (Arduino BLE Connection Mode)
**Analysis Date:** 2025-10-25

---

## Overview

Cricket's Arduino BLE implementation uses **connection-based detection** (not advertisement-based like RuuviTag). The Arduino establishes a persistent BLE connection and streams temperature/humidity data via characteristic notifications.

**Key Characteristics:**
- Connection-based (not scan-based)
- Notification-driven data updates
- Automatic reconnection on disconnect
- No active signal strength monitoring

---

## 1. Signal Loss Detection

### **Primary Detection Method: CoreBluetooth Disconnect Events**

**Location:** iOS: `BluetoothViewModel.swift:146-155` | macOS: Identical

```swift
func centralManager(_ central: CBCentralManager,
                   didDisconnectPeripheral peripheral: CBPeripheral,
                   error: Error?) {
    NSLog("[BLE] ❌ Disconnected from peripheral: %@", peripheral.identifier.uuidString)
    if let error = error {
        NSLog("[BLE] Disconnect error: %@", error.localizedDescription)
    }
    connectionStatus = "Disconnected"
    // Automatically try to reconnect
    NSLog("[BLE] Attempting to reconnect...")
    centralManager.scanForPeripherals(withServices: nil,
        options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
}
```

**How It Works:**
1. iOS/macOS CoreBluetooth monitors the BLE connection
2. When Arduino goes out of range or powers off, CoreBluetooth detects radio silence
3. After CoreBluetooth's internal timeout (typically 6-30 seconds), disconnect callback fires
4. Cricket receives notification via delegate method
5. Status updated to "Disconnected"

**Detection Latency:**
- ⏱️ **6-30 seconds** before disconnect is detected
- Depends on CoreBluetooth's internal supervision timeout
- NOT configurable at application level
- User sees "Connected to Arduino" status until timeout expires

---

### **What Cricket Does NOT Detect**

❌ **No Active Signal Strength Monitoring:**
- No RSSI checking while connected
- No "weak signal" warnings
- No gradual degradation detection

❌ **No Data Freshness Monitoring:**
- No timer checking when last update received
- If Arduino freezes (still connected but not sending data), Cricket won't detect
- Relies entirely on CoreBluetooth disconnect events

❌ **No Characteristic Update Timeout:**
- No detection if notifications stop coming
- Could appear "connected" with stale data

**Code Evidence:**
```swift
// Line 214-265: didUpdateValueFor characteristic
func peripheral(_ peripheral: CBPeripheral,
               didUpdateValueFor characteristic: CBCharacteristic,
               error: Error?) {
    // Updates temperature/humidity when received
    // Updates lastUpdated timestamp
    // NO checking of time since last update
}
```

**Comparison to RuuviTag:**
| Feature | Arduino BLE | RuuviTag |
|---------|-------------|----------|
| Detection Method | CoreBluetooth disconnect | Timer-based (5s checks) |
| Detection Latency | 6-30 seconds | 10 seconds (configurable) |
| Active Monitoring | ❌ No | ✅ Yes |
| Stale Data Detection | ❌ No | ✅ Yes (via timer) |
| Battery Impact | Low (passive) | Medium (timer) |

---

## 2. Recovery Mechanisms

Cricket has **THREE recovery mechanisms** triggered by different failure scenarios:

---

### **Mechanism A: Disconnect Recovery**

**Trigger:** Arduino goes out of range or powers off
**Location:** `BluetoothViewModel.swift:146-155`

```swift
func centralManager(_ central: CBCentralManager,
                   didDisconnectPeripheral peripheral: CBPeripheral,
                   error: Error?) {
    connectionStatus = "Disconnected"
    // RECOVERY: Restart scanning
    centralManager.scanForPeripherals(withServices: nil,
        options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
}
```

**Recovery Flow:**
1. CoreBluetooth detects disconnect (6-30 second latency)
2. Cricket updates status to "Disconnected"
3. Immediately starts **broad scan** (all devices, no service filter)
4. When Arduino re-appears, discovery callback fires
5. Cricket connects automatically (lines 122-138)

**Issues:**
- ⚠️ **Scans ALL devices** (no service filter on line 154)
- ⚠️ **No delay** before retry (immediate rescan)
- ⚠️ **Loses peripheral reference** - must rediscover from scratch
- ⚠️ **No exponential backoff** - could drain battery if Arduino stays off

---

### **Mechanism B: Connection Failure Recovery**

**Trigger:** Connection attempt fails (Arduino not responding, BLE error, etc.)
**Location:** `BluetoothViewModel.swift:157-167`

```swift
func centralManager(_ central: CBCentralManager,
                   didFailToConnect peripheral: CBPeripheral,
                   error: Error?) {
    NSLog("[BLE] ❌ Failed to connect to peripheral: %@", peripheral.identifier.uuidString)
    connectionStatus = "Connection failed"
    // RECOVERY: Wait 2 seconds, then try scanning again
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self.startScanning()
    }
}
```

**Recovery Flow:**
1. Connection attempt fails
2. Wait **2 seconds** (exponential backoff? No, just fixed delay)
3. Call `startScanning()` which checks Bluetooth state
4. If Bluetooth powered on, restarts scan

**Advantages:**
- ✅ Has delay (2 seconds) to avoid tight retry loop
- ✅ Checks Bluetooth state before scanning

**Issues:**
- ⚠️ Fixed 2-second delay (not adaptive)
- ⚠️ **No maximum retry limit** - will retry forever
- ⚠️ **No user notification** after multiple failures

---

### **Mechanism C: Bluetooth Power Cycle Recovery**

**Trigger:** User turns Bluetooth off then back on
**Location:** `BluetoothViewModel.swift:86-100`

```swift
func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == .poweredOn {
        connectionStatus = "Scanning for Arduino sensor..."
        NSLog("[BLE] ✅ Bluetooth is POWERED ON")
        // RECOVERY: Restart scanning
        centralManager.scanForPeripherals(withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    } else {
        connectionStatus = "Bluetooth not available"
    }
}
```

**Recovery Flow:**
1. User turns Bluetooth off → state changes to `.poweredOff`
2. Status updates to "Bluetooth not available"
3. User turns Bluetooth on → state changes to `.poweredOn`
4. Cricket immediately starts scanning
5. Automatic reconnection when Arduino found

**Advantages:**
- ✅ Automatic recovery without user action
- ✅ Clean state reset

**Issues:**
- ⚠️ **No state preservation** - doesn't remember last connected device
- ⚠️ **Broad scan** (all devices) instead of targeted reconnect

---

### **What Recovery Does NOT Include**

❌ **No iOS Background State Restoration:**
```swift
// MISSING: No CBCentralManagerOptionRestoreIdentifierKey in init
centralManager = CBCentralManager(delegate: self, queue: nil)
// Should be:
// centralManager = CBCentralManager(delegate: self, queue: nil,
//     options: [CBCentralManagerOptionRestoreIdentifierKey: "com.cricket.ble"])
```
- If iOS terminates app, connection is permanently lost
- User must manually reopen app to reconnect

❌ **No Peripheral Caching:**
```swift
// Line 14: Single peripheral reference
private var discoveredPeripheral: CBPeripheral?

// MISSING: No UUID persistence
// Could use: @AppStorage("lastArduinoUUID") private var lastArduinoUUID: String?
```
- Doesn't remember last connected Arduino UUID
- Can't do targeted reconnection with `retrievePeripherals(withIdentifiers:)`

❌ **No Connection Timeout:**
```swift
// Line 132: Connection with no timeout
centralManager.connect(peripheral, options: nil)

// MISSING: No timeout monitoring
// Should track connection attempt time and cancel after N seconds
```
- Connection attempts can hang indefinitely
- No "Connection timeout" error for user

---

## 3. Memory Management & Cleanup

### **Resource Tracking**

**State Variables:**
```swift
// Line 13-14: Core state
private var centralManager: CBCentralManager!
private var discoveredPeripheral: CBPeripheral?

// Line 8-11: Published UI state
@Published var temperature: String = "--"
@Published var humidity: String = "--"
@Published var connectionStatus: String = "Disconnected"
@Published var lastUpdated: Date? = nil
```

**Lifecycle Management:**
```swift
// Line 26-38: Initialization
override init() {
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: nil)
    loadStoredValues()
}

// MISSING: No deinit method
// Should cleanup: centralManager, peripheral, stop scanning
```

---

### **Memory Leak Prevention**

✅ **Good Practices Found:**

1. **Weak Self in Closures:**
```swift
// Line 63-70: Scan timeout closure
DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
    guard let self = self else { return }
    // Safe: Won't retain self
}

// Line 164-166: Retry closure
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    self.startScanning()  // ⚠️ Missing [weak self]!
}
```

2. **Delegate Pattern:**
```swift
// Lines 5, 26-38: Proper delegate setup
class BluetoothViewModel: NSObject, ..., CBCentralManagerDelegate, CBPeripheralDelegate
// self is delegate of centralManager and peripheral
```

⚠️ **Potential Issues:**

1. **Strong Reference to CBPeripheral:**
```swift
// Line 14: Strong reference
private var discoveredPeripheral: CBPeripheral?

// Line 129: Stores peripheral
discoveredPeripheral = peripheral
discoveredPeripheral?.delegate = self

// CONCERN: Circular reference?
// peripheral -> delegate (self) -> discoveredPeripheral -> peripheral
// MITIGATED: CBPeripheralDelegate is a protocol, delegate property is weak
```

2. **Missing Cleanup on Disconnect:**
```swift
// Line 146-155: Disconnect handler
func centralManager(_ central: CBCentralManager,
                   didDisconnectPeripheral peripheral: CBPeripheral,
                   error: Error?) {
    connectionStatus = "Disconnected"
    // MISSING: No cleanup of discoveredPeripheral reference
    // Should: discoveredPeripheral = nil
}
```

3. **No Scan Stop Guarantee:**
```swift
// MISSING: No explicit scan stop on deinit
// If ViewModel deallocates while scanning, scan may continue
```

---

### **Cleanup Checklist**

| Resource | Created | Cleaned Up | Notes |
|----------|---------|------------|-------|
| `centralManager` | Line 35 | ❌ Never | Implicit ARC cleanup only |
| `discoveredPeripheral` | Line 128 | ❌ Never | Not nil'd on disconnect |
| Active BLE scan | Lines 60, 95, 154, 159 | ✅ On discovery (line 126) | Not stopped on deinit |
| Peripheral delegate | Line 129 | ❌ Never | Not unset on disconnect |
| DispatchQueue closures | Lines 63, 164 | ✅ Auto (weak self) | Line 164 missing weak! |

---

### **Recommended Cleanup Code (NOT IMPLEMENTED)**

```swift
deinit {
    NSLog("[BLE] BluetoothViewModel deallocating - cleaning up")

    // Stop scanning
    centralManager?.stopScan()

    // Disconnect if connected
    if let peripheral = discoveredPeripheral,
       peripheral.state == .connected || peripheral.state == .connecting {
        centralManager?.cancelPeripheralConnection(peripheral)
    }

    // Clear references
    discoveredPeripheral?.delegate = nil
    discoveredPeripheral = nil
    centralManager = nil
}
```

**Why This Matters:**
- App switching: ViewModel may deallocate/reallocate
- Memory pressure: iOS may terminate app
- Testing: Creating/destroying ViewModels in tests

---

## 4. Data Persistence & Recovery

### **UserDefaults Persistence**

**Saved Data:**
```swift
// Lines 45-54: saveValues() method
UserDefaults.standard.set(temperature, forKey: "currentTemperature")
UserDefaults.standard.set(humidity, forKey: "currentHumidity")
UserDefaults.standard.set(connectionStatus, forKey: "connectionStatus")

sharedDefaults?.set(temperature, forKey: "temperature")
sharedDefaults?.set(humidity, forKey: "humidity")
```

**Loaded Data:**
```swift
// Lines 40-43: loadStoredValues() method
temperature = sharedDefaults?.string(forKey: "temperature") ?? "--"
humidity = sharedDefaults?.string(forKey: "humidity") ?? "--"
// Note: connectionStatus NOT loaded (always starts "Disconnected")
```

**What IS Persisted:**
- ✅ Last known temperature value
- ✅ Last known humidity value

**What is NOT Persisted:**
- ❌ Arduino peripheral UUID (for fast reconnect)
- ❌ Connection state (always starts disconnected)
- ❌ Last update timestamp
- ❌ Discovery state

**Impact:**
- User sees last values immediately on app launch
- Must wait for reconnection to get fresh data
- No indication values are stale

---

## 5. User Experience Flow

### **Scenario A: Normal Operation**

```
1. App Launch
   ├─ BluetoothViewModel.init() (Line 26)
   ├─ Load last values from UserDefaults (Line 40)
   ├─ Create CBCentralManager (Line 35)
   └─ Status: "Disconnected"

2. ContentView.onAppear (ContentView.swift:262)
   └─ Calls bluetoothViewModel.startScanning() (Line 56)

3. Bluetooth Powered On
   └─ centralManagerDidUpdateState() (Line 86)
      └─ Starts scanning for Arduino (Line 95)
      └─ Status: "Scanning for Arduino sensor..."

4. Arduino Discovered
   └─ didDiscover() callback (Line 102)
      ├─ Logs discovery details (Lines 103-119)
      ├─ Stops scan (Line 126)
      ├─ Stores peripheral reference (Line 128)
      ├─ Sets delegate (Line 129)
      └─ Connects (Line 132)
      └─ Status: "Connecting to Arduino..."

5. Connection Established
   └─ didConnect() callback (Line 139)
      ├─ Discovers services (Line 143)
      └─ Status: "Connected to Arduino"

6. Services Discovered
   └─ didDiscoverServices() (Line 169)
      └─ Discovers characteristics (Line 184)

7. Characteristics Discovered
   └─ didDiscoverCharacteristicsFor() (Line 188)
      ├─ Reads initial value (Line 207)
      └─ Enables notifications (Line 209)

8. Data Updates Arrive
   └─ didUpdateValueFor() (Line 214)
      ├─ Parses temperature/humidity (Lines 232-264)
      ├─ Updates @Published properties (Lines 236, 252)
      ├─ Updates lastUpdated timestamp (Lines 237, 253)
      ├─ Saves to UserDefaults (Lines 239, 255)
      └─ Status: "Connected to Arduino"

9. UI Refreshes Automatically
   └─ SwiftUI observes @Published changes
      └─ ContentView updates display
```

**Total Time to First Data:** ~5-15 seconds
- Bluetooth initialization: 1-2 seconds
- Discovery: 1-5 seconds
- Connection: 1-3 seconds
- Service/characteristic discovery: 1-3 seconds
- First notification: 1-2 seconds

---

### **Scenario B: Signal Loss & Recovery**

```
1. Arduino Goes Out of Range
   └─ [6-30 second delay while CoreBluetooth detects]

2. CoreBluetooth Disconnect Detected
   └─ didDisconnectPeripheral() (Line 146)
      ├─ Logs disconnect (Lines 147-150)
      ├─ Status: "Disconnected"
      └─ Immediately starts broad scan (Line 154)

3. Scanning for Arduino
   └─ Status shows "Disconnected"
   └─ Last values still displayed (from UserDefaults)
   └─ No indication values are stale

4. Arduino Returns to Range
   └─ didDiscover() callback fires (Line 102)
      └─ [Repeat steps 4-9 from Scenario A]

5. Reconnected
   └─ Fresh data starts flowing
   └─ Status: "Connected to Arduino"
```

**Recovery Time:** 5-15 seconds after Arduino returns
**Total Downtime:** 11-45 seconds (6-30s detection + 5-15s reconnection)

---

### **Scenario C: Connection Failure**

```
1. Connection Attempt Fails
   └─ didFailToConnect() (Line 157)
      ├─ Logs error (Lines 158-161)
      ├─ Status: "Connection failed"
      └─ Waits 2 seconds (Line 164)

2. Retry After Delay
   └─ Calls startScanning() (Line 165)
      └─ If Bluetooth on: restarts scan
      └─ If Bluetooth off: shows error

3. Loop Until Success
   └─ Will retry indefinitely
   └─ No maximum retry count
   └─ No backoff strategy
```

---

### **Scenario D: Bluetooth Power Cycle**

```
1. User Turns Bluetooth Off
   └─ centralManagerDidUpdateState() (Line 86)
      ├─ State: .poweredOff
      └─ Status: "Bluetooth not available"

2. [App continues running with stale data]

3. User Turns Bluetooth On
   └─ centralManagerDidUpdateState() (Line 86)
      ├─ State: .poweredOn
      ├─ Status: "Scanning for Arduino sensor..."
      └─ Starts broad scan (Line 95)

4. Arduino Discovered & Connected
   └─ [Same as Scenario A, steps 4-9]
```

**Recovery Time:** Automatic, 5-15 seconds after Bluetooth enabled

---

## 6. Comparison: Current vs BTKit Architecture

### **Signal Loss Detection**

| Aspect | Current Cricket | BTKit Approach |
|--------|----------------|----------------|
| **Detection Method** | CoreBluetooth disconnect event | Disconnect event + connection state tracking |
| **Detection Latency** | 6-30 seconds (system controlled) | 6-30 seconds + configurable timeout |
| **Active Monitoring** | None | Connection health checks available |
| **Timeout Configuration** | Not configurable | `.connectionTimeout(seconds)` |

### **Recovery Mechanisms**

| Aspect | Current Cricket | BTKit Approach |
|--------|----------------|----------------|
| **Reconnection Strategy** | Full device scan | Cached peripheral direct connect |
| **Retry Logic** | Immediate (no delay) | Automatic with state tracking |
| **Backoff Strategy** | None (except 2s on failure) | Built-in intelligent retry |
| **State Restoration** | None | iOS background mode support |
| **BT Power Cycle** | Manual scan restart | Automatic with peripheral cache |

### **Memory Management**

| Aspect | Current Cricket | BTKit Approach |
|--------|----------------|----------------|
| **Peripheral Reference** | Strong, never cleaned | Managed internally |
| **Cleanup on Disconnect** | None | Automatic |
| **deinit Implementation** | Missing | Proper cleanup |
| **Weak References** | Mostly correct | Consistently correct |

---

## 7. Identified Issues & Limitations

### **Critical Issues** 🔴

1. **No Connection Timeout**
   - Connection attempts can hang indefinitely
   - User sees "Connecting..." with no escape

2. **Circular Reference Risk**
   - `discoveredPeripheral?.delegate = self` creates potential cycle
   - Mitigated by weak delegate property, but risky

3. **Missing deinit Cleanup**
   - Active scans may continue after ViewModel deallocation
   - Peripheral delegate not unset

### **Moderate Issues** 🟡

4. **Inefficient Recovery**
   - Broad scan (all devices) instead of targeted reconnect
   - No peripheral UUID caching

5. **No Maximum Retry Limit**
   - Will retry forever if Arduino stays off
   - Battery drain potential

6. **Stale Data Not Indicated**
   - Last values displayed after disconnect
   - No "Last updated X seconds ago" indication

7. **Long Detection Latency**
   - 6-30 seconds before disconnect detected
   - User sees "Connected" with no updates

### **Minor Issues** 🟢

8. **Inconsistent Weak Self**
   - Line 164: Missing `[weak self]`
   - Could cause reference retention

9. **No iOS State Restoration**
   - Connection lost if app terminated
   - Requires manual app reopen

10. **No User Feedback for Repeated Failures**
    - Silent infinite retries
    - No "Unable to connect after N attempts" message

---

## 8. Strengths of Current Implementation

### **What Cricket Does Well** ✅

1. **Simple & Understandable**
   - Straightforward CoreBluetooth usage
   - Easy to debug with extensive logging
   - Clear state flow

2. **Automatic Reconnection**
   - Doesn't require manual user action
   - Handles common failure scenarios

3. **Data Persistence**
   - Last values preserved across app launches
   - Good for quick app switching

4. **Clean Architecture**
   - ViewModel pattern
   - SwiftUI reactive updates
   - Separation of concerns

5. **Robust Parsing**
   - IEEE 754 float parsing
   - NaN/Infinity checking (Lines 273, 278, 282, 287)
   - Data validation

6. **Cross-Platform**
   - Identical iOS and macOS implementations
   - Easy to maintain

---

## 9. Summary

### **Signal Loss Detection**
- ✅ **Method:** CoreBluetooth disconnect events (passive)
- ⏱️ **Latency:** 6-30 seconds (system controlled)
- ❌ **Active Monitoring:** None
- ❌ **Stale Data Detection:** None

### **Recovery Mechanisms**
- ✅ **Disconnect Recovery:** Automatic scan restart
- ✅ **Connection Failure:** 2-second retry
- ✅ **BT Power Cycle:** Automatic rescan
- ❌ **State Restoration:** Not implemented
- ❌ **Peripheral Caching:** Not implemented

### **Cleanup**
- ⚠️ **Memory Management:** Mostly good (weak self in most closures)
- ❌ **Missing deinit:** No explicit cleanup
- ❌ **Peripheral Reference:** Not nil'd on disconnect
- ⚠️ **Scan Cleanup:** Not stopped on deallocation

### **Overall Assessment**

**Grade:** 🟡 **B- (Good but Improvable)**

**Strengths:**
- Functional and reliable for common scenarios
- Simple architecture, easy to maintain
- Automatic reconnection works

**Weaknesses:**
- Long disconnect detection latency (6-30s)
- Inefficient recovery (broad scan vs cached reconnect)
- Missing deinit cleanup
- No connection timeout
- No maximum retry limit

**Verdict:**
- ✅ **Adequate for current Cricket needs**
- ⚠️ **BTKit would improve efficiency and reliability**
- 🎯 **Recommended: Keep as-is per project decision**

---

## Appendix: Code References

### **Key Methods**

| Method | Line (iOS) | Purpose |
|--------|------------|---------|
| `init()` | 26-38 | Initialize ViewModel, create CBCentralManager |
| `startScanning()` | 56-75 | Manually trigger scan |
| `centralManagerDidUpdateState()` | 86-100 | Handle BT state changes |
| `didDiscover()` | 102-137 | Handle discovered peripherals |
| `didConnect()` | 139-144 | Handle successful connection |
| `didDisconnectPeripheral()` | 146-155 | **Recovery Mechanism A** |
| `didFailToConnect()` | 157-167 | **Recovery Mechanism B** |
| `didDiscoverServices()` | 169-186 | Discover characteristics |
| `didDiscoverCharacteristicsFor()` | 188-212 | Enable notifications |
| `didUpdateValueFor()` | 214-265 | Parse sensor data |
| `parseTemperature()` | 268-275 | IEEE 754 parsing |
| `parseHumidity()` | 277-284 | IEEE 754 parsing |

**macOS Version:** Identical implementation

---

*Analysis completed: 2025-10-25*
*Status: Current implementation documented*
*Recommendation: Adequate for current needs; defer BTKit integration*
