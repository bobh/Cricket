# 🔋 Cricket Arduino - Battery Mode Guide

## Overview

The Cricket Peripheral now supports **Battery Mode** for extended battery life when running on battery power (LiPo, coin cell, or USB power bank).

---

## Two Versions Available

### 1. **Cricket_Peripheral.ino** (Current/Normal)
- ✅ Full features, 1-second sampling
- ✅ RGB LED status indicators
- ✅ Optimized for USB/wall power
- ⚡ Higher power consumption (~10-15mA)

### 2. **Cricket_Peripheral_LowPower.ino** (New/Battery)
- ✅ Switchable between Normal and Battery modes
- ✅ Battery mode: 60-second sampling
- ✅ LEDs disabled in battery mode
- ✅ Low-power CPU sleep between readings
- ⚡ Battery mode: ~2-5mA (estimated 10x longer battery life)

---

## Power Consumption Comparison

| Feature | Normal Mode | Battery Mode | Power Savings |
|---------|-------------|--------------|---------------|
| Sample Interval | 1 second | 60 seconds | 60x less sensor reads |
| RGB LEDs | Always on | Always OFF | ~5-10mA saved |
| CPU Sleep | None | WFE sleep mode | ~2-3mA saved |
| BLE Advertising | Standard | Reduced | ~0.5mA saved |
| Temp Threshold | 0.5°C | 1.0°C | Fewer transmissions |
| Humidity Threshold | 0.5%RH | 2.0%RH | Fewer transmissions |
| **Total Current** | ~10-15mA | ~2-5mA | **~70% reduction** |

### Battery Life Estimates:

**With 2000mAh LiPo battery:**
- Normal Mode: ~133 hours (~5.5 days)
- Battery Mode: ~400-1000 hours (~17-42 days)

**With 220mAh coin cell (CR2032):**
- Normal Mode: ~15 hours
- Battery Mode: ~44-110 hours (~2-5 days)

*Note: Actual battery life depends on BLE connection time, environmental changes, and battery quality.*

---

## How to Switch Between Modes

### Method 1: BLE Command (Recommended)

**From iOS/Mac Cricket App** (requires app update):

The app will need a new UI control to send Battery Mode commands.

**BLE Characteristic:**
- UUID: `a1b2c3d4-e5f6-4789-a012-3456789abcde`
- Write value: `0x00` = Normal Mode
- Write value: `0x01` = Battery Mode

**Future iOS/Mac Implementation:**
```swift
// In BluetoothViewModel or ContentView
let batteryModeUUID = CBUUID(string: "a1b2c3d4-e5f6-4789-a012-3456789abcde")

func enableBatteryMode() {
    let data = Data([0x01])
    peripheral.writeValue(data, for: batteryModeCharacteristic, type: .withResponse)
}

func enableNormalMode() {
    let data = Data([0x00])
    peripheral.writeValue(data, for: batteryModeCharacteristic, type: .withResponse)
}
```

### Method 2: Physical Switch (Optional Hardware)

**Add a physical toggle switch:**

1. **Components needed:**
   - SPST toggle switch or slide switch
   - 2 wires

2. **Wiring:**
   - Connect one switch terminal to **D2** (or change `MODE_SWITCH_PIN` in code)
   - Connect other switch terminal to **GND**
   - Arduino uses internal pull-up resistor

3. **Enable in code:**
   ```cpp
   const bool USE_PHYSICAL_SWITCH = true;  // Change to true
   const int MODE_SWITCH_PIN = 2;          // Pin D2
   ```

4. **Operation:**
   - Switch OPEN (disconnected) = **Normal Mode** (LEDs on)
   - Switch CLOSED (grounded) = **Battery Mode** (LEDs off)

**Pinout Reference:**
```
Arduino Nano 33 BLE Rev 2:
┌─────────────┐
│  D13 - SCK  │
│  D12 - MISO │
│  D11 - MOSI │
│  D10        │
│  ...        │
│  D2  ◄──────┼── Switch ── GND
│  GND ───────┘
└─────────────┘
```

---

## Visual Indicators

### LED Behavior:

| Mode | Advertising | Connected | Data TX |
|------|-------------|-----------|---------|
| **Normal** | 🔵 Blue | 🟢 Green | 🟣 Purple flash |
| **Battery** | ⚫ OFF | ⚫ OFF | ⚫ OFF |

**In Battery Mode:**
- All LEDs are **permanently OFF**
- No visual indication of connection status
- Check iOS/Mac app to verify connection

**To verify Battery Mode is active:**
- Serial Monitor will print: "BATTERY MODE ACTIVATED"
- LEDs turn off immediately
- Readings appear every 60 seconds (not every second)

---

## Feature Comparison Table

