# 🦗 Cricket Arduino - Quick Reference Card

## BLE Service & Characteristics

```
Service UUID:     5971e8f1-bc4d-4a5f-a6fd-3591131a98c6
├─ Temperature:   78b20af1-e597-40c1-a69c-304205b7e099 (Float, Read/Notify)
├─ Humidity:      0ba15aa1-a805-4205-bc82-af2e4a9364c5 (Float, Read/Notify)
└─ Battery Mode:  a1b2c3d4-e5f6-4789-a012-3456789abcde (Byte, Read/Write)
                  └─ 0x00 = Normal Mode, 0x01 = Battery Mode
```

---

## LED Status Colors (Normal Mode)

| Color | State | Description |
|-------|-------|-------------|
| 🔵 Blue | Advertising | Waiting for connection |
| 🟢 Green | Connected | iPhone/Mac connected |
| 🟣 Purple | Data Transfer | Brief flash during transmission |
| 🔴 Red | Error | Startup/initialization |
| ⚫ Off | Battery Mode | All LEDs disabled to save power |

---

## Power Modes Comparison

|  | Normal Mode | Battery Mode |
|---|-------------|--------------|
| **Sample Rate** | 1 second | 60 seconds |
| **LEDs** | ON | OFF |
| **Temp Threshold** | 0.5°C | 1.0°C |
| **Humidity Threshold** | 0.5%RH | 2.0%RH |
| **Power Draw** | ~10-15mA | ~2-5mA |
| **Battery Life (2000mAh)** | ~7 days | ~28 days |

---

## Mode Switching Commands

### Via BLE (iOS/Mac App):
```swift
// Enable Battery Mode
characteristic.writeValue(Data([0x01]), type: .withResponse)

// Enable Normal Mode
characteristic.writeValue(Data([0x00]), type: .withResponse)
```

### Via Physical Switch:
```
Pin D2 to GND = Battery Mode
Pin D2 open   = Normal Mode
```

---

## Serial Monitor Output

### Startup:
```
=== Cricket Low-Power Peripheral ===
Arduino Nano 33 BLE Sense Rev2 (nRF52840)
SUCCESS: HS300x sensor initialized
SUCCESS: BLE initialized
Mode: NORMAL (full power)
```

### Normal Mode:
```
Raw: 23.1°C, 39.2% | Avg(5): 23.1°C, 39.2%  ← Every 1s
```

### Battery Mode:
```
BATTERY MODE ACTIVATED
Raw: 23.1°C, 39.2% | Avg(5): 23.1°C, 39.2%  ← Every 60s
```

---

## Pin Configuration

```
Arduino Nano 33 BLE Rev 2:
┌──────────────────┐
│ LEDR (22) - Red  │  Built-in RGB LED
│ LEDG (23) - Green│  (Active-LOW)
│ LEDB (24) - Blue │
│ D2 - Mode Switch │  Optional physical switch
│ GND              │  Switch ground reference
└──────────────────┘

I2C (HS300x Sensor):
- SDA: Pin A4
- SCL: Pin A5
- Built-in sensor on Rev 2
```

---

## Battery Life Calculator

```
Battery Life (hours) = Battery Capacity (mAh) / Current Draw (mA)

Examples:
- 2000mAh LiPo + Normal Mode (12mA):   167 hours (~7 days)
- 2000mAh LiPo + Battery Mode (3mA):   667 hours (~28 days)
- 1000mAh Bank + Battery Mode (3mA):   333 hours (~14 days)
- 220mAh CR2032 + Battery Mode (3mA):  73 hours (~3 days)
```

---

## Common Issues & Solutions

| Problem | Solution |
|---------|----------|
| Arduino not connecting | Check Serial Monitor for "BLE advertising" message |
| LEDs stay purple | Normal - data transmitting constantly or mode stuck |
| No LED in Battery Mode | Correct behavior - LEDs disabled to save power |
| Readings every 1s in Battery Mode | Mode not activated - check Serial for "BATTERY MODE" |
| Physical switch not working | Set `USE_PHYSICAL_SWITCH = true` in code |
| Battery drains too fast | Verify Battery Mode active, check LED is OFF |

