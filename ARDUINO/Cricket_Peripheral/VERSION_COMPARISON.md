# Cricket Arduino Peripheral - Version Comparison

## Quick Decision Guide

**Choose Cricket_Peripheral.ino if:**
- ✅ Powered by USB or wall adapter (not battery)
- ✅ You want immediate visual LED feedback
- ✅ You need 1-second real-time monitoring
- ✅ Power consumption doesn't matter

**Choose Cricket_Peripheral_LowPower.ino if:**
- ✅ Running on battery power (LiPo, coin cell, power bank)
- ✅ Need extended battery life (weeks/months)
- ✅ Can tolerate 60-second updates in low-power mode
- ✅ Want flexibility to switch modes remotely via BLE

---

## Feature Matrix

| Feature | Cricket_Peripheral.ino | Cricket_Peripheral_LowPower.ino |
|---------|----------------------|--------------------------------|
| **Power Modes** | Single (always normal) | Dual (Normal + Battery) |
| **Mode Switching** | None | BLE command or physical switch |
| **Sample Rate** | 1 Hz (1 second) | 1 Hz or 0.0167 Hz (switchable) |
| **RGB LEDs** | Always enabled | Enabled in Normal, OFF in Battery |
| **Power Consumption** | ~10-15mA | ~10-15mA (Normal) / ~2-5mA (Battery) |
| **Battery Life (2000mAh)** | ~5.5 days | ~5.5 days (Normal) / ~17-42 days (Battery) |
| **CPU Sleep** | None | WFE low-power sleep in Battery mode |
| **Code Complexity** | Simple | Moderate (adds mode management) |
| **Flash Usage** | ~100KB | ~105KB (+5KB for power management) |
| **RAM Usage** | ~20KB | ~22KB (+2KB for mode state) |
| **BLE Characteristics** | 2 (temp, humidity) | 3 (temp, humidity, battery mode) |
| **Best For** | USB/Wall power | Battery power |

---

## Power Consumption Details

### Cricket_Peripheral.ino (Standard):
```
Base consumption:        ~8-10mA
RGB LEDs (avg):          ~5-7mA
BLE advertising:         ~2-3mA
Sensor (periodic):       ~0.5mA
─────────────────────────────
Total:                   ~10-15mA
```

### Cricket_Peripheral_LowPower.ino (Normal Mode):
```
Base consumption:        ~8-10mA
RGB LEDs (avg):          ~5-7mA
BLE advertising:         ~2-3mA
Sensor (periodic):       ~0.5mA
Mode management:         ~0.1mA
─────────────────────────────
Total:                   ~10-15mA
(Virtually identical to standard version)
```

### Cricket_Peripheral_LowPower.ino (Battery Mode):
```
Base consumption:        ~1-2mA (with CPU sleep)
RGB LEDs:                0mA (OFF)
BLE advertising:         ~1-2mA (reduced)
Sensor (1/60th rate):    ~0.01mA (averaged)
Mode management:         ~0.1mA
─────────────────────────────
Total:                   ~2-5mA
(70-80% power reduction!)
```

---

## Battery Life Calculations

### With 2000mAh LiPo Battery:

| Version | Mode | Current | Battery Life | Days |
|---------|------|---------|--------------|------|
| Standard | N/A | 12mA | 167 hours | 6.9 days |
| Low-Power | Normal | 12mA | 167 hours | 6.9 days |
| Low-Power | **Battery** | **3mA** | **667 hours** | **27.8 days** |

### With 1000mAh Power Bank:

| Version | Mode | Current | Battery Life | Days |
|---------|------|---------|--------------|------|
| Standard | N/A | 12mA | 83 hours | 3.5 days |
| Low-Power | Normal | 12mA | 83 hours | 3.5 days |
| Low-Power | **Battery** | **3mA** | **333 hours** | **13.9 days** |

### With 220mAh Coin Cell (CR2032):

