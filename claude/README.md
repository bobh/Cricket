# TEST_Peripheral - Simple BLE Environmental Sensor

## Overview
Simple BLE peripheral implementation for Arduino Nano 33 BLE Sense Rev2 that transmits temperature and humidity data using Bluetooth SIG standard 16-bit UUIDs. Features 5-second running averages and clean, straightforward code design.

## Hardware Requirements
- **Arduino Nano 33 BLE Sense Rev2** with nRF52840 SoC
- **Onboard HS3003** temperature and humidity sensor
- **USB connection** for programming and power

## Software Requirements
- **Arduino IDE 2.0+**
- **Arduino Mbed OS Nano Boards** package
- **ArduinoBLE** library (official Arduino BLE library for nRF52840)
- **Arduino_HS3003** library (official Arduino library for HS3003/HS300x sensors)

## BLE Services Implementation

### Health Thermometer Service (0x1809)
- **Service UUID**: `1809`
- **Temperature Characteristic UUID**: `2A1C`
- **Data Type**: `BLEFloatCharacteristic` (32-bit float)
- **Properties**: Read, Notify
- **Units**: Celsius

### Environmental Sensing Service (0x181A)
- **Service UUID**: `181A`
- **Humidity Characteristic UUID**: `2A6F`
- **Data Type**: `BLEFloatCharacteristic` (32-bit float)
- **Properties**: Read, Notify
- **Units**: Percent (0-100%)

## Key Features

### Simple Design
- Clean, minimal code focused on core functionality
- Easy to understand and modify
- No complex data encoding - uses native float values
- Straightforward error handling

### 5-Second Running Averages
- **Sampling Rate**: 5 Hz (200ms intervals)
- **Window Size**: 25 samples (5 seconds)
- **Circular Buffer**: Efficient memory usage
- **Real-time Updates**: Continuous averaging

### BLE Functionality
- **Dual Services**: Separate services for temperature and humidity
- **Change-Based Transmission**: Only sends when values change significantly
- **Automatic Reconnection**: Resumes advertising after disconnection
- **Connection Status**: Clear serial feedback

## Installation

### 1. Library Installation
```
Arduino IDE → Tools → Manage Libraries
Search and install:
- ArduinoBLE (by Arduino)
- Arduino_HS3003 (by Arduino)
```

### 2. Hardware Setup
1. Connect Arduino Nano 33 BLE Sense Rev2 via USB
2. Select board: "Arduino Nano 33 BLE"
3. Select correct port

### 3. Upload Code
1. Open `TEST_Peripheral.ino`
2. Upload to Arduino (Ctrl+U)
3. Open Serial Monitor at 115200 baud

## Usage

### Expected Serial Output
```
=== TEST_Peripheral - Simple BLE Sensor ===
Arduino Nano 33 BLE Sense Rev2 (nRF52840)
Temperature: Health Thermometer Service (0x1809)
Humidity: Environmental Sensing Service (0x181A)
==========================================
SUCCESS: HS3003 sensor initialized via Arduino_HS3003 library
SUCCESS: BLE initialized
SUCCESS: BLE advertising as 'Nano33BLE_Sensor'
Waiting for connections...
==========================================

Raw: 23.45°C, 56.7% | Avg(1): 23.45°C, 56.7% -> SENT
Raw: 23.47°C, 56.8% | Avg(2): 23.46°C, 56.8%
Raw: 23.44°C, 56.6% | Avg(3): 23.45°C, 56.7%
...
BLE CONNECTED: Central device connected
Raw: 23.43°C, 56.5% | Avg(25): 23.45°C, 56.7% -> SENT
BLE TX: 23.45°C, 56.7%
```

### BLE Connection
1. Device advertises as **"Nano33BLE_Sensor"**
2. Provides both Health Thermometer and Environmental Sensing services
3. Central devices can read/subscribe to both characteristics
4. Values transmitted as standard 32-bit floats

## Configuration Constants

```cpp
const char* DEVICE_NAME = "Nano33BLE_Sensor";     // BLE device name
const unsigned long SAMPLE_INTERVAL = 200;        // 200ms sampling
const int AVERAGE_WINDOW = 25;                     // 25 samples = 5 seconds
const float TEMP_THRESHOLD = 0.1;                  // 0.1°C change threshold
const float HUM_THRESHOLD = 0.5;                   // 0.5% change threshold
```

## Performance Specifications

### Sensor Performance
- **Temperature Accuracy**: ±0.25°C (HS3003 specification)
- **Humidity Accuracy**: ±2.8% RH (HS3003 specification)
- **Sampling Rate**: 5 Hz (200ms intervals)
- **Average Window**: 5 seconds (25 samples)

### BLE Performance
- **Transmission Threshold**: 0.1°C temperature, 0.5% humidity
- **Connection Time**: <2 seconds typical
- **Power Consumption**: Minimal (10ms loop delay)
- **Memory Usage**: Low (circular buffer design)

### Data Transmission
- **Temperature**: 32-bit IEEE 754 float (Celsius)
- **Humidity**: 32-bit IEEE 754 float (Percent)
- **Update Rate**: Change-based (not time-based)
- **Precision**: Full float precision maintained

## Troubleshooting

### Sensor Initialization Failure
```
ERROR: Failed to initialize HS3003 sensor via Arduino_HS3003 library!
```
**Solutions:**
- Verify **Arduino_HS3003** library is installed (NOT the obsolete HS300x library)
- Check board selection (Arduino Nano 33 BLE)
- Try pressing reset button

### BLE Initialization Failure
```
ERROR: Failed to start BLE!
```
**Solutions:**
- Verify ArduinoBLE library installed
- Check for library conflicts
- Restart Arduino IDE

### Connection Issues
- Ensure central device supports both services (0x1809 and 0x181A)
- Check serial monitor for "BLE CONNECTED" message
- Device shows as "Nano33BLE_Sensor" in BLE scans
- Try Arduino reset if no advertising

### Invalid Sensor Readings
```
SENSOR ERROR: Invalid reading
```
**Solutions:**
- Check sensor operating conditions
- Avoid condensation on sensor
- Allow warm-up time after power-on

## Technical Details

### Code Architecture
- **Modular Functions**: Clear separation of concerns
- **Circular Buffer**: Efficient 5-second averaging
- **State Management**: Simple connection tracking
- **Error Handling**: Graceful sensor failure recovery

### Memory Usage
- **Program Storage**: ~15% typical
- **Dynamic Memory**: ~10% typical
- **Sensor Arrays**: 200 bytes (2 × 25 × 4 bytes)
- **Stack Usage**: Minimal

### Bluetooth SIG Compliance
- **Standard UUIDs**: Official 16-bit assigned numbers
- **Service Separation**: Temperature and humidity in correct services
- **Data Format**: Native float for maximum compatibility
- **Advertising**: Proper service advertisement

## Compatibility
- **iOS**: Compatible with Core Bluetooth framework
- **Android**: Compatible with standard BLE APIs
- **Cross-Platform**: Standard BLE services work everywhere
- **Development Tools**: Works with generic BLE scanners/testers

## Version Information
- **Version**: 1.0 Simple
- **Target**: Arduino Nano 33 BLE Sense Rev2
- **Compiler**: Arduino IDE 2.0+
- **Libraries**: ArduinoBLE + Arduino_HS3003
- **Language**: C/C++