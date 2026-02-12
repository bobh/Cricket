# Core Bluetooth Best Practices - Production-Ready Implementation Guide

**Purpose**: Reusable reference for implementing BLE in iOS/macOS projects
**Source**: Punch Through expert guide + Cricket project learnings
**Version**: 1.0 (February 2026)
**Use**: Include this prompt when starting any Core Bluetooth project

---

## 🎯 Quick Start Checklist

Before writing any BLE code, ensure:

- [ ] Info.plist contains required Bluetooth privacy keys
- [ ] CBCentralManager initialized with delegate
- [ ] All delegate methods implemented (not just happy path)
- [ ] Service UUIDs known and documented
- [ ] Peripheral retention strategy planned
- [ ] Error handling for all callbacks
- [ ] State management for all CBManagerState cases

---

## 📋 Info.plist Requirements

### iOS Projects
**Required Keys** (app will crash without these on iOS 13+):
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Your app needs Bluetooth access to connect to [device type] for [purpose].</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>Your app uses Bluetooth to communicate with [device type].</string>
```

### macOS Projects
**Required Keys**:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Your app needs Bluetooth access to connect to [device type] for [purpose].</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>Your app uses Bluetooth to communicate with [device type].</string>
```

### Background Mode (Optional)
If your app needs background BLE operations:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

**Warning**: Omitting these keys causes:
- iOS 13+: Immediate crash
- App Store: Rejection during review

---

## 🏗️ Architecture Pattern: ViewModel Approach

### Recommended Structure
```swift
import Foundation
import CoreBluetooth
import Combine

class BluetoothViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties (SwiftUI Integration)
    @Published var isScanning: Bool = false
    @Published var connectionStatus: String = "Disconnected"
    @Published var discoveredDevices: [DiscoveredPeripheral] = []

    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?

    // Service and Characteristic UUIDs
    private let serviceUUID = CBUUID(string: "YOUR-SERVICE-UUID")
    private let characteristicUUID = CBUUID(string: "YOUR-CHARACTERISTIC-UUID")

    // Stored characteristic references (avoid repeated searches)
    private var targetCharacteristic: CBCharacteristic?

    // Heartbeat timer (prevent 30-second auto-disconnect)
    private var heartbeatTimer: Timer?

    // MARK: - Initialization
    override init() {
        super.init()
        // Initialize on nil queue (uses main queue) or specify custom queue
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    deinit {
        stopHeartbeat()
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}
```

---

## 🔐 CRITICAL: Peripheral Retention Rules

### ❌ WRONG - Peripheral Will Be Deallocated
```swift
func centralManager(_ central: CBCentralManager,
                   didDiscover peripheral: CBPeripheral,
                   advertisementData: [String : Any],
                   rssi RSSI: NSNumber) {
    // BAD: No strong reference stored
    centralManager.connect(peripheral, options: nil)
    // Peripheral deallocated when function returns!
}
```

### ✅ CORRECT - Strong Reference Retained
```swift
private var discoveredPeripheral: CBPeripheral?

func centralManager(_ central: CBCentralManager,
                   didDiscover peripheral: CBPeripheral,
                   advertisementData: [String : Any],
                   rssi RSSI: NSNumber) {
    // GOOD: Store strong reference BEFORE connecting
    self.discoveredPeripheral = peripheral
    self.discoveredPeripheral?.delegate = self
    centralManager.connect(peripheral, options: nil)
}
```

**Rule**: Always store a strong reference to CBPeripheral before calling `connect()`.

---

## 📡 State Management (REQUIRED)

### ✅ Complete State Handling Pattern
```swift
extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectionStatus = "Ready to scan"
            // Safe to start scanning
            startScanning()

        case .poweredOff:
            connectionStatus = "Bluetooth is off - Enable in Settings"
            isScanning = false

        case .unauthorized:
            connectionStatus = "Bluetooth access denied - Check Privacy settings"
            isScanning = false
            // On iOS, direct user to Settings app
            // No programmatic way to re-request permission

        case .unsupported:
            connectionStatus = "Bluetooth Low Energy not supported on this device"
            isScanning = false

        case .resetting:
            connectionStatus = "Bluetooth is resetting..."
            isScanning = false

        case .unknown:
            connectionStatus = "Bluetooth state unknown"
            isScanning = false

        @unknown default:
            connectionStatus = "Unexpected Bluetooth state"
            isScanning = false
        }
    }
}
```

