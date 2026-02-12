# Bluetooth SIG Standards Compliance

## Data Format Corrections

### ⚠️ Critical Correction Required

The original PRD incorrectly specified **uint16** for the Temperature characteristic (2A6E). According to the **Bluetooth SIG specification**, the correct formats are:

### Temperature Characteristic (UUID: 2A6E)
- **Format**: **sint16** (signed 16-bit integer)
- **Unit**: Degrees Celsius  
- **Resolution**: 0.01°C (value × 100)
- **Range**: -327.68°C to +327.67°C
- **Supports negative temperatures**: Essential for operating range -10°C to +70°C

### Humidity Characteristic (UUID: 2A6F)  
- **Format**: **uint16** (unsigned 16-bit integer) ✅ Correct
- **Unit**: Percent relative humidity
- **Resolution**: 0.01% (value × 100)
- **Range**: 0.00% to 655.35%

## Error Value Corrections

### Original (Incorrect)
- Temperature error: 64536 (invalid for sint16)
- Humidity error: 64536 (same value for both)

### Corrected (Standards Compliant)
- **Temperature error**: **-32768** (INT16_MIN for sint16)
- **Humidity error**: **65535** (UINT16_MAX for uint16)

## Implementation Changes

### Arduino Code Changes
```cpp
// Old (incorrect)
BLEUnsignedShortCharacteristic temperatureCharacteristic(...);  // uint16
uint16_t tempValue = (uint16_t)(temperature * 100);

// New (correct)
BLEShortCharacteristic temperatureCharacteristic(...);          // sint16
int16_t tempValue = (int16_t)(temperature * 100);
```

### Data Examples
```cpp
// Positive temperature: 23.50°C
int16_t tempValue = 2350;  // sint16

// Negative temperature: -5.00°C  
int16_t tempValue = -500;  // sint16 (impossible with uint16)

// Humidity: 45.20%
uint16_t humValue = 4520;  // uint16
```

## iOS App Compatibility

### iOS Parsing Code Changes Required
```swift
// Old (incorrect)
let tempC = parseTemperature(from: value)  // Assumes unsigned
return Float(raw) / 100.0

// New (correct)
let tempC = parseTemperature(from: value)  // Handle signed values
let raw = Int16(littleEndian: data.withUnsafeBytes { $0.load(as: Int16.self) })
return Float(raw) / 100.0  // Now supports negative temperatures
```

## Standards Compliance Benefits

1. **Interoperability**: Works with other Bluetooth SIG compliant devices
2. **Negative Temperature Support**: Essential for real-world applications
3. **Standard Error Handling**: Proper sentinel values for each data type
4. **Future Compatibility**: Follows official specifications

## Required Updates

### PRD Updates ✅
- Changed Temperature format from uint16 to sint16
- Updated error values to type-appropriate sentinels
- Added temperature range documentation

### Arduino Code Updates ✅
- `BLEShortCharacteristic` for temperature (sint16)
- `BLEUnsignedShortCharacteristic` for humidity (uint16)
- Proper error value constants
- Range validation and clamping

### iOS App Updates Required ⚠️
- Update `parseTemperature()` to handle signed values
- Change data type from `UInt16` to `Int16` for temperature
- Update error detection logic for new sentinel values

## Verification

Test cases to verify compliance:
- **Positive temperature**: 23.50°C → 2350 (sint16)
- **Negative temperature**: -5.00°C → -500 (sint16)  
- **Temperature error**: Sensor failure → -32768 (INT16_MIN)
- **Humidity**: 45.20% → 4520 (uint16)
- **Humidity error**: Sensor failure → 65535 (UINT16_MAX)

## Sensor Accuracy vs. Transmission Precision

**Important Distinction:**
- **Sensor Accuracy**: ±0.25°C (temperature), ±2.8% RH (humidity) - HS3003 hardware limits
- **Transmission Precision**: 0.01°C (temperature), 0.01% RH (humidity) - BLE format resolution

The BLE format can represent values to 0.01°C precision, but the underlying sensor accuracy is limited to ±0.25°C. This means readings may have higher precision than accuracy - a common characteristic in sensor systems.

This ensures full compliance with Bluetooth SIG Environmental Sensing Service specifications.