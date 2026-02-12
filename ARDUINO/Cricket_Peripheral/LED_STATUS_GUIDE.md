# 🦗 Cricket Arduino RGB LED Status Guide

## Arduino Nano 33 BLE Rev 2 - Built-in RGB LED

The Cricket peripheral now uses the built-in RGB LED to indicate BLE connection status.

---

## LED Status Colors

| State | Color | LED Code (active-low) | Description |
|-------|-------|----------------------|-------------|
| **Advertising** | 🔵 **Blue** | `LEDR = HIGH, LEDG = HIGH, LEDB = LOW` | Arduino is advertising and waiting for connection |
| **Connected** | 🟢 **Green** | `LEDR = HIGH, LEDG = LOW, LEDB = HIGH` | Successfully connected to iPhone/iOS device |
| **Disconnected/Error** | 🔴 **Red** | `LEDR = LOW, LEDG = HIGH, LEDB = HIGH` | Connection lost or error state |
| **Data Transfer** | 🟣 **Purple** | `LEDR = 128, LEDG = 255, LEDB = 128` (analogWrite) | Brief flash when transmitting temperature/humidity |

---

## LED Behavior Flow

### Power On Sequence:
1. **Red** (initialization)
2. **Blue** (BLE advertising starts)
3. **Green** (iPhone connects)
4. **Purple flashes** (every second when sending data)

### Normal Operation:
- **Steady Green** = Connected and idle
- **Brief Purple Flash** = Sending temperature/humidity data (100ms flash)
- Returns to **Green** after each data transmission

### Disconnection:
- **Blue** = Lost connection, now advertising again
- **Red** = Error state or initial startup before BLE ready

---

## Technical Details

### Pin Configuration:
```cpp
pinMode(LEDR, OUTPUT);  // Pin 22
pinMode(LEDG, OUTPUT);  // Pin 23
pinMode(LEDB, OUTPUT);  // Pin 24
```

### Active-LOW Operation:
- `LOW` = LED **ON** (brightness 255)
- `HIGH` = LED **OFF** (brightness 0)
- `analogWrite(pin, value)` = Brightness control (0=full on, 255=off)

### Data Transfer Flash:
- **Duration**: 100ms purple flash
- **Frequency**: Occurs whenever temperature or humidity data is transmitted
- **Trigger**: When change threshold exceeded (0.5°C or 0.5%RH)

---

## Code Reference

See `/Users/bobh/Desktop/Cricket/ARDUINO/Demetor_Peripheral_1/Cricket_Peripheral.ino`:

- **Lines 23-38**: RGB LED configuration and BLEState enum
- **Lines 71-75**: LED initialization in setup()
- **Lines 146-164**: LED state changes on connect/disconnect
- **Lines 248-264**: Purple flash during data transmission
- **Lines 267-306**: setLEDState() function implementation

---

## Troubleshooting

### LED not lighting up?
- The LED is built-in - no wiring needed
- Check that Arduino is powered
- Verify sketch uploaded successfully

### Wrong colors?
- Remember pins are active-LOW
- Blue on startup = normal (advertising)
- Green after iPhone connects = correct
- Purple flashes = data being sent

### No purple flashes?
- Data only sends when readings change by threshold
- Check Serial Monitor for "BLE TX:" messages
- Sensor may be in stable environment (no changes to report)

---

## Visual Reference

```
POWER ON → 🔴 RED (init)
         ↓
      🔵 BLUE (advertising)
         ↓
      🟢 GREEN (connected)
         ↓
      🟣 PURPLE (data) → 🟢 GREEN → 🟣 PURPLE → 🟢 GREEN ...
         ↓
      🔵 BLUE (if disconnected)
```

---

Happy Cricket monitoring! 🦗🌡️💧