**Rule**: Handle ALL states, not just `.poweredOn`. Users need actionable guidance.

---

## 🔍 Scanning Best Practices

### ✅ ALWAYS Use Service Filtering
```swift
func startScanning() {
    guard centralManager.state == .poweredOn else { return }

    isScanning = true

    // ALWAYS filter by service UUID for power efficiency
    centralManager.scanForPeripherals(
        withServices: [serviceUUID],  // ← Never use nil in production
        options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ]
    )
}

func stopScanning() {
    centralManager.stopScan()
    isScanning = false
}
```

**Rules**:
- ✅ Always use `withServices: [yourServiceUUID]` for power efficiency
- ❌ Never use `withServices: nil` unless you have a very specific reason
- ❌ Avoid `CBCentralManagerScanOptionAllowDuplicatesKey: true` unless tracking RSSI changes

### Discovery Callback Pattern
```swift
func centralManager(_ central: CBCentralManager,
                   didDiscover peripheral: CBPeripheral,
                   advertisementData: [String: Any],
                   rssi RSSI: NSNumber) {

    // Create wrapper to store discovery data
    let discovered = DiscoveredPeripheral(
        peripheral: peripheral,
        rssi: RSSI,
        advertisementData: advertisementData
    )

    // Store in array (keeps strong reference)
    if !discoveredDevices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
        discoveredDevices.append(discovered)
    }

    // Auto-connect logic (optional)
    if shouldAutoConnect(peripheral, advertisementData: advertisementData) {
        connect(to: discovered)
    }
}
```

### Peripheral Wrapper Class (Recommended)
```swift
class DiscoveredPeripheral: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    var rssi: NSNumber
    var advertisementData: [String: Any]
    var lastSeen: Date

    init(peripheral: CBPeripheral, rssi: NSNumber, advertisementData: [String: Any]) {
        self.id = peripheral.identifier
        self.peripheral = peripheral
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.lastSeen = Date()
    }

    var name: String {
        peripheral.name ?? "Unknown Device"
    }

    var isConnectable: Bool {
        advertisementData[CBAdvertisementDataIsConnectable] as? Bool ?? true
    }
}
```

**Benefits**:
- Stores RSSI and advertisement data beyond discovery callback
- Easy to use in SwiftUI lists
- Maintains strong peripheral reference

---

## 🔌 Connection Management

### Connection Pattern
```swift
func connect(to discoveredPeripheral: DiscoveredPeripheral) {
    stopScanning()

    let peripheral = discoveredPeripheral.peripheral
    peripheral.delegate = self

    // Store reference BEFORE connecting
    self.connectedPeripheral = peripheral

    connectionStatus = "Connecting..."
    centralManager.connect(peripheral, options: nil)
}

func disconnect() {
    stopHeartbeat()

    if let peripheral = connectedPeripheral {
        centralManager.cancelPeripheralConnection(peripheral)
    }

    connectedPeripheral = nil
    connectionStatus = "Disconnected"
}
```

### Connection Callbacks
```swift
func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    connectionStatus = "Connected - Discovering services..."

    // Discover services (can filter by UUID or use nil for all)
    peripheral.discoverServices([serviceUUID])

    // Start heartbeat to prevent 30-second auto-disconnect
    startHeartbeat()
}

func centralManager(_ central: CBCentralManager,
                   didDisconnectPeripheral peripheral: CBPeripheral,
                   error: Error?) {
    stopHeartbeat()

    if let error = error {
        connectionStatus = "Disconnected: \(error.localizedDescription)"
    } else {
        connectionStatus = "Disconnected"
    }

    // Auto-reconnect logic (optional)
    if shouldAutoReconnect {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startScanning()
        }
    }
}

func centralManager(_ central: CBCentralManager,
                   didFailToConnect peripheral: CBPeripheral,
                   error: Error?) {
    connectionStatus = "Connection failed: \(error?.localizedDescription ?? "Unknown error")"

    // Retry logic with exponential backoff
    retryConnection(after: calculateBackoff())
}
```

---

## 🔧 Service & Characteristic Discovery