| Feature | Normal Mode | Battery Mode |
|---------|-------------|--------------|
| **Sample Rate** | 1 Hz (every 1s) | 0.0167 Hz (every 60s) |
| **RGB LEDs** | ✅ Enabled | ❌ Disabled |
| **Temperature Threshold** | 0.5°C | 1.0°C |
| **Humidity Threshold** | 0.5%RH | 2.0%RH |
| **CPU Sleep** | ❌ None | ✅ WFE low-power |
| **Serial Debug** | ✅ Full | ✅ Full (same) |
| **BLE Notifications** | ✅ Every change | ✅ Every change (less frequent) |
| **Connection Speed** | Fast | Same |
| **Data Accuracy** | High | Same |

**Key Differences:**
1. **Sampling frequency** - Most significant power saver
2. **LED power** - Saves 5-10mA
3. **Threshold sensitivity** - Fewer BLE transmissions = less power
4. **CPU sleep** - Saves power between sensor reads

---

## Serial Monitor Output

### Normal Mode:
```
========================================
NORMAL MODE ACTIVATED
  - Sample interval: 1 second
  - LEDs: ENABLED
  - Thresholds: Full sensitivity
  - Low-power sleep: DISABLED
========================================
Raw: 23.1°C, 39.2% | Avg(5): 23.1°C, 39.2%
Raw: 23.1°C, 39.2% | Avg(5): 23.1°C, 39.2%  <- Every 1 second
Raw: 23.1°C, 39.2% | Avg(5): 23.1°C, 39.2%
```

### Battery Mode:
```
========================================
BATTERY MODE ACTIVATED
  - Sample interval: 60 seconds
  - LEDs: DISABLED
  - Thresholds: Reduced sensitivity
  - Low-power sleep: ENABLED
========================================
Raw: 23.1°C, 39.2% | Avg(5): 23.1°C, 39.2%
... (60 second wait) ...
Raw: 23.1°C, 39.2% | Avg(5): 23.1°C, 39.2%  <- Every 60 seconds
... (60 second wait) ...
```

---

## Testing Battery Mode

### Step 1: Upload Low-Power Sketch
1. Open `Cricket_Peripheral_LowPower.ino` in Arduino IDE
2. Select **Board:** "Arduino Nano 33 BLE"
3. Select **Port:** Your Arduino's serial port
4. Click **Upload**

### Step 2: Verify Normal Mode (Default)
1. Open **Serial Monitor** (115200 baud)
2. You should see readings every 1 second
3. LED should be 🔵 Blue (advertising) or 🟢 Green (connected)

### Step 3: Switch to Battery Mode

**Option A: Via Serial Monitor** (temporary test):
- Not implemented yet (would require Serial commands)

**Option B: Via BLE Command** (requires app update):
- Use iOS/Mac app to send Battery Mode command
- Watch Serial Monitor for "BATTERY MODE ACTIVATED"

**Option C: Via Physical Switch** (if enabled):
1. Set `USE_PHYSICAL_SWITCH = true` in code
2. Re-upload sketch
3. Toggle switch to GND → Battery Mode

### Step 4: Verify Battery Mode Active
- ✅ Serial Monitor shows "BATTERY MODE ACTIVATED"
- ✅ LEDs turn OFF (all colors)
- ✅ Readings appear every 60 seconds (not 1 second)
- ✅ BLE connection still works (check iOS/Mac app)

---

## Power Optimization Details

### 1. CPU Low-Power Sleep
```cpp
void lowPowerDelay(unsigned long ms) {
    while (millis() - start < ms) {
        __WFE();  // Wait For Event - ARM Cortex-M4 sleep instruction
    }
}
```
- CPU enters sleep mode between sensor readings
- Wakes on BLE events, timers, interrupts
- Saves ~2-3mA

### 2. LED Power Savings
```cpp
case STATE_OFF:
    analogWrite(LEDR, 255);  // All LEDs off
    analogWrite(LEDG, 255);
    analogWrite(LEDB, 255);
```
- Each LED channel uses ~2-3mA when on
- Total LED savings: ~5-10mA

### 3. Reduced Sensor Sampling
- Normal: 1 reading per second = 3600 readings/hour
- Battery: 1 reading per 60 seconds = 60 readings/hour
- Sensor draw: ~0.5mA during reading (brief)
- Savings from fewer sensor activations: ~0.3mA average

### 4. Higher Thresholds = Fewer BLE Transmissions
- Normal: Transmit on 0.5°C change
- Battery: Transmit on 1.0°C change
- BLE transmission uses ~8-10mA for ~10ms
- Fewer transmissions = power savings

---

## Future iOS/Mac App Integration

To add Battery Mode control to Cricket apps:

### iOS App Changes:

**1. Add Button to ContentView.swift:**
```swift
Button(action: {
    bluetoothViewModel.toggleBatteryMode()
}) {
    HStack {
        Image(systemName: bluetoothViewModel.isBatteryMode ? "battery.25" : "bolt.fill")
        Text(bluetoothViewModel.isBatteryMode ? "Battery Mode" : "Normal Mode")
    }
}
```

