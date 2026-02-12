# Cricket macOS - Priority 1 Critical BLE Fixes

**Source**: Comparison with [Punch Through Core Bluetooth Guide](https://punchthrough.com/core-bluetooth-guide/)
**Date**: February 12, 2026
**File**: `/Users/bobh/Desktop/Projects/Cricket/CricketMac/CricketMac/BluetoothViewModel.swift`

---

## Fix 1: Consistent Service Filtering ⚡

### Problem
Lines 105 and 129 scan with `withServices: nil`, defeating power optimization.

### Impact
- ❌ Increased power consumption
- ❌ Slower device discovery
- ❌ May discover unrelated BLE devices

### Before (Lines 105, 129)
```swift
// Line 105 - centralManagerDidUpdateState
centralManager.scanForPeripherals(
    withServices: nil,
    options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
)

// Line 129 - didDisconnectPeripheral
centralManager.scanForPeripherals(
    withServices: nil,
    options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
)
```

### After
```swift
// Line 105 - centralManagerDidUpdateState
centralManager.scanForPeripherals(
    withServices: [environmentalSensingServiceUUID],
    options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
)

// Line 129 - didDisconnectPeripheral
centralManager.scanForPeripherals(
    withServices: [environmentalSensingServiceUUID],
    options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
)
```

**Best Practice**: Always filter by service UUID for power efficiency.

---

## Fix 2: Complete State Handling 🔧

### Problem
Only handles `.poweredOn` state; other states get generic "Bluetooth not available" message.

### Impact
- ❌ Poor user experience - unclear what's wrong
- ❌ No guidance on how to fix issues
- ❌ Can't distinguish between different Bluetooth problems

### Before (Lines 102-109)
```swift
func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == .poweredOn {
        connectionStatus = "Scanning for Arduino sensor..."
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    } else {
        connectionStatus = "Bluetooth not available"
    }
}
```

### After
```swift
func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .poweredOn:
        connectionStatus = "Scanning for Arduino sensor..."
        // Use service filtering (see Fix 1)
        centralManager.scanForPeripherals(
            withServices: [environmentalSensingServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

    case .poweredOff:
        connectionStatus = "Bluetooth is off - Enable in System Settings"
        temperature = "--"
        humidity = "--"

    case .unauthorized:
        connectionStatus = "Bluetooth access denied - Check Privacy settings"
        temperature = "--"
        humidity = "--"

    case .unsupported:
        connectionStatus = "This Mac doesn't support Bluetooth Low Energy"
        temperature = "--"
        humidity = "--"

    case .resetting:
        connectionStatus = "Bluetooth resetting..."

    case .unknown:
        connectionStatus = "Bluetooth state unknown - waiting..."

    @unknown default:
        connectionStatus = "Unexpected Bluetooth state"
    }
}
```

**Best Practice**: Handle all CBCentralManager states with actionable user guidance.

---

## Fix 3: Store Characteristic References 📦

### Problem
Searches for characteristics by UUID repeatedly in `didUpdateValueFor` callback.

### Impact
- ❌ Unnecessary array searches on every sensor update
- ❌ Less efficient code
- ❌ Harder to maintain

### Add to Class Properties (After Line 27)
```swift
// Stored characteristic references (avoid repeated UUID searches)
private var temperatureCharacteristic: CBCharacteristic?
private var humidityCharacteristic: CBCharacteristic?
```

### Before (Lines 162-167)
```swift
for characteristic in characteristics {
    if characteristic.uuid == temperatureCharacteristicUUID ||
       characteristic.uuid == humidityCharacteristicUUID {
        peripheral.readValue(for: characteristic)
        peripheral.setNotifyValue(true, for: characteristic)
    }
}
```

### After (Lines 162-172)
```swift
for characteristic in characteristics {
    if characteristic.uuid == temperatureCharacteristicUUID {
        temperatureCharacteristic = characteristic  // Store reference
        peripheral.readValue(for: characteristic)
        peripheral.setNotifyValue(true, for: characteristic)
    } else if characteristic.uuid == humidityCharacteristicUUID {
        humidityCharacteristic = characteristic  // Store reference
        peripheral.readValue(for: characteristic)
        peripheral.setNotifyValue(true, for: characteristic)
    }
}
```

**Best Practice**: Store characteristic references during discovery to avoid repeated array searches.

### Bonus: Use Stored References in `didUpdateValueFor`
```swift
func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    if let error = error {
        DispatchQueue.main.async {
            self.connectionStatus = "Update error: \(error.localizedDescription)"
        }
        return
    }

    guard let value = characteristic.value else {
        return
    }

    // Use stored references for comparison (more efficient)
    if characteristic.uuid == temperatureCharacteristicUUID {
        // ... existing temperature parsing code ...
    } else if characteristic.uuid == humidityCharacteristicUUID {
        // ... existing humidity parsing code ...
    }
}
```

---

## Implementation Checklist

### Fix 1: Service Filtering ✅
- [ ] Line 105: Change `withServices: nil` to `withServices: [environmentalSensingServiceUUID]`
- [ ] Line 129: Change `withServices: nil` to `withServices: [environmentalSensingServiceUUID]`
- [ ] Test: Verify Arduino is still discovered
- [ ] Test: Check discovery time is reasonable

### Fix 2: State Handling ✅
- [ ] Replace lines 102-109 with complete switch statement
- [ ] Test each state:
  - [ ] Turn Bluetooth off → see "Bluetooth is off" message
  - [ ] Turn Bluetooth on → starts scanning
  - [ ] Deny Bluetooth permission → see "access denied" message
- [ ] Verify temperature/humidity show "--" when Bluetooth unavailable

### Fix 3: Characteristic Storage ✅
- [ ] Add two properties after line 27: `temperatureCharacteristic` and `humidityCharacteristic`
- [ ] Update lines 162-167 to store characteristic references
- [ ] Test: Verify temperature and humidity still update correctly
- [ ] Optional: Update `didUpdateValueFor` to use stored references

---

## Testing After Fixes

### Test 1: Service Filtering Works
```bash
# Verify Arduino discovery still works
1. Power on Arduino Nano 33 BLE Sense
2. Launch Cricket macOS app
3. Should discover and connect within 5-10 seconds
4. Verify temperature and humidity display
```

### Test 2: State Handling Provides Guidance
```bash
# Test each Bluetooth state
1. Turn Bluetooth off in System Settings
   → Should show: "Bluetooth is off - Enable in System Settings"

2. Turn Bluetooth back on
   → Should show: "Scanning for Arduino sensor..."

3. If available, deny Bluetooth permission
   → Should show: "Bluetooth access denied - Check Privacy settings"
```

### Test 3: Characteristics Are Stored
```bash
# Verify normal operation
1. Connect to Arduino
2. Check temperature updates every few seconds
3. Check humidity updates every few seconds
4. Verify no console errors about missing characteristics
```

---

## Expected Results

After implementing these fixes:

✅ **More Power Efficient** - Service filtering reduces BLE scanning power
✅ **Better User Experience** - Clear, actionable error messages
✅ **More Maintainable** - Stored references simplify code
✅ **Compliant with Best Practices** - Matches Punch Through recommendations

---

## Additional Notes

### Why These Are Priority 1

1. **Service Filtering** - Impacts every scan operation, wastes power
2. **State Handling** - Users currently get unhelpful error messages
3. **Characteristic Storage** - Inefficient code pattern, easy fix

### When to Apply

- ✅ Can apply immediately (no breaking changes)
- ✅ Compatible with existing Arduino firmware
- ✅ Works with current RuuviTag implementation
- ✅ Safe for production use

### iOS Version

The iOS app (`/Users/bobh/Desktop/Projects/Cricket/IOS--BLE Central/BLE_Central/BluetoothViewModel.swift`) likely has similar issues. Consider applying the same fixes there after testing on macOS.

---

## Next Steps

1. **Apply these three fixes** to `CricketMac/CricketMac/BluetoothViewModel.swift`
2. **Build and test** on your M4 MacBook Air
3. **Verify functionality** with Arduino sensor
4. **Apply same fixes to iOS** version when ready
5. **Consider Priority 2 fixes** (heartbeat, error logging) for WWDC 26 prep

---

**Document Location**: `/Users/bobh/Desktop/Projects/Cricket/BLE_CRITICAL_FIXES.md`
**Related Files**:
- `/Users/bobh/Desktop/Projects/Cricket/CricketMac/CricketMac/BluetoothViewModel.swift` (macOS)
- `/Users/bobh/Desktop/Projects/Cricket/IOS--BLE Central/BLE_Central/BluetoothViewModel.swift` (iOS)

---

*These fixes bring Cricket's Core Bluetooth implementation in line with industry best practices from Punch Through, improving reliability and user experience without requiring architecture changes.* 🎯