### Service Discovery
```swift
extension BluetoothViewModel: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Service discovery error: \(error.localizedDescription)")
            connectionStatus = "Service discovery failed"
            return
        }

        guard let services = peripheral.services else {
            connectionStatus = "No services found"
            return
        }

        for service in services {
            if service.uuid == serviceUUID {
                // Discover characteristics for target service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
}
```

### Characteristic Discovery
```swift
func peripheral(_ peripheral: CBPeripheral,
               didDiscoverCharacteristicsFor service: CBService,
               error: Error?) {
    if let error = error {
        print("❌ Characteristic discovery error: \(error.localizedDescription)")
        return
    }

    guard let characteristics = service.characteristics else {
        return
    }

    for characteristic in characteristics {
        // Store reference (avoid repeated UUID searches)
        if characteristic.uuid == characteristicUUID {
            self.targetCharacteristic = characteristic

            // Read initial value
            peripheral.readValue(for: characteristic)

            // Subscribe to notifications if characteristic supports it
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    connectionStatus = "Ready"
}
```

**Rule**: Store characteristic references during discovery to avoid repeated array searches.

---

## 📝 Reading & Writing Data

### Reading Values
```swift
func readValue() {
    guard let peripheral = connectedPeripheral,
          let characteristic = targetCharacteristic else {
        return
    }

    peripheral.readValue(for: characteristic)
}

func peripheral(_ peripheral: CBPeripheral,
               didUpdateValueFor characteristic: CBCharacteristic,
               error: Error?) {
    if let error = error {
        print("❌ Read error: \(error.localizedDescription)")
        return
    }

    guard let value = characteristic.value else {
        return
    }

    // Parse value based on your protocol
    parseValue(value, for: characteristic)
}
```

### Writing Values
```swift
func writeValue(_ data: Data, withResponse: Bool = true) {
    guard let peripheral = connectedPeripheral,
          let characteristic = targetCharacteristic else {
        return
    }

    let writeType: CBCharacteristicWriteType = withResponse ? .withResponse : .withoutResponse
    peripheral.writeValue(data, for: characteristic, type: writeType)
}

func peripheral(_ peripheral: CBPeripheral,
               didWriteValueFor characteristic: CBCharacteristic,
               error: Error?) {
    // Only called when using .withResponse
    if let error = error {
        print("❌ Write error: \(error.localizedDescription)")
    } else {
        print("✅ Write successful")
    }
}
```

**Write Types**:
- `.withResponse` - ACK required, triggers callback, slower but reliable
- `.withoutResponse` - Fire-and-forget, no callback, faster but no confirmation

---

## 💓 Heartbeat Pattern (Prevent Auto-Disconnect)

### Problem
iOS auto-disconnects after ~30 seconds of no BLE communication.

### Solution: Periodic Read
```swift
private var heartbeatTimer: Timer?
private let heartbeatInterval: TimeInterval = 20.0 // 20 seconds (safe margin)

func startHeartbeat() {
    stopHeartbeat()

    heartbeatTimer = Timer.scheduledTimer(
        withTimeInterval: heartbeatInterval,
        repeats: true
    ) { [weak self] _ in
        self?.sendHeartbeat()
    }
}

func stopHeartbeat() {
    heartbeatTimer?.invalidate()
    heartbeatTimer = nil
}

private func sendHeartbeat() {
    guard let peripheral = connectedPeripheral,
          let characteristic = targetCharacteristic else {
        return
    }

    // Simple read to keep connection alive
    peripheral.readValue(for: characteristic)
}
```

**Rule**: Always implement heartbeat for long-lived connections.

---

## 🔔 Notification Subscription

### Subscribe to Notifications
```swift
func subscribeToNotifications() {
    guard let peripheral = connectedPeripheral,
          let characteristic = targetCharacteristic,
          characteristic.properties.contains(.notify) else {
        return
    }

    peripheral.setNotifyValue(true, for: characteristic)
}

func peripheral(_ peripheral: CBPeripheral,
               didUpdateNotificationStateFor characteristic: CBCharacteristic,
               error: Error?) {
    if let error = error {
        print("❌ Notification subscription error: \(error.localizedDescription)")
        return
    }

    if characteristic.isNotifying {
        print("✅ Subscribed to notifications")
    } else {
        print("⚠️ Unsubscribed from notifications")
    }
}
```

