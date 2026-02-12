# Testing Instructions - TEST_Peripheral BLE Environmental Sensor

## Overview
This document provides comprehensive testing instructions for verifying the TEST_Peripheral BLE Environmental Sensor implementation using LightBlue Explorer as the primary BLE Central testing tool.

## Prerequisites
- **Hardware**: Arduino Nano 33 BLE Sense Rev2 with TEST_Peripheral firmware uploaded
- **Testing Tool**: LightBlue Explorer (iOS/macOS) - Available free on App Store
- **Alternative Tools**: nRF Connect (iOS/Android), BLE Scanner (Android)
- **Computer**: For Serial Monitor debugging (Arduino IDE or compatible)

---

## Phase 1: Hardware Verification

### Step 1.1: Upload and Initialize
1. **Upload Firmware**:
   - Open `TEST_Peripheral.ino` in Arduino IDE
   - Select board: "Arduino Nano 33 BLE"
   - Select correct port (typically `/dev/cu.usbmodem*`)
   - Upload firmware (Ctrl+U / Cmd+U)

2. **Verify Serial Output**:
   - Open Serial Monitor (115200 baud)
   - Press Arduino reset button if needed
   - Confirm initialization messages appear

### Step 1.2: Expected Initial Serial Output
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

Raw: 22.87°C, 45.3% | Avg(1): 22.87°C, 45.3% -> SENT
Raw: 22.89°C, 45.4% | Avg(2): 22.88°C, 45.4%
Raw: 22.85°C, 45.2% | Avg(3): 22.87°C, 45.3%
Raw: 22.88°C, 45.3% | Avg(4): 22.87°C, 45.3%
Raw: 22.86°C, 45.1% | Avg(5): 22.87°C, 45.3%
```

**✅ Verification Points:**
- Sensor initialization shows "SUCCESS"
- BLE initialization shows "SUCCESS"
- Device name is "Nano33BLE_Sensor"
- Raw readings appear every 1 second
- Average sample count increases to 5
- Temperature values are reasonable (15-30°C typical room temperature)
- Humidity values are reasonable (30-70%RH typical indoor humidity)

---

## Phase 2: LightBlue Explorer Testing

### Step 2.1: Device Discovery
1. **Open LightBlue Explorer**:
   - Launch LightBlue Explorer app on iOS/macOS
   - Ensure Bluetooth is enabled on device
   - Allow location permissions if prompted

2. **Scan for Device**:
   - Tap "Scan" or pull down to refresh
   - Look for device named **"Nano33BLE_Sensor"** in device list
   - Check RSSI value (should be -30 to -70 dBm for reasonable proximity)

3. **Device Information Verification**:
   - Device should appear with a clear signal strength indicator
   - UUID should be visible (if shown by LightBlue Explorer)
   - Device type should indicate "Peripheral"

### Step 2.2: Connection Establishment
1. **Connect to Device**:
   - Tap on "Nano33BLE_Sensor" in device list
   - Connection should establish within 2 seconds
   - Device status should change to "Connected"

2. **Monitor Serial Output During Connection**:
```
BLE CONNECTED: Central device connected
Raw: 22.84°C, 45.2% | Avg(5): 22.86°C, 45.2% -> SENT
BLE TX: 22.86°C, 45.2%
Raw: 22.87°C, 45.4% | Avg(5): 22.86°C, 45.3%
Raw: 22.85°C, 45.1% | Avg(5): 22.86°C, 45.2% -> SENT
BLE TX: 22.86°C, 45.2%
```

**✅ Connection Verification:**
- Serial shows "BLE CONNECTED: Central device connected"
- First reading after connection is transmitted ("-> SENT")
- "BLE TX:" messages appear with precise formatting
- Subsequent readings follow 1-second interval

### Step 2.3: Service Discovery
1. **Verify Services**:
   - In LightBlue Explorer, services should automatically load
   - Look for **two services**:
     - **Health Thermometer** service with UUID `1809`
     - **Environmental Sensing** service with UUID `181A`

2. **Service Details**:
   - Each service should show as "Primary Service"
   - Services should be expandable to show characteristics
   - No additional services should be present (clean implementation)

### Step 2.4: Characteristic Testing - Temperature

1. **Expand Health Thermometer Service (1809)**:
   - Tap to expand the service
   - Find **Temperature Measurement** characteristic: `2A1C`
   - Verify properties show: **Read ✓, Notify ✓**

2. **Test Read Operation**:
   - Tap "Read" button/option for characteristic `2A1C`
   - Value should appear as a float (e.g., `22.86`)
   - Value should be reasonable room temperature (15-30°C typical)
   - Value should match recent "BLE TX:" temperature from serial output

3. **Test Notify Operation**:
   - Enable notifications for characteristic `2A1C`
   - Should see "Notifications Enabled" or checkmark indicator
   - Values should update approximately every 1 second
   - Updates should occur when temperature changes by ≥0.1°C

4. **Expected LightBlue Explorer Display**:
```
🌡️ Health Thermometer (1809)
  └── Temperature Measurement (2A1C)
      ├── Properties: Read, Notify
      ├── Value: 22.86 (float)
      └── Notifications: ✅ Enabled
