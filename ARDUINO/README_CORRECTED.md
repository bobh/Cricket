# Arduino BLE Sensor Peripheral

This Arduino sketch creates a BLE peripheral that reads temperature and humidity from the Arduino Nano 33 Sense Rev 2's onboard **HS3003 sensor** and transmits the data to the iOS BLE Central app using **Bluetooth SIG compliant** data formats.

## Hardware Requirements

- Arduino Nano 33 Sense Rev 2 (with built-in **HS3003 sensor**)
- USB cable for programming

## Software Requirements

Install the following libraries in Arduino IDE:

1. **ArduinoBLE** - For BLE communication (built-in for Arduino Nano 33 BLE)
2. **Arduino_HS300x** - For temperature/humidity sensor (HS3003)

## Installation

1. Open Arduino IDE
2. Install required libraries via Library Manager
3. Connect Arduino Nano 33 Sense Rev 2 to computer
4. Open `BLE_Sensor_Peripheral_BLE_Standards.ino`
5. Select board: "Arduino Nano 33 BLE"
6. Upload the sketch

## Features

### Bluetooth SIG Compliance
- **Temperature**: sint16 format (supports negative temperatures)
- **Humidity**: uint16 format  
- **Standards compliant**: Follows official Bluetooth SIG specifications
- **Negative temperature support**: -10°C to +70°C operating range

### Power Optimization
- Minimal delays between sensor readings
- Reduced BLE transmission power
- Longer advertising intervals (1 second)
- Disabled unused peripherals
- Optimized BLE connection parameters

### Sensor Data Processing
- 500ms sampling interval
- 5-reading running average
- Change-based transmission (±0.5°C, ±2% humidity)
- **Error handling**: -32768 (temperature), 65535 (humidity) on sensor failure

### BLE Communication
- Environmental Sensing Service (181A)
- Temperature Characteristic (2A6E) - **sint16**
- Humidity Characteristic (2A6F) - **uint16**
- Compatible with iOS BLE Central app
- Automatic reconnection after disconnect

## Usage

1. Upload sketch to Arduino Nano 33 Sense Rev 2
2. Power on the device
3. Launch iOS BLE Central app
4. The app will automatically discover and connect to "Arduino Sensor"
5. Temperature and humidity readings will appear in the app

## Configuration

Modify these constants in the sketch to customize behavior:

```cpp
#define TEMP_CHANGE_THRESHOLD 0.5    // ±0.5°C change threshold
#define HUMIDITY_CHANGE_THRESHOLD 2.0 // ±2% humidity change threshold
#define SAMPLE_INTERVAL_MS 500       // 500ms between sensor readings
#define SAMPLES_FOR_AVERAGE 5        // Number of readings to average

// Error values (Bluetooth SIG compliant)
#define TEMP_ERROR_VALUE -32768      // INT16_MIN for sint16
#define HUMIDITY_ERROR_VALUE 65535   // UINT16_MAX for uint16
```

## Data Format Examples

```cpp
// Positive temperature: 23.50°C → 2350 (sint16)
// Negative temperature: -5.00°C → -500 (sint16)
// Humidity: 45.20% → 4520 (uint16)
// Temperature error: -32768 (INT16_MIN)
// Humidity error: 65535 (UINT16_MAX)
```

## Serial Monitor Output

Connect to serial monitor at 115200 baud to see:
- Sensor initialization status
- Individual sensor readings
- Averaged values
- BLE connection status
- Transmitted data values with sint16/uint16 format

## Troubleshooting

- **No BLE connection**: Check that iOS device Bluetooth is enabled
- **Sensor errors**: Verify HS3003 sensor is properly connected/functioning
- **High power consumption**: Ensure unused peripherals are disabled
- **Connection drops**: Check BLE signal strength and interference
- **Negative temperature issues**: Ensure iOS app handles sint16 format correctly

## Important Notes

⚠️ **iOS App Compatibility**: The iOS app must be updated to handle **sint16** temperature values to support negative temperatures. The original uint16 parsing will not work correctly with the standards-compliant implementation.

📊 **Sensor Specifications**: The HS3003 sensor provides ±0.25°C temperature accuracy and ±2.8% RH humidity accuracy. The 0.01°C/0.01% precision refers to the BLE transmission format resolution, not the underlying sensor accuracy.