**2. Add to BluetoothViewModel.swift:**
```swift
@Published var isBatteryMode: Bool = false
private var batteryModeCharacteristic: CBCharacteristic?

// UUID for battery mode characteristic
private let batteryModeUUID = CBUUID(string: "a1b2c3d4-e5f6-4789-a012-3456789abcde")

func toggleBatteryMode() {
    guard let char = batteryModeCharacteristic else { return }

    let newMode: UInt8 = isBatteryMode ? 0 : 1  // Toggle
    let data = Data([newMode])

    peripheral?.writeValue(data, for: char, type: .withResponse)
    isBatteryMode.toggle()

    NSLog("[Cricket] Battery mode: \(isBatteryMode ? "ON" : "OFF")")
}

// In peripheral(_:didDiscoverCharacteristicsFor:error:)
for characteristic in service.characteristics ?? [] {
    if characteristic.uuid == batteryModeUUID {
        batteryModeCharacteristic = characteristic
        peripheral.readValue(for: characteristic)  // Get current state
    }
}

// In peripheral(_:didUpdateValueFor:error:)
if characteristic.uuid == batteryModeUUID {
    if let data = characteristic.value, let value = data.first {
        DispatchQueue.main.async {
            self.isBatteryMode = (value == 1)
        }
    }
}
```

---

## Troubleshooting

### LEDs won't turn off in Battery Mode
- Verify you're using `Cricket_Peripheral_LowPower.ino` (not regular version)
- Check Serial Monitor for "BATTERY MODE ACTIVATED" message
- Try power cycling the Arduino

### Still getting readings every 1 second in Battery Mode
- Battery mode may not be activated
- Check `batteryModeChar` value (should be 1)
- Verify Serial Monitor shows "Sample interval: 60 seconds"

### Physical switch doesn't work
- Set `USE_PHYSICAL_SWITCH = true` in code
- Re-upload sketch
- Check wiring: Switch between D2 and GND
- Use multimeter to verify switch continuity

### Battery drains faster than expected
- Verify LEDs are actually OFF (not dim)
- Check BLE isn't constantly reconnecting (connection drops waste power)
- Measure actual current with multimeter
- Consider disabling Serial debug (saves ~1-2mA)

### Can't write to Battery Mode characteristic from app
- Verify characteristic UUID matches: `a1b2c3d4-e5f6-4789-a012-3456789abcde`
- Use `.withResponse` write type
- Check BLE connection is established
- Look for write confirmation in Serial Monitor

---

## Power Measurement

To accurately measure power consumption:

**Equipment needed:**
- Multimeter with µA/mA range
- Or: USB power meter (e.g., UM24C, UM25C)

**Method 1: Multimeter in series:**
1. Power Arduino via VIN pin (not USB during measurement)
2. Connect multimeter in series: Battery(+) → Multimeter → VIN
3. Ground: Battery(-) → GND
4. Measure current draw

**Method 2: USB power meter:**
1. Connect: USB power source → Power meter → Arduino USB
2. Read current (mA) on display

**Expected Results:**
- Normal Mode: 10-15mA
- Battery Mode (no BLE connection): 2-3mA
- Battery Mode (connected, idle): 3-5mA
- Battery Mode (during transmission): 8-12mA (brief spike)

---

## Recommendations

### When to use Normal Mode:
- ✅ USB/wall powered
- ✅ Debugging/development
- ✅ When you want visual LED feedback
- ✅ When you need real-time (1s) monitoring

### When to use Battery Mode:
- ✅ Battery powered (LiPo, coin cell, power bank)
- ✅ Remote deployment (shed, greenhouse, outdoor)
- ✅ When 60-second sampling is sufficient
- ✅ When battery life > responsiveness

### Best Battery Configuration:
1. Use 2000mAh+ LiPo battery with voltage regulator
2. Enable Battery Mode
3. Place Arduino in weatherproof enclosure
4. Expected life: 1-2 months continuous operation
5. Add solar panel for indefinite operation

---

## Next Steps

1. ✅ **Test Low-Power sketch** - Upload and verify basic functionality
2. ⏳ **Measure power consumption** - Use multimeter to confirm savings
3. ⏳ **Update iOS/Mac apps** - Add Battery Mode toggle UI
4. ⏳ **Optional: Add physical switch** - For easy mode switching
5. ⏳ **Real-world test** - Deploy on battery, monitor life over 1 week

---

## Files Reference

| File | Purpose |
|------|---------|
| `Cricket_Peripheral.ino` | Original version (always normal mode) |
| `Cricket_Peripheral_LowPower.ino` | New version (switchable modes) |
| `BATTERY_MODE_GUIDE.md` | This document |
| `LED_STATUS_GUIDE.md` | RGB LED reference |

---

Happy long-term Cricket monitoring! 🦗🔋