```

### Step 2.5: Characteristic Testing - Humidity

1. **Expand Environmental Sensing Service (181A)**:
   - Tap to expand the service
   - Find **Relative Humidity** characteristic: `2A6F`
   - Verify properties show: **Read ✓, Notify ✓**

2. **Test Read Operation**:
   - Tap "Read" button/option for characteristic `2A6F`
   - Value should appear as a float (e.g., `45.2`)
   - Value should be reasonable humidity (20-80%RH typical indoor)
   - Value should match recent "BLE TX:" humidity from serial output

3. **Test Notify Operation**:
   - Enable notifications for characteristic `2A6F`
   - Should see "Notifications Enabled" or checkmark indicator
   - Values should update approximately every 1 second
   - Updates should occur when humidity changes by ≥0.5%RH

4. **Expected LightBlue Explorer Display**:
```
💧 Environmental Sensing (181A)
  └── Relative Humidity (2A6F)
      ├── Properties: Read, Notify
      ├── Value: 45.2 (float)
      └── Notifications: ✅ Enabled
```

---

## Phase 3: Data Validation Testing

### Step 3.1: Real-Time Data Monitoring
1. **Enable Both Notifications**:
   - Ensure both temperature and humidity notifications are enabled
   - Both characteristics should show active notification status
   - Values should update every ~1 second

2. **Serial Output with Active Connection**:
```
Raw: 22.89°C, 45.4% | Avg(5): 22.87°C, 45.3%
Raw: 22.91°C, 45.5% | Avg(5): 22.88°C, 45.4% -> SENT
BLE TX: 22.88°C, 45.4%
Raw: 22.88°C, 45.3% | Avg(5): 22.88°C, 45.4%
Raw: 22.86°C, 45.2% | Avg(5): 22.87°C, 45.3%
Raw: 22.85°C, 45.1% | Avg(5): 22.86°C, 45.2% -> SENT
BLE TX: 22.86°C, 45.2%
```

3. **Data Validation Checklist**:
   - ✅ Serial "Raw:" values change slightly each second
   - ✅ "Avg(5):" values are smoothed compared to raw values
   - ✅ "-> SENT" appears when thresholds exceeded (0.1°C, 0.5%RH)
   - ✅ "BLE TX:" values match LightBlue Explorer received values
   - ✅ LightBlue Explorer shows updates corresponding to transmissions

### Step 3.2: Change Detection Testing
1. **Temperature Change Test**:
   - Gently breathe on Arduino sensor or hold finger near sensor
   - Should see raw temperature increase in serial output
   - When average change ≥0.1°C, should see "-> SENT" and "BLE TX:"
   - LightBlue Explorer should show updated temperature value

2. **Humidity Change Test**:
   - Breathe gently on sensor (moisture increases humidity)
   - Should see raw humidity increase in serial output
   - When average change ≥0.5%RH, should see "-> SENT" and "BLE TX:"
   - LightBlue Explorer should show updated humidity value

3. **Expected Response Pattern**:
```
Raw: 22.85°C, 45.2% | Avg(5): 22.86°C, 45.2%
Raw: 23.12°C, 47.8% | Avg(5): 22.94°C, 45.8% -> SENT  [Temperature +0.08°C]
BLE TX: 22.94°C, 45.8%
Raw: 23.45°C, 49.3% | Avg(5): 23.08°C, 46.5% -> SENT  [Temperature +0.14°C]
BLE TX: 23.08°C, 46.5%
```

---

## Phase 4: Connection Behavior Testing

### Step 4.1: Advertising Stop Verification
1. **Before Connection**:
   - Arduino should be visible in BLE scanner
   - Device should appear as available for connection

2. **During Connection**:
   - After successful connection, device should stop advertising
   - New BLE scans should NOT show "Nano33BLE_Sensor" (advertising stopped)
   - Connection should remain stable

### Step 4.2: Disconnection and Reconnection
1. **Disconnect Test**:
   - In LightBlue Explorer, tap "Disconnect" or back button
   - Monitor serial output for disconnection message

2. **Expected Serial Output on Disconnect**:
```
BLE DISCONNECTED: Central device disconnected
Restarting advertising...
Raw: 22.87°C, 45.3% | Avg(5): 22.86°C, 45.3%
Raw: 22.85°C, 45.1% | Avg(5): 22.85°C, 45.2%
```

3. **Verify Advertising Restart**:
   - Device should reappear in LightBlue Explorer scan within 3 seconds
   - Should be able to reconnect successfully
   - All services and characteristics should work identically

---

## Phase 5: Error Condition Testing

### Step 5.1: Sensor Error Simulation
**Note**: This test requires physically disconnecting the HS3003 sensor or simulating sensor failure, which may not be practical for integrated sensors. Skip if not applicable.

1. **Expected Behavior on Sensor Failure**:
   - BLE services remain available
   - Characteristics show 0.0 values
   - Serial output shows error messages
   - System continues operating

### Step 5.2: Range Testing
1. **Distance Test**:
   - Gradually move away from Arduino while connected
   - Monitor connection stability in LightBlue Explorer
   - Typical range: 5-10 meters indoors
   - Connection should gracefully handle signal degradation

2. **Signal Strength Monitoring**:
   - LightBlue Explorer may show RSSI values
   - Good: -30 to -50 dBm
   - Acceptable: -50 to -70 dBm
   - Poor: -70 to -90 dBm (may disconnect)

---

## Phase 6: Performance Validation

### Step 6.1: Timing Validation
1. **Sample Rate Verification**:
   - Monitor serial output timestamps
   - Raw readings should appear every 1000ms (±50ms tolerance)
   - Use stopwatch to verify 5 readings in ~5 seconds

2. **BLE Update Rate Verification**:
   - Enable notifications in LightBlue Explorer
   - Monitor update frequency
   - Should receive updates every ~1 second (when values change)

### Step 6.2: Data Quality Assessment
1. **Averaging Effectiveness**:
   - Raw values should show minor fluctuations
   - Averaged values should be smoother/more stable
   - Compare Raw vs Avg values in serial output

2. **Precision Verification**:
   - Temperature values should show 2 decimal places (e.g., 22.87°C)
   - Humidity values should show 1 decimal place (e.g., 45.3%RH)
   - BLE TX values should match this precision

---

## Troubleshooting Guide

### Device Not Found in LightBlue Explorer
**Symptoms**: "Nano33BLE_Sensor" doesn't appear in scan results

**Solutions**:
1. Check Arduino power (USB connected, power LED on)
2. Verify serial output shows "SUCCESS: BLE advertising"
3. Press Arduino reset button and wait 10 seconds
4. Move closer to Arduino (within 2 meters)
5. Try refreshing LightBlue Explorer scan (pull down)
6. Check iOS Bluetooth is enabled in Settings

### Connection Fails or Immediately Disconnects
**Symptoms**: Connection attempt fails or disconnects within seconds

**Solutions**:
1. Close and reopen LightBlue Explorer
2. Reset Arduino and wait for full initialization
3. Move closer to reduce interference
4. Turn iOS Bluetooth off/on in Settings
5. Try connecting with different device or app

### Services Not Discovered
**Symptoms**: Connection succeeds but no services appear

**Solutions**:
1. Wait 5-10 seconds for service discovery to complete
2. Disconnect and reconnect
3. Check serial output for BLE initialization errors
4. Verify both services (1809, 181A) are shown in LightBlue Explorer
5. Try tapping refresh or reload in LightBlue Explorer

### Characteristics Show No Data or Wrong Values
**Symptoms**: Characteristics exist but show no values or incorrect values

**Solutions**:
1. Tap "Read" manually to force data retrieval
2. Check serial output for sensor errors
3. Compare LightBlue Explorer values with "BLE TX:" in serial output
4. Ensure notifications are properly enabled
5. Verify temperature is in °C range (15-30°C typical), humidity in %RH (20-80% typical)

### Notifications Not Updating
**Symptoms**: Initial read works but notifications don't provide updates

**Solutions**:
1. Disable and re-enable notifications
2. Check for active connection (signal strength)
3. Verify serial shows "-> SENT" messages
4. Ensure device is within good signal range
5. Try breathing on sensor to force value changes

---

## Expected Test Results Summary

### ✅ Successful Test Completion Checklist
- [ ] Device "Nano33BLE_Sensor" discovered in LightBlue Explorer
- [ ] Connection establishes within 2 seconds
- [ ] Both services (1809, 181A) are discovered
- [ ] Both characteristics (2A1C, 2A6F) support Read and Notify
- [ ] Temperature values are reasonable and formatted to 2 decimal places
- [ ] Humidity values are reasonable and formatted to 1 decimal place
- [ ] Notifications update approximately every 1 second
- [ ] Values in LightBlue Explorer match serial "BLE TX:" output
- [ ] Device stops advertising when connected
- [ ] Device resumes advertising when disconnected
- [ ] Automatic reconnection works successfully
- [ ] 5-sample averaging provides stable values
- [ ] Change detection triggers transmissions appropriately

### 📊 Performance Benchmarks
- **Connection Time**: <2 seconds from scan to connected
- **Service Discovery**: <1 second to show both services
- **Data Update Rate**: Every 1 second (±100ms tolerance)
- **Signal Range**: 5-10 meters typical indoor environment
- **Data Precision**: Temperature 0.01°C, Humidity 0.1%RH
- **Averaging Window**: Exactly 5 samples over 5 seconds

---

## Test Report Template

### Test Session Information
- **Date**: ___________
- **Tester**: ___________
- **Arduino Firmware Version**: TEST_Peripheral v1.0
- **LightBlue Explorer Version**: ___________
- **iOS Version**: ___________

### Test Results
| Test Phase | Status | Notes |
|------------|--------|-------|
| Hardware Initialization | ✅ ❌ | |
| Device Discovery | ✅ ❌ | |
| Connection Establishment | ✅ ❌ | |
| Service Discovery | ✅ ❌ | |
| Temperature Characteristic | ✅ ❌ | |
| Humidity Characteristic | ✅ ❌ | |
| Notification Functionality | ✅ ❌ | |
| Data Validation | ✅ ❌ | |
| Connection Behavior | ✅ ❌ | |
| Performance Validation | ✅ ❌ | |

### Issues Encountered
_Document any problems, error messages, or unexpected behavior_

### Recommendations
_Suggest improvements or follow-up actions_

---

**Document Version**: 1.0
**Last Updated**: September 25, 2025
**Compatible with**: TEST_Peripheral Arduino firmware v1.0