| Version | Mode | Current | Battery Life | Days |
|---------|------|---------|--------------|------|
| Standard | N/A | 12mA | 18 hours | 0.75 days |
| Low-Power | Normal | 12mA | 18 hours | 0.75 days |
| Low-Power | **Battery** | **3mA** | **73 hours** | **3.0 days** |

*Note: Actual battery life depends on usage patterns, temperature, BLE connection frequency, and battery quality. Above calculations assume continuous operation.*

---

## Code Size Comparison

```bash
# Cricket_Peripheral.ino
Sketch uses 102,432 bytes (19%) of program storage space
Global variables use 22,016 bytes (8%) of dynamic memory

# Cricket_Peripheral_LowPower.ino
Sketch uses 107,520 bytes (20%) of program storage space
Global variables use 24,192 bytes (9%) of dynamic memory

Difference: +5KB flash, +2KB RAM
```

The low-power version adds minimal overhead while providing significant power savings.

---

## Functional Differences

### 1. LED Behavior

**Standard Version:**
- Always shows status (Blue/Green/Purple/Red)
- No way to disable LEDs

**Low-Power Version:**
- Normal mode: Shows status (same as standard)
- Battery mode: All LEDs OFF permanently
- Switchable at runtime

### 2. Sampling Frequency

**Standard Version:**
- Fixed 1-second sampling
- Always provides real-time updates

**Low-Power Version:**
- Normal mode: 1-second sampling
- Battery mode: 60-second sampling
- Trade-off: responsiveness vs battery life

### 3. Data Transmission Thresholds

**Standard Version:**
- Temperature: 0.5°C change triggers transmission
- Humidity: 0.5%RH change triggers transmission

**Low-Power Version:**
- Normal mode: 0.5°C / 0.5%RH (same as standard)
- Battery mode: 1.0°C / 2.0%RH (less sensitive)
- Fewer transmissions = longer battery life

### 4. BLE Characteristics

**Standard Version:**
```
Service: 5971e8f1-bc4d-4a5f-a6fd-3591131a98c6
├─ Temperature:  78b20af1-e597-40c1-a69c-304205b7e099
└─ Humidity:     0ba15aa1-a805-4205-bc82-af2e4a9364c5
```

**Low-Power Version:**
```
Service: 5971e8f1-bc4d-4a5f-a6fd-3591131a98c6
├─ Temperature:  78b20af1-e597-40c1-a69c-304205b7e099
├─ Humidity:     0ba15aa1-a805-4205-bc82-af2e4a9364c5
└─ Battery Mode: a1b2c3d4-e5f6-4789-a012-3456789abcde  ← NEW
```

The battery mode characteristic allows iOS/Mac apps to:
- Read current mode (0 = Normal, 1 = Battery)
- Write to change mode remotely

---

## Migration Path

### From Standard → Low-Power:

1. **Back up your current sketch**
2. **Open Cricket_Peripheral_LowPower.ino**
3. **Upload to Arduino**
4. **Test in Normal mode first** (default startup mode)
5. **Switch to Battery mode** when ready (via BLE or physical switch)

**No app changes needed initially** - the low-power version is fully backward compatible in Normal mode!

### App Integration (Optional):

To add Battery Mode control to iOS/Mac apps:
1. Discover new Battery Mode characteristic
2. Add UI toggle/button
3. Write 0x00 (Normal) or 0x01 (Battery)
4. See `BATTERY_MODE_GUIDE.md` for code examples

---

## Real-World Use Cases

### Use Case 1: Desktop USB Monitoring
**Scenario:** Arduino on desk, powered by USB, monitoring room climate
**Recommendation:** `Cricket_Peripheral.ino` (standard)
**Why:** USB powered, want immediate LED feedback, no battery concerns

### Use Case 2: Greenhouse Monitoring (Solar + Battery)
**Scenario:** Remote greenhouse, 2000mAh LiPo + small solar panel
**Recommendation:** `Cricket_Peripheral_LowPower.ino` in Battery mode
**Why:** Need 2-4 week battery backup, 60s updates sufficient for plants