**Important**: Use `setNotifyValue(_:for:)` method. Do NOT try to write the CCCD descriptor directly.

---

## ⚠️ Error Handling Patterns

### Never Silently Fail
```swift
// ❌ BAD
if error != nil {
    return
}

// ✅ GOOD
if let error = error {
    print("❌ Operation failed: \(error.localizedDescription)")
    connectionStatus = "Error: \(error.localizedDescription)"
    // Optionally: notify user, retry, or recover
    return
}
```

### Comprehensive Error Handling
```swift
func handleBLEError(_ error: Error, operation: String) {
    let errorMessage = "BLE Error (\(operation)): \(error.localizedDescription)"

    print("❌ \(errorMessage)")

    // Update UI
    connectionStatus = errorMessage

    // Log for debugging
    logError(errorMessage)

    // Attempt recovery if appropriate
    attemptRecovery(for: operation)
}
```

---

## 🧪 Testing Checklist

### Before Shipping
- [ ] Test with Bluetooth off → clear error message
- [ ] Test with permission denied → user directed to Settings
- [ ] Test with device out of range → graceful handling
- [ ] Test disconnect during operation → proper cleanup
- [ ] Test background operation (if enabled)
- [ ] Test low battery on peripheral → handle gracefully
- [ ] Test multiple connect/disconnect cycles → no memory leaks
- [ ] Test with multiple peripherals (if supported)

---

## 📊 Common Data Parsing Patterns

### Integer Values (16-bit)
```swift
func parseInt16(from data: Data) -> Int16? {
    guard data.count >= 2 else { return nil }
    return data.withUnsafeBytes { $0.load(as: Int16.self) }
}
```

### Float Values (32-bit IEEE 754)
```swift
func parseFloat32(from data: Data) -> Float? {
    guard data.count == 4 else { return nil }
    let value = data.withUnsafeBytes { $0.load(as: Float.self) }
    guard value.isFinite else { return nil } // Check for NaN/Infinity
    return value
}
```

### String Values
```swift
func parseString(from data: Data) -> String? {
    return String(data: data, encoding: .utf8)
}
```

### Custom Structures
```swift
struct SensorReading {
    let temperature: Float
    let humidity: Float
    let timestamp: UInt32

    init?(from data: Data) {
        guard data.count == 12 else { return nil } // 4 + 4 + 4 bytes

        temperature = data[0..<4].withUnsafeBytes { $0.load(as: Float.self) }
        humidity = data[4..<8].withUnsafeBytes { $0.load(as: Float.self) }
        timestamp = data[8..<12].withUnsafeBytes { $0.load(as: UInt32.self) }

        guard temperature.isFinite && humidity.isFinite else { return nil }
    }
}
```

---

## 🎯 Performance Optimization

### Do's ✅
- Use service filtering in `scanForPeripherals`
- Store characteristic references after discovery
- Batch operations when possible
- Use `.withoutResponse` writes for high-frequency data
- Implement connection parameter optimization (if needed)

### Don'ts ❌
- Don't scan with `withServices: nil` unless necessary
- Don't enable `CBCentralManagerScanOptionAllowDuplicatesKey` unnecessarily
- Don't poll characteristics rapidly (use notifications instead)
- Don't keep scanning when connected
- Don't forget to stop scanning when no longer needed

---

## 🔒 Security Considerations

### Bonding & Pairing
```swift
// Note: iOS handles bonding automatically
// No direct API for bonding control

func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    // Bonding happens here if peripheral requires it
    // Use encrypted characteristics as a workaround to detect bonding
}
```

### Data Validation
```swift
func parseAndValidate(_ data: Data) -> SensorReading? {
    guard let reading = SensorReading(from: data) else {
        print("⚠️ Invalid data format")
        return nil
    }

    // Validate ranges
    guard reading.temperature >= -40 && reading.temperature <= 125 else {
        print("⚠️ Temperature out of valid range")
        return nil
    }

    guard reading.humidity >= 0 && reading.humidity <= 100 else {
        print("⚠️ Humidity out of valid range")
        return nil
    }

    return reading
}
```

---

## 📱 iOS vs macOS Differences