---

## Upload Checklist

1. ✅ Select **Board:** "Arduino Nano 33 BLE"
2. ✅ Select **Port:** (your Arduino's port)
3. ✅ Choose version:
   - `Cricket_Peripheral.ino` - Standard (USB power)
   - `Cricket_Peripheral_LowPower.ino` - Battery capable
4. ✅ Click **Upload**
5. ✅ Open **Serial Monitor** (115200 baud)
6. ✅ Verify startup messages

---

## Testing Checklist

### Basic Functionality:
- [ ] Arduino advertises (Blue LED or Serial confirms)
- [ ] iPhone/Mac app can connect
- [ ] Temperature reading displays correctly
- [ ] Humidity reading displays correctly
- [ ] LED turns Green when connected
- [ ] Purple flash when data transmits

### Battery Mode (Low-Power version only):
- [ ] Can switch to Battery Mode (BLE or switch)
- [ ] All LEDs turn OFF in Battery Mode
- [ ] Readings appear every 60 seconds
- [ ] Serial shows "BATTERY MODE ACTIVATED"
- [ ] App still receives data updates
- [ ] Can switch back to Normal Mode

---

## File Organization

```
Demetor_Peripheral_1/
├── Cricket_Peripheral.ino              ← Standard version (USB power)
├── Cricket_Peripheral_LowPower.ino     ← Battery-capable version ⭐
├── Cricket_Peripheral_WITH_LED.ino.bak ← Backup
├── LED_STATUS_GUIDE.md                 ← LED color reference
├── BATTERY_MODE_GUIDE.md               ← Battery mode documentation
├── VERSION_COMPARISON.md               ← Feature comparison
└── QUICK_REFERENCE.md                  ← This file
```

---

## Configuration Constants

```cpp
// Easy customization points in code:

// Sample intervals
const unsigned long NORMAL_SAMPLE_INTERVAL = 1000;    // 1 second
const unsigned long BATTERY_SAMPLE_INTERVAL = 60000;  // 60 seconds

// Change thresholds
const float TEMP_THRESHOLD_NORMAL = 0.5;   // 0.5°C
const float TEMP_THRESHOLD_BATTERY = 1.0;  // 1.0°C
const float HUM_THRESHOLD_NORMAL = 0.5;    // 0.5%RH
const float HUM_THRESHOLD_BATTERY = 2.0;   // 2.0%RH

// Physical switch
const int MODE_SWITCH_PIN = 2;              // Pin D2
const bool USE_PHYSICAL_SWITCH = false;     // Enable/disable switch

// Device name
const char* DEVICE_NAME = "Cricket";        // BLE advertising name
```

---

## URLs & Resources

- **Arduino Nano 33 BLE Docs:** https://docs.arduino.cc/hardware/nano-33-ble
- **HS300x Sensor Library:** https://github.com/arduino-libraries/Arduino_HS300x
- **ArduinoBLE Library:** https://www.arduino.cc/reference/en/libraries/arduinoble/
- **nRF52840 Datasheet:** Nordic Semiconductor website

---

## Support

For issues or questions:
1. Check Serial Monitor output (115200 baud)
2. Verify BLE UUIDs match iOS/Mac app
3. Measure actual power consumption with multimeter
4. Review LED_STATUS_GUIDE.md and BATTERY_MODE_GUIDE.md

---

## Version Info

- **Standard Version:** Cricket_Peripheral.ino v1.0
- **Low-Power Version:** Cricket_Peripheral_LowPower.ino v1.0
- **Compatible iOS:** Cricket app (all versions)
- **Compatible macOS:** Cricket app (all versions)
- **Arduino Board:** Nano 33 BLE Rev 2
- **Required Libraries:**
  - ArduinoBLE (latest)
  - Arduino_HS300x (latest)
  - mbed (included with board package)

---

🦗 Happy Cricket Monitoring! 🌡️💧🔋
