# Code Changes for Dual-Sensor Logging

## Goal
Enable both Arduino and RuuviTag to write data to UserDefaults simultaneously, allowing automated calibration logging.

---

## Current Problem

**Current Code:**
```swift
// In saveValues() method:
guard isActiveSource else { return }  // ❌ Only active sensor writes
```

**Result**: Only ONE sensor writes to UserDefaults at a time.

**Solution**: Both sensors always write, using unique keys.

---

## Changes Required

### File 1: `CricketMac/CricketMac/BluetoothViewModel.swift`

**Location**: Lines 61-78 (saveValues method)

**Current Code:**
```swift
private func saveValues() {
    // Only save to UserDefaults if this is the active sensor source
    guard isActiveSource else { return }  // ❌ REMOVE THIS LINE

    // Save to standard UserDefaults for App Intents access
    UserDefaults.standard.set(temperature, forKey: "currentTemperature")
    UserDefaults.standard.set(humidity, forKey: "currentHumidity")
    UserDefaults.standard.set(connectionStatus, forKey: "connectionStatus")
    UserDefaults.standard.synchronize()

    // Also save to shared defaults for widgets
    sharedDefaults?.set(temperature, forKey: "temperature")
    sharedDefaults?.set(humidity, forKey: "humidity")
    sharedDefaults?.synchronize()

    // Donate intents to Apple Intelligence for pattern learning
    donateIntents()
}
```

**New Code:**
```swift
private func saveValues() {
    // ALWAYS save Arduino data with unique keys for calibration logging
    // Active sensor still writes to generic keys for UI/intents

    // Save Arduino-specific data (always)
    UserDefaults.standard.set(temperature, forKey: "arduino_temperature")
    UserDefaults.standard.set(humidity, forKey: "arduino_humidity")
    UserDefaults.standard.set(connectionStatus, forKey: "arduino_status")
    UserDefaults.standard.set(Date(), forKey: "arduino_lastUpdated")

    // Only save to generic keys if active sensor (for UI/intents)
    if isActiveSource {
        UserDefaults.standard.set(temperature, forKey: "currentTemperature")
        UserDefaults.standard.set(humidity, forKey: "currentHumidity")
        UserDefaults.standard.set(connectionStatus, forKey: "connectionStatus")

        // Also save to shared defaults for widgets
        sharedDefaults?.set(temperature, forKey: "temperature")
        sharedDefaults?.set(humidity, forKey: "humidity")
        sharedDefaults?.synchronize()

        // Donate intents only for active sensor
        donateIntents()
    }

    UserDefaults.standard.synchronize()
}
```

---

### File 2: `CricketMac/CricketMac/RuuviTagViewModel.swift`

**Location**: Lines ~130-155 (saveValues method - similar to BluetoothViewModel)

**Find the saveValues() method and apply the same pattern:**

**New Code:**
```swift
private func saveValues() {
    // ALWAYS save RuuviTag data with unique keys for calibration logging

    // Save RuuviTag-specific data (always)
    UserDefaults.standard.set(temperature, forKey: "ruuvi_temperature")
    UserDefaults.standard.set(humidity, forKey: "ruuvi_humidity")
    UserDefaults.standard.set(connectionStatus, forKey: "ruuvi_status")
    UserDefaults.standard.set(Date(), forKey: "ruuvi_lastUpdated")

    // Only save to generic keys if active sensor (for UI/intents)
    if isActiveSource {
        UserDefaults.standard.set(temperature, forKey: "currentTemperature")
        UserDefaults.standard.set(humidity, forKey: "currentHumidity")
        UserDefaults.standard.set(connectionStatus, forKey: "connectionStatus")

        // Also save to shared defaults for widgets
        sharedDefaults?.set(temperature, forKey: "temperature")
        sharedDefaults?.set(humidity, forKey: "humidity")
        sharedDefaults?.synchronize()

        // Donate intents only for active sensor
        donateIntents()
    }

    UserDefaults.standard.synchronize()
}
```

---

### File 3: `IOS--BLE Central/BLE_Central/BluetoothViewModel.swift`

**Apply the same changes as File 1** (iOS version of Arduino ViewModel)

---

### File 4: `IOS--BLE Central/BLE_Central/RuuviTagViewModel.swift`

**Apply the same changes as File 2** (iOS version of RuuviTag ViewModel)

---

## Summary of Changes

### Before:
- Only active sensor writes to UserDefaults
- Keys: `currentTemperature`, `currentHumidity`
- Result: Can't log both sensors simultaneously

### After:
- **Both sensors always write** to unique keys
- Arduino keys: `arduino_temperature`, `arduino_humidity`, `arduino_status`, `arduino_lastUpdated`
- RuuviTag keys: `ruuvi_temperature`, `ruuvi_humidity`, `ruuvi_status`, `ruuvi_lastUpdated`
- Generic keys: Still written by active sensor (for UI/intents)
- Result: Logger can read both sensors at once!

---

## New UserDefaults Keys

| Sensor | Temperature Key | Humidity Key | Status Key | Timestamp Key |
|--------|----------------|--------------|------------|---------------|
| Arduino | `arduino_temperature` | `arduino_humidity` | `arduino_status` | `arduino_lastUpdated` |
| RuuviTag | `ruuvi_temperature` | `ruuvi_humidity` | `ruuvi_status` | `ruuvi_lastUpdated` |
| Active (UI) | `currentTemperature` | `currentHumidity` | `connectionStatus` | - |

---

## Testing After Changes

### 1. Build and Run
```bash
cd /Users/bobh/Desktop/Projects/Cricket
xcodebuild -project "./CricketMac/CricketMac.xcodeproj" -scheme Cricket_mac build
```

### 2. Open Two Cricket Instances
- One connected to Arduino
- One connected to RuuviTag

### 3. Verify Both Writing
```bash
# Check Arduino values
defaults read wm6h.Cricket-mac arduino_temperature
defaults read wm6h.Cricket-mac arduino_humidity

# Check RuuviTag values
defaults read wm6h.Cricket-mac ruuvi_temperature
defaults read wm6h.Cricket-mac ruuvi_humidity

# Both should return current values!
```

---

## Files to Modify

Total: **4 files** (2 macOS, 2 iOS)

**macOS:**
1. `CricketMac/CricketMac/BluetoothViewModel.swift`
2. `CricketMac/CricketMac/RuuviTagViewModel.swift`

**iOS:**
3. `IOS--BLE Central/BLE_Central/BluetoothViewModel.swift`
4. `IOS--BLE Central/BLE_Central/RuuviTagViewModel.swift`

---

## Estimated Effort

- **Coding**: 30 minutes (straightforward changes)
- **Testing**: 15 minutes (verify both sensors writing)
- **Total**: 45 minutes

---

## Next Steps After Code Changes

1. ✅ Make code changes
2. ✅ Build and test
3. ✅ Verify both sensors writing to UserDefaults
4. ✅ Update `sensor_logger.py` to read new keys
5. ✅ Set up automated logging (4x daily)
6. ✅ Collect data for 7 days
7. ✅ Run analyzer and apply calibration!

---

**Ready to make these changes?**