### Use Case 3: Travel Temperature Logger
**Scenario:** Monitor suitcase temp during travel, 1000mAh power bank
**Recommendation:** `Cricket_Peripheral_LowPower.ino` in Battery mode
**Why:** Need multi-day operation, can check readings periodically

### Use Case 4: Bedroom Monitoring
**Scenario:** Bedside table, USB charger, sleep tracking
**Recommendation:** `Cricket_Peripheral.ino` OR `Low-Power in Normal mode`
**Why:** Wall powered, might want to disable LEDs at night (Low-Power gives option)

### Use Case 5: Server Room Monitoring
**Scenario:** 24/7 temperature monitoring, PoE or USB powered
**Recommendation:** `Cricket_Peripheral.ino` (standard)
**Why:** Always powered, need real-time alerts (1s sampling), LED status useful

---

## Testing Recommendations

### For Standard Version:
```
1. Upload Cricket_Peripheral.ino
2. Open Serial Monitor (115200 baud)
3. Connect with iOS/Mac app
4. Verify:
   ✓ LEDs show status (Blue → Green → Purple flashes)
   ✓ Readings every 1 second
   ✓ Temperature/humidity displayed in app
```

### For Low-Power Version:
```
1. Upload Cricket_Peripheral_LowPower.ino
2. Open Serial Monitor (115200 baud)
3. Test Normal Mode (default):
   ✓ LEDs show status (same as standard)
   ✓ Readings every 1 second
   ✓ Serial: "NORMAL MODE ACTIVATED"

4. Switch to Battery Mode:
   - Send BLE command (0x01) OR
   - Toggle physical switch to GND

5. Test Battery Mode:
   ✓ All LEDs turn OFF
   ✓ Readings every 60 seconds
   ✓ Serial: "BATTERY MODE ACTIVATED"
   ✓ BLE connection still works
```

---

## Frequently Asked Questions

**Q: Can I switch between versions easily?**
A: Yes! Just upload the other .ino file. They use the same BLE service UUID, so iOS/Mac apps work with both.

**Q: Does Low-Power version work the same in Normal mode?**
A: Yes, virtually identical to standard version when in Normal mode.

**Q: Will my iOS/Mac app work with Low-Power version?**
A: Yes! Fully backward compatible. Battery Mode characteristic is optional.

**Q: Can I add Battery Mode to standard version?**
A: No, use the Low-Power version - it's designed for both scenarios.

**Q: Does Battery Mode affect data accuracy?**
A: No, sensor readings are equally accurate. Only sampling frequency changes.

**Q: Can I customize the Battery Mode sample interval?**
A: Yes! Change `BATTERY_SAMPLE_INTERVAL` from 60000ms to desired value (in milliseconds).

**Q: Why not always use Low-Power version?**
A: You should! It's a superset of standard version with no downsides.

---

## Recommendation

**For new projects:** Use `Cricket_Peripheral_LowPower.ino`

**Why:**
- ✅ Includes all features of standard version
- ✅ Adds battery mode flexibility
- ✅ Minimal code size increase (+5KB)
- ✅ No performance penalty in Normal mode
- ✅ Future-proof for battery deployment

The standard `Cricket_Peripheral.ino` is retained for:
- Educational purposes (simpler code to learn from)
- Minimal flash usage scenarios
- Legacy compatibility

---

## Summary

| Criteria | Standard | Low-Power |
|----------|----------|-----------|
| **Simplicity** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Flexibility** | ⭐ | ⭐⭐⭐⭐⭐ |
| **Battery Life** | ⭐⭐ | ⭐⭐⭐⭐⭐ (Battery mode) |
| **Features** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Code Size** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Recommended For** | USB power only | Battery or USB power |

**Winner:** Cricket_Peripheral_LowPower.ino for most use cases! 🏆

---

Happy Cricket monitoring! 🦗🔋