### iOS Specific
- Background BLE requires `UIBackgroundModes` in Info.plist
- Limited background execution time
- State restoration for background apps
- More aggressive power management

### macOS Specific
- No background mode restrictions
- Can run BLE indefinitely in foreground
- Different permission prompts
- Sandboxing considerations for Mac App Store

### Unified Code Pattern
```swift
#if os(iOS)
    // iOS-specific code
    UIApplication.shared.open(settingsURL)
#elseif os(macOS)
    // macOS-specific code
    NSWorkspace.shared.open(settingsURL)
#endif
```

---

## 🚀 Production Deployment Checklist

### Before App Store Submission
- [ ] Info.plist privacy keys present and descriptive
- [ ] All CBCentralManager states handled
- [ ] Error messages user-friendly (not technical)
- [ ] Memory leaks tested (Instruments)
- [ ] Background mode tested (if enabled)
- [ ] Works on both iPhone and iPad (if universal)
- [ ] Works on both Intel and Apple Silicon Macs (if macOS)
- [ ] Tested with real hardware (not just simulator)
- [ ] Tested with device out of range scenarios
- [ ] Tested with low battery peripherals

---

## 📚 Quick Reference: Common Mistakes

| Mistake | Fix |
|---------|-----|
| Scanning with `withServices: nil` | Always filter by service UUID |
| Not retaining peripheral reference | Store in property before `connect()` |
| Only handling `.poweredOn` state | Handle all states with switch |
| Silent error handling | Always log and display errors |
| No heartbeat mechanism | Implement 20-second read timer |
| Searching for characteristics by UUID repeatedly | Store references after discovery |
| Forgetting to stop scanning | Stop scan when connected or no longer needed |
| Not setting peripheral delegate | Set delegate before connecting |
| Writing CCCD descriptor directly | Use `setNotifyValue(_:for:)` |
| No connection timeout | Implement timeout with timer |

---

## 🎓 Further Learning

### Official Documentation
- [Core Bluetooth Programming Guide](https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/)
- [CBCentralManager Documentation](https://developer.apple.com/documentation/corebluetooth/cbcentralmanager)
- [CBPeripheral Documentation](https://developer.apple.com/documentation/corebluetooth/cbperipheral)

### Expert Resources
- [Punch Through Core Bluetooth Guide](https://punchthrough.com/core-bluetooth-guide/)
- WWDC Sessions on Core Bluetooth
- Bluetooth SIG Specifications

---

## 💡 Template: Minimal Working Example

```swift
import CoreBluetooth

class MinimalBLEManager: NSObject, ObservableObject {
    @Published var status: String = "Initializing..."

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?

    private let serviceUUID = CBUUID(string: "YOUR-SERVICE-UUID")
    private let charUUID = CBUUID(string: "YOUR-CHAR-UUID")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension MinimalBLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        peripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([serviceUUID])
    }
}

extension MinimalBLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else { return }
        peripheral.discoverCharacteristics([charUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let char = service.characteristics?.first(where: { $0.uuid == charUUID }) else { return }
        self.characteristic = char
        peripheral.setNotifyValue(true, for: char)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        // Process data here
    }
}
```

---

## 📝 Usage Instructions

### When Starting a New BLE Project

1. **Copy this file** to your project repository
2. **Include in Claude prompt**: "Follow Core Bluetooth best practices from CORE_BLUETOOTH_BEST_PRACTICES.md"
3. **Reference during code review**: Check implementation against this guide
4. **Update as needed**: Add project-specific patterns

### Integration with Claude

**Prompt Template**:
```
I'm building a [iOS/macOS] app that connects to a BLE device for [purpose].

Read /path/to/CORE_BLUETOOTH_BEST_PRACTICES.md and follow all patterns:
- Service UUID: [YOUR-UUID]
- Characteristic UUIDs: [LIST]
- Data format: [DESCRIPTION]

Implement a production-ready BluetoothViewModel with:
- Complete state handling
- Service filtering
- Heartbeat mechanism
- Error handling
- Characteristic caching
```

---

**Document Version**: 1.0
**Last Updated**: February 12, 2026
**Tested With**: iOS 26.0+, macOS 26.0+
**Based On**: Cricket project + Punch Through expert guide

---

*Keep this document updated as you learn new patterns from production BLE projects.* 🎯
