# Test Plan Document (TPD)
## Arduino BLE Environmental Sensor + iOS BLE Central App

---

### Document Information
- **Version**: 1.0
- **Date**: July 19, 2025
- **Author**: QA Team
- **Status**: Final

---

## 1. Test Overview

### 1.1 Purpose
This Test Plan Document (TPD) defines the comprehensive testing strategy for validating proper operation between the Arduino Nano 33 Sense Rev 2 BLE peripheral and the iOS BLE Central app, with critical focus on signed temperature data handling and negative temperature support.

### 1.2 Scope
Testing encompasses:
- Arduino BLE peripheral functionality and sensor accuracy
- iOS BLE Central app integration and data parsing
- End-to-end system validation with real environmental conditions
- Widget and Siri integration functionality
- Extended operation and reliability testing

### 1.3 Test Objectives
- **Primary**: Verify Int16 signed temperature parsing correctly displays negative temperatures
- **Secondary**: Validate BLE communication protocol compliance (sint16/uint16 format)
- **Tertiary**: Confirm system reliability and accuracy within specified tolerances

---

## 2. Test Environment

### 2.1 Hardware Under Test

#### 2.1.1 Arduino Platform
- **Device**: Arduino Nano 33 Sense Rev 2
- **Microcontroller**: Nordic nRF52840 (ARM Cortex-M4)
- **Onboard Sensor**: HS3003 (temperature/humidity)
- **Connectivity**: Bluetooth 5.0 Low Energy
- **Power**: USB 5V supply during testing
- **Firmware**: BLE_Sensor_Peripheral_BLE_Standards.ino (Bluetooth SIG compliant)

#### 2.1.2 iOS Platform  
- **Device**: iPhone 15 Pro Max
- **Operating System**: iOS 17.0+ (latest available)
- **Processor**: A17 Pro chip
- **Bluetooth**: Bluetooth 5.3 with BLE support
- **App Version**: BLE Central (latest build with Int16 temperature parsing)
- **Test Configuration**: Airplane mode OFF, Bluetooth ON, Background App Refresh enabled

### 2.2 Software Requirements

#### 2.2.1 Arduino Development Environment
- **IDE**: Arduino IDE 2.0+
- **Board Package**: Arduino Mbed OS Nano Boards (latest stable)
- **Required Libraries**:
  - ArduinoBLE (latest stable version)
  - Arduino_HS300x (for HS3003 sensor)
- **Serial Monitor**: 115200 baud rate

#### 2.2.2 iOS Development Environment
- **Xcode**: 15.0+ (for debugging and console access)
- **iOS Deployment Target**: iOS 14.0 minimum, testing on iOS 17.0+
- **Debug Configuration**: Enable BLE logging, console output capture
- **App Store Build**: Production configuration for final validation

### 2.3 Test Equipment and Tools

#### 2.3.1 Measurement Instruments
- **Reference Thermometer**: Calibrated digital thermometer (±0.1°C accuracy minimum)
- **Reference Hygrometer**: Calibrated digital hygrometer (±1% RH accuracy minimum)
- **Multimeter**: For power consumption measurements
- **BLE Analyzer**: nRF Connect app (iOS version) for packet inspection

#### 2.3.2 Environmental Control Equipment
- **Freezer Access**: For negative temperature testing (-18°C to -10°C range)
- **Heat Source**: Hair dryer or heat gun for controlled warming (up to 50°C)
- **Humidity Control**: Desiccant packs (dry conditions) and humidifier (humid conditions)
- **Controlled Environment**: Indoor laboratory space (20-25°C, 40-60% RH)

#### 2.3.3 Documentation Tools
- **Camera**: For screenshot documentation of iOS app displays
- **Screen Recording**: iOS screen recording for dynamic test scenarios
- **Data Logging**: Excel/CSV for test result compilation
- **Serial Capture**: Arduino IDE serial monitor log export

---

## 3. Test Strategy

### 3.1 Testing Approach
- **Bottom-up Integration**: Arduino unit testing → iOS integration → System validation
- **Risk-based Testing**: Critical focus on negative temperature parsing (primary risk area)
- **Environment-driven**: Real-world conditions with reference instrument validation
- **Automated Logging**: Continuous data capture for trend analysis

### 3.2 Test Phases

#### 3.2.1 Phase 1: Component Validation (Day 1)
**Objective**: Verify individual component functionality
**Duration**: 4 hours
**Focus**: Arduino sensor accuracy, iOS app basic functionality

#### 3.2.2 Phase 2: Integration Testing (Day 2)  
**Objective**: Validate BLE communication and data parsing
**Duration**: 6 hours
**Focus**: Critical negative temperature test, real-time data synchronization

#### 3.2.3 Phase 3: Environmental Testing (Day 3-4)
**Objective**: System validation across operating temperature/humidity ranges
**Duration**: 16 hours (including overnight stability test)
**Focus**: Accuracy validation, extreme condition handling

#### 3.2.4 Phase 4: Extended Operation (Day 5)
**Objective**: Long-term reliability and iOS app lifecycle testing
**Duration**: 8 hours
**Focus**: Battery life, app state transitions, widget synchronization

### 3.3 Entry and Exit Criteria

#### 3.3.1 Entry Criteria
- ✅ Arduino Nano 33 Sense Rev 2 with latest firmware uploaded
- ✅ iPhone 15 Pro Max with iOS BLE Central app installed (Int16 parsing version)
- ✅ All test equipment calibrated and operational
- ✅ Controlled test environment available
- ✅ Reference instruments validated against known standards

#### 3.3.2 Exit Criteria
- ✅ All critical test cases passed (95% minimum pass rate)
- ✅ Negative temperature display verified across range (-20°C to 0°C)
- ✅ BLE communication stability demonstrated (>95% uptime over 24 hours)
- ✅ Accuracy within specifications (±0.5°C temp, ±2% humidity)
- ✅ No critical defects remaining unresolved

---

## 4. Test Cases

### 4.1 Arduino Component Testing

#### TC-A001: HS3003 Sensor Initialization
**Objective**: Verify onboard sensor proper initialization
**Preconditions**: Fresh Arduino power-on, serial monitor active
**Test Steps**:
1. Connect Arduino Nano 33 Sense Rev 2 to USB power
2. Open serial monitor at 115200 baud
3. Observe initialization messages
**Expected Results**: 
- Serial output: "HS3003 sensor initialized successfully"
- No error messages related to sensor communication
**Pass Criteria**: Sensor initialization message appears within 10 seconds
**Risk Level**: High (sensor dependency)

#### TC-A002: BLE Service Advertisement
**Objective**: Confirm BLE Environmental Sensing Service advertisement
**Preconditions**: Arduino powered and sensor initialized
**Test Steps**:
1. Monitor serial output for BLE status
2. Use nRF Connect app on iPhone 15 Pro Max to scan for devices
3. Locate "Arduino Sensor" in device list
**Expected Results**:
- Serial: "BLE advertising as 'Arduino Sensor' with 1-second interval"
- nRF Connect: Device appears with Environmental Sensing Service (181A)
**Pass Criteria**: Device discoverable within 30 seconds of power-on
**Risk Level**: High (communication foundation)

#### TC-A003: Sensor Reading Accuracy Baseline
**Objective**: Validate sensor readings against reference instruments
**Preconditions**: Controlled environment (22°C ±1°C, 45% ±5% RH)
**Test Steps**:
1. Place reference thermometer and hygrometer adjacent to Arduino
2. Allow 10-minute stabilization period
3. Compare Arduino serial output to reference readings for 30 minutes
**Expected Results**:
- Temperature accuracy: Within ±0.25°C of reference (HS3003 specification)
- Humidity accuracy: Within ±2.8% RH of reference (HS3003 specification)
**Pass Criteria**: 95% of readings within specification over test period
**Risk Level**: Medium (accuracy foundation)

#### TC-A004: Temperature Data Format Validation (Positive)
**Objective**: Confirm sint16 format for positive temperatures
**Preconditions**: Arduino at room temperature (~23°C)
**Test Steps**:
1. Monitor serial output for temperature transmissions
2. Verify sint16 format in transmission logs
3. Calculate expected value: 23.5°C × 100 = 2350
**Expected Results**:
- Serial: "Transmitted - Temp: 23.5°C (sint16: 2350)"
- Value matches calculation within rounding tolerance
**Pass Criteria**: Transmitted sint16 values match expected calculations
**Risk Level**: High (data format compliance)

#### TC-A005: Temperature Data Format Validation (Negative) ⭐ CRITICAL
**Objective**: Confirm sint16 format for negative temperatures  
**Preconditions**: Arduino cooled to sub-zero temperature (freezer)
**Test Steps**:
1. Place Arduino in freezer for 15 minutes minimum
2. Monitor serial output while maintaining USB connection (extended cable)
3. Verify negative sint16 values transmitted
4. Calculate expected: -10.0°C × 100 = -1000
**Expected Results**:
- Serial: "Transmitted - Temp: -10.0°C (sint16: -1000)"
- Negative values properly formatted as signed integers
**Pass Criteria**: Negative temperatures transmitted as correct negative sint16 values
**Risk Level**: Critical (core functionality requirement)

#### TC-A006: Error Value Transmission
**Objective**: Verify error handling when sensor fails
**Preconditions**: Arduino operational, sensor accessible
**Test Steps**:
1. Simulate sensor disconnection or failure (if possible)
2. Monitor serial output for error detection
3. Verify error value transmission
**Expected Results**:
- Serial: "Transmitted error values - Temp: -32768 (sint16), Humidity: 65535 (uint16)"
- Error values comply with Bluetooth SIG standards
**Pass Criteria**: Correct error values transmitted on sensor failure
**Risk Level**: Medium (error handling)

### 4.2 iOS Integration Testing

#### TC-I001: Device Discovery and Connection
**Objective**: Verify iPhone 15 Pro Max can discover and connect to Arduino
**Preconditions**: Arduino advertising, iOS app launched, Bluetooth enabled
**Test Steps**:
1. Launch BLE Central app on iPhone 15 Pro Max
2. Verify app scans for BLE devices automatically
3. Confirm connection establishment
4. Check connection status display
**Expected Results**:
- App displays "Scanning..." then "Connecting..." then "Connected"
- Arduino serial shows "Device connected"
- Connection established within 30 seconds
**Pass Criteria**: Successful automatic connection without user intervention
**Risk Level**: High (system integration foundation)

#### TC-I002: Service and Characteristic Discovery  
**Objective**: Confirm iOS app discovers Environmental Sensing Service
**Preconditions**: BLE connection established (TC-I001 passed)
**Test Steps**:
1. Monitor iOS app for service discovery
2. Verify characteristic access (temperature 2A6E, humidity 2A6F)
3. Check for initial data reception
**Expected Results**:
- App accesses Environmental Sensing Service (181A)
- Temperature and humidity characteristics available
- Initial sensor readings displayed (not "--")
**Pass Criteria**: Service discovery completes, initial data displayed within 10 seconds
**Risk Level**: High (data access foundation)

#### TC-I003: Positive Temperature Display Accuracy
**Objective**: Validate iOS displays positive temperatures correctly
**Preconditions**: Arduino at room temperature, connected to iOS
**Test Steps**:
1. Note Arduino serial temperature transmission (e.g., sint16: 2350)
2. Observe iOS app temperature display
3. Verify calculation: 2350 ÷ 100 = 23.5°C displayed as "23.5 °C"
**Expected Results**:
- iOS display matches Arduino serial output calculation
- Temperature format includes "°C" unit
- Value updates within 5 seconds of Arduino transmission
**Pass Criteria**: Displayed temperature matches expected calculation within ±0.1°C
**Risk Level**: Medium (display accuracy)

#### TC-I004: Negative Temperature Display Accuracy ⭐ CRITICAL
**Objective**: Verify iOS correctly parses and displays negative temperatures
**Preconditions**: Arduino in freezer (~-10°C), BLE connection maintained
**Test Steps**:
1. Cool Arduino to negative temperature (TC-A005 setup)
2. Monitor Arduino serial: "Transmitted - Temp: -10.0°C (sint16: -1000)"
3. Verify iOS parsing: Int16(-1000) ÷ 100.0 = -10.0°C  
4. Confirm iOS displays "-10.0 °C" with negative sign visible
**Expected Results**:
- iOS app displays negative temperature with minus sign
- Value accuracy matches Arduino transmission
- No parsing errors or positive value display
**Pass Criteria**: Negative temperatures displayed correctly with visible minus sign
**Risk Level**: Critical (primary test objective, core functionality)

#### TC-I005: Humidity Display Accuracy
**Objective**: Validate iOS displays humidity values correctly
**Preconditions**: Arduino at measurable humidity level, connected to iOS
**Test Steps**:
1. Note Arduino serial humidity transmission (e.g., uint16: 4520)
2. Observe iOS app humidity display  
3. Verify calculation: 4520 ÷ 100 = 45.2% displayed as "45.2 %"
**Expected Results**:
- iOS display matches Arduino calculation  
- Humidity format includes "%" unit
- Value updates following Arduino change thresholds
**Pass Criteria**: Displayed humidity matches calculation within ±0.1%
**Risk Level**: Medium (display accuracy)

#### TC-I006: Real-Time Data Synchronization
**Objective**: Verify iOS updates follow Arduino change-based transmission
**Preconditions**: Arduino and iOS connected, stable baseline readings
**Test Steps**:
1. Create temperature change >0.5°C (hand warming)
2. Monitor Arduino serial for threshold-triggered transmission
3. Verify iOS app updates correspondingly
4. Repeat with humidity change >2% (breath moisture)
**Expected Results**:
- iOS updates within 5 seconds of Arduino transmission
- Changes align with Arduino change threshold logic (±0.5°C temp, ±2% humidity)
- Smooth value transitions, no sudden jumps
**Pass Criteria**: iOS updates correspond to Arduino transmissions with <5 second latency
**Risk Level**: Medium (real-time functionality)

#### TC-I007: Widget Data Synchronization  
**Objective**: Confirm iOS widget displays current sensor values
**Preconditions**: BLE Central widget added to iPhone 15 Pro Max home screen
**Test Steps**:
1. Verify main app displays current sensor readings
2. Navigate to home screen and check widget values
3. Create sensor value changes (temperature/humidity)
4. Verify widget updates to match main app
**Expected Results**:
- Widget shows same values as main app
- Widget updates within 10 seconds of sensor changes
- Format: "Temperature: XX.X°C" and "Humidity: XX.X%"
**Pass Criteria**: Widget values match main app within ±0.1°C/0.1%
**Risk Level**: Low (auxiliary functionality)

#### TC-I008: Siri Integration Testing
**Objective**: Validate voice query responses for sensor data
**Preconditions**: Siri enabled, BLE Central app configured for App Intents
**Test Steps**:
1. Activate Siri: "Hey Siri, get temperature from BLE Central"
2. Note response value and format
3. Compare to current app display
4. Repeat for humidity: "Hey Siri, get humidity from BLE Central"
**Expected Results**:
- Siri returns current temperature value with units
- Siri returns current humidity value with percentage
- Values match current app display
**Pass Criteria**: Siri responses match app display values within ±0.5°C/±2%
**Risk Level**: Low (auxiliary functionality)

### 4.3 Environmental Validation Testing

#### TC-E001: Freezer Temperature Range Testing ⭐ CRITICAL
**Objective**: Validate negative temperature accuracy across freezer range
**Preconditions**: Freezer access (-18°C typical), extended USB cable
**Test Steps**:
1. Place Arduino in freezer with reference thermometer
2. Monitor temperature descent over 20 minutes
3. Verify iOS displays negative temperatures correctly throughout range
4. Document accuracy at -10°C, -15°C, -18°C waypoints
**Expected Results**:
- iOS displays negative temperatures with minus sign visible
- Accuracy within ±0.5°C compared to reference thermometer
- No display errors or positive value artifacts
**Pass Criteria**: Negative temperature display accuracy maintained across -5°C to -20°C range
**Risk Level**: Critical (core environmental validation)

#### TC-E002: Heating Temperature Range Testing
**Objective**: Validate positive temperature accuracy across heated range
**Preconditions**: Heat source (hair dryer), controlled warming setup
**Test Steps**:
1. Gradually warm Arduino from room temperature to 45°C
2. Monitor iOS displays during temperature rise
3. Compare to reference thermometer throughout range
4. Verify no overflow or parsing errors at higher temperatures
**Expected Results**:
- iOS displays track temperature increases smoothly
- Accuracy maintained throughout 25°C to 45°C range
- No value jumps or display artifacts
**Pass Criteria**: Temperature display accuracy within ±0.5°C across tested range
**Risk Level**: Medium (extended range validation)

#### TC-E003: Humidity Range Validation
**Objective**: Test humidity accuracy across achievable range
**Preconditions**: Humidity control methods (desiccant/humidifier)
**Test Steps**:
1. Create dry conditions (30% RH target) using desiccant
2. Monitor humidity readings vs. reference hygrometer
3. Create humid conditions (70% RH target) using humidifier
4. Verify iOS displays track humidity changes accurately
**Expected Results**:
- iOS humidity displays match reference within ±2% RH
- Smooth transitions during humidity changes
- Change thresholds (±2%) trigger appropriately
**Pass Criteria**: Humidity accuracy within ±2% RH across 30-70% range
**Risk Level**: Medium (environmental validation)

#### TC-E004: Combined Environmental Stress
**Objective**: Test system under simultaneous temperature and humidity changes
**Preconditions**: Hot, humid environment setup (bathroom shower simulation)
**Test Steps**:
1. Create warm, humid environment (35°C, 80% RH target)
2. Monitor both sensors simultaneously
3. Verify independent operation (no cross-interference)
4. Check BLE transmission stability under stress
**Expected Results**:
- Both temperature and humidity track environmental changes
- No sensor cross-interference observed
- BLE connection remains stable
- iOS displays both parameters accurately
**Pass Criteria**: Both sensors operate independently with specified accuracy
**Risk Level**: Medium (system stress testing)

### 4.4 Extended Operation Testing

#### TC-L001: 24-Hour Continuous Operation
**Objective**: Validate system stability over extended period
**Preconditions**: Arduino USB powered, iPhone 15 Pro Max charging available
**Test Steps**:
1. Establish stable BLE connection and baseline readings
2. Monitor system operation for 24 hours minimum
3. Log all sensor readings, BLE events, and iOS app behavior
4. Check for memory leaks, connection drops, or degraded performance
**Expected Results**:
- BLE connection maintained >95% of test period
- Sensor readings remain stable and accurate
- iOS app remains responsive throughout test
- No memory or performance degradation observed
**Pass Criteria**: System operates stably for 24+ hours with <5% downtime
**Risk Level**: High (reliability validation)

#### TC-L002: iOS App Lifecycle Testing
**Objective**: Verify app behavior through iOS state transitions
**Preconditions**: Active BLE connection and data monitoring
**Test Steps**:
1. Background app during active monitoring (home button)
2. Receive phone call during monitoring
3. Lock/unlock iPhone 15 Pro Max multiple times
4. Force-quit and restart app
5. Verify data continuity and BLE reconnection
**Expected Results**:
- App maintains sensor readings through state transitions
- BLE reconnection occurs within 30 seconds after app restart
- No data corruption or display errors
- Widget continues functioning during app backgrounding
**Pass Criteria**: App maintains functionality through all iOS lifecycle states
**Risk Level**: Medium (mobile app robustness)

#### TC-L003: Power Management Validation
**Objective**: Measure Arduino power consumption and battery life projection
**Preconditions**: Arduino on battery power (external battery pack), multimeter available
**Test Steps**:
1. Connect multimeter to measure Arduino current consumption
2. Monitor power draw during various operational states:
   - Idle (no BLE connection)
   - Connected but no data changes
   - Active data transmission
3. Calculate projected battery life based on measurements
**Expected Results**:
- Power consumption aligns with PRD objectives
- Change-based transmission reduces average power draw
- Battery life projection >24 hours for typical operation
**Pass Criteria**: Measured power consumption meets PRD battery life objectives
**Risk Level**: Medium (power efficiency validation)

### 4.5 Error Handling and Recovery Testing

#### TC-R001: BLE Disconnection Recovery
**Objective**: Verify automatic reconnection after BLE range loss
**Preconditions**: Stable BLE connection established
**Test Steps**:
1. Move iPhone 15 Pro Max beyond BLE range (>15 meters)
2. Monitor Arduino serial for disconnection detection
3. Return to range and verify automatic reconnection
4. Check data transmission resumption
**Expected Results**:
- Arduino detects disconnection: "Device disconnected - restarting advertising"
- iPhone reconnects automatically within 30 seconds of return to range
- Data transmission resumes without user intervention
**Pass Criteria**: Automatic reconnection occurs within 30 seconds of range return
**Risk Level**: Medium (connection reliability)

#### TC-R002: Sensor Error Handling
**Objective**: Validate error display when Arduino sensor fails
**Preconditions**: Normal operation established
**Test Steps**:
1. Simulate HS3003 sensor failure (if possible via disconnection)
2. Verify Arduino transmits error values (-32768, 65535)
3. Confirm iOS app displays error condition appropriately
4. Restore sensor operation and verify recovery
**Expected Results**:
- Arduino serial: "Transmitted error values"
- iOS app displays "--" for both temperature and humidity
- Normal display resumes when sensor operation restored
**Pass Criteria**: Error condition displayed appropriately, recovery successful
**Risk Level**: Medium (error handling robustness)

#### TC-R003: iOS Bluetooth Permission Recovery  
**Objective**: Test app behavior when Bluetooth permissions change
**Preconditions**: App operating normally with Bluetooth enabled
**Test Steps**:
1. Disable Bluetooth in iOS Settings during active monitoring
2. Observe app behavior and user feedback
3. Re-enable Bluetooth and verify automatic recovery
4. Check for appropriate user notifications
**Expected Results**:
- App displays appropriate Bluetooth unavailable message
- No crashes or undefined behavior during Bluetooth off state
- Automatic recovery when Bluetooth re-enabled
**Pass Criteria**: Graceful handling of Bluetooth state changes with user feedback
**Risk Level**: Low (permissions handling)

---

## 5. Test Data and Metrics

### 5.1 Key Performance Indicators (KPIs)

#### 5.1.1 Accuracy Metrics
- **Temperature Accuracy**: ±0.5°C throughout -20°C to +50°C range
- **Humidity Accuracy**: ±2% RH throughout 30% to 80% RH range  
- **Reference Correlation**: >95% of readings within specification vs. calibrated instruments

#### 5.1.2 Performance Metrics
- **BLE Connection Success Rate**: >95% successful connections
- **Connection Stability**: >95% uptime over 24-hour period
- **Data Transmission Latency**: <5 seconds from Arduino to iOS display
- **App Response Time**: <2 seconds for user interactions

#### 5.1.3 Reliability Metrics
- **System Availability**: >99% operational time during test period
- **Error Recovery Success**: 100% successful recovery from handled error conditions
- **Battery Life**: >24 hours continuous operation (Arduino on battery)

### 5.2 Pass/Fail Criteria

#### 5.2.1 Critical Test Cases (Must Pass)
- **TC-A005**: Negative temperature sint16 format validation
- **TC-I004**: iOS negative temperature display accuracy  
- **TC-E001**: Freezer temperature range testing
- **TC-L001**: 24-hour continuous operation

#### 5.2.2 High Priority Test Cases (95% Pass Rate Required)
- All Arduino component tests (TC-A001 through TC-A006)
- All iOS integration tests (TC-I001 through TC-I006)  
- Environmental validation tests (TC-E001 through TC-E003)

#### 5.2.3 Medium Priority Test Cases (90% Pass Rate Required)  
- Extended operation tests (TC-L002, TC-L003)
- Error handling and recovery tests (TC-R001 through TC-R003)
- Widget and Siri integration tests (TC-I007, TC-I008)

### 5.3 Test Environment Specifications

#### 5.3.1 Controlled Environment Parameters
- **Ambient Temperature**: 22°C ± 2°C during baseline testing
- **Ambient Humidity**: 45% ± 10% RH during baseline testing
- **Electromagnetic Interference**: Minimal (laboratory environment)
- **Physical Stability**: Vibration-free mounting for Arduino during testing

#### 5.3.2 Reference Instrument Specifications
- **Thermometer Accuracy**: ±0.1°C minimum (NIST traceable preferred)
- **Hygrometer Accuracy**: ±1% RH minimum (NIST traceable preferred)
- **Calibration Status**: Current calibration certificates required
- **Measurement Range**: -25°C to +60°C (thermometer), 10% to 90% RH (hygrometer)

---

## 6. Test Execution Schedule

### 6.1 Test Phase Timeline

#### 6.1.1 Phase 1: Component Validation (Day 1)
**Duration**: 8 hours
**Scope**: TC-A001 through TC-A006, basic iOS functionality
**Deliverables**: Component validation report, baseline accuracy measurements
**Critical Milestone**: TC-A005 (negative temperature format) must pass

#### 6.1.2 Phase 2: Integration Testing (Day 2)
**Duration**: 8 hours  
**Scope**: TC-I001 through TC-I008
**Deliverables**: Integration test results, BLE communication validation
**Critical Milestone**: TC-I004 (iOS negative temperature display) must pass

#### 6.1.3 Phase 3: Environmental Testing (Day 3-4)
**Duration**: 16 hours (including overnight stability)
**Scope**: TC-E001 through TC-E004, extended environmental validation
**Deliverables**: Environmental accuracy report, stress test results
**Critical Milestone**: TC-E001 (freezer range testing) must pass

#### 6.1.4 Phase 4: Extended Operation (Day 5)
**Duration**: 8 hours + 24-hour continuous monitoring
**Scope**: TC-L001 through TC-L003, TC-R001 through TC-R003  
**Deliverables**: Reliability report, power consumption analysis
**Critical Milestone**: TC-L001 (24-hour operation) must pass

### 6.2 Daily Test Execution Plan

#### 6.2.1 Day 1: Component Validation
```
09:00-10:00: Hardware setup and calibration
10:00-12:00: Arduino component testing (TC-A001 to TC-A003)
12:00-13:00: Lunch break
13:00-15:00: Data format validation (TC-A004, TC-A005 - CRITICAL)
15:00-16:00: Error handling testing (TC-A006)
16:00-17:00: Results documentation and Day 2 preparation
```

#### 6.2.2 Day 2: Integration Testing
```
09:00-10:00: iOS app setup and BLE connection validation
10:00-12:00: Basic integration testing (TC-I001 to TC-I003)
12:00-13:00: Lunch break  
13:00-15:00: Display accuracy testing (TC-I004 - CRITICAL, TC-I005)
15:00-16:00: Real-time synchronization (TC-I006)
16:00-17:00: Widget and Siri integration (TC-I007, TC-I008)
```

#### 6.2.3 Day 3-4: Environmental Testing
```
Day 3:
09:00-10:00: Environmental test setup
10:00-12:00: Freezer testing (TC-E001 - CRITICAL)
12:00-13:00: Lunch break
13:00-15:00: Heating range testing (TC-E002)
15:00-17:00: Humidity validation (TC-E003)
17:00-09:00: Overnight stability monitoring (TC-E004 setup)

Day 4:
09:00-10:00: Overnight results analysis
10:00-12:00: Combined stress testing (TC-E004 completion)
12:00-17:00: Extended environmental validation and documentation
```

#### 6.2.4 Day 5: Extended Operation
```
09:00-10:00: Extended operation test setup
10:00-12:00: iOS lifecycle testing (TC-L002)
12:00-13:00: Lunch break
13:00-15:00: Error recovery testing (TC-R001 to TC-R003)
15:00-17:00: Power consumption validation (TC-L003)
17:00+: 24-hour continuous monitoring start (TC-L001)
```

### 6.3 Milestone Gates

#### 6.3.1 Gate 1: Component Validation Complete
**Criteria**: TC-A005 (negative temperature format) passed
**Decision**: Proceed to integration testing or stop for Arduino firmware fixes

#### 6.3.2 Gate 2: Integration Validation Complete  
**Criteria**: TC-I004 (iOS negative display) passed
**Decision**: Proceed to environmental testing or stop for iOS app fixes

#### 6.3.3 Gate 3: Environmental Validation Complete
**Criteria**: TC-E001 (freezer testing) passed with accuracy requirements met
**Decision**: Proceed to extended testing or document limitations

#### 6.3.4 Gate 4: System Validation Complete
**Criteria**: TC-L001 (24-hour operation) completed successfully
**Decision**: System ready for production or additional testing required

---

## 7. Risk Assessment and Mitigation

### 7.1 Technical Risks

#### 7.1.1 High Risk Items
| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|--------|-------------------|
| iOS Int16 parsing fails for negative temps | Medium | Critical | Immediate code review, fallback UInt16 implementation |
| HS3003 sensor calibration drift | Low | High | Use calibrated reference instruments, document deviations |
| BLE connection instability on iPhone 15 Pro Max | Medium | High | Test with multiple iOS devices, optimize connection parameters |
| Freezer testing damages Arduino | Low | High | Use extended cables, gradual temperature changes |

#### 7.1.2 Medium Risk Items
| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|--------|---------------------|
| Environmental interference affects BLE | Medium | Medium | Controlled test environment, EMI shielding if needed |
| Battery life shorter than specified | High | Medium | Power optimization, realistic usage scenarios |
| Widget sync delays > 10 seconds | Medium | Medium | Background refresh optimization, fallback manual refresh |
| Reference instrument accuracy insufficient | Low | Medium | NIST traceable calibration, multiple reference sources |

### 7.2 Schedule Risks

#### 7.2.1 Time-Critical Dependencies
- **Freezer Access**: Required for critical negative temperature testing
- **Extended USB Cables**: Needed for freezer testing with Arduino powered
- **Calibrated Reference Instruments**: Must be available for accuracy validation
- **iPhone 15 Pro Max Availability**: Primary test device must be dedicated

#### 7.2.2 Schedule Mitigation
- **Backup Test Devices**: Secondary iPhone available if primary fails
- **Alternative Test Methods**: Simulator for extreme conditions if hardware unavailable
- **Parallel Test Execution**: Non-dependent tests run concurrently
- **Buffer Time**: 20% schedule margin for issue resolution

### 7.3 Quality Risks

#### 7.3.1 Measurement Accuracy Risks
- **Reference Instrument Error**: Mitigation - Multiple independent references
- **Environmental Gradient**: Mitigation - Sensors placed in immediate proximity
- **Thermal Lag**: Mitigation - Sufficient stabilization time between measurements
- **Human Error in Readings**: Mitigation - Automated logging where possible

#### 7.3.2 Test Coverage Risks
- **Edge Case Scenarios**: May not cover all possible failure modes
- **Long-term Degradation**: 5-day test may not reveal long-term issues  
- **User Interaction Scenarios**: Limited real-world usage patterns
- **iOS Version Compatibility**: Testing limited to single iOS version

---

## 8. Test Deliverables

### 8.1 Test Documentation

#### 8.1.1 Test Execution Reports
- **Daily Test Reports**: Results summary for each test day
- **Test Case Results**: Individual pass/fail status for each test case
- **Defect Reports**: Detailed documentation of any failures or issues
- **Performance Metrics**: Quantitative results for all KPIs

#### 8.1.2 Evidence Collection
- **Screenshots**: iOS app displays for all critical test scenarios
- **Serial Logs**: Complete Arduino serial output capture for all tests
- **Video Recordings**: Key test scenarios (especially negative temperature display)
- **Measurement Data**: Raw data from reference instruments

#### 8.1.3 Analysis Reports
- **Accuracy Analysis**: Statistical analysis of sensor accuracy vs. reference instruments
- **Performance Analysis**: BLE connection stability, latency measurements
- **Reliability Analysis**: System uptime, error recovery success rates
- **Power Consumption Report**: Battery life projection based on measured consumption

### 8.2 Test Completion Criteria

#### 8.2.1 Mandatory Completion Requirements
- ✅ All critical test cases passed (TC-A005, TC-I004, TC-E001, TC-L001)
- ✅ >95% pass rate for high-priority test cases
- ✅ >90% pass rate for medium-priority test cases  
- ✅ All defects documented with severity classification
- ✅ Performance metrics meet specified KPIs

#### 8.2.2 Test Report Contents
1. **Executive Summary**: Overall test results and system readiness
2. **Test Coverage Analysis**: Percentage of requirements tested
3. **Defect Summary**: Count and severity of issues found
4. **Performance Summary**: KPI results vs. specifications
5. **Risk Assessment**: Residual risks and recommended actions
6. **Recommendations**: System readiness for production deployment

### 8.3 Sign-off Requirements

#### 8.3.1 Technical Sign-offs Required
- **QA Lead**: Test execution completeness and quality
- **Hardware Engineer**: Arduino component validation results
- **iOS Developer**: App functionality and integration results
- **Systems Engineer**: End-to-end system validation

#### 8.3.2 Management Sign-offs Required
- **Project Manager**: Schedule and resource utilization
- **Product Manager**: Requirements coverage and acceptance
- **Technical Lead**: Overall system architecture validation

---

## 9. Appendices

### 9.1 Test Environment Setup Procedures

#### 9.1.1 Arduino Setup Checklist
```
□ Arduino IDE 2.0+ installed with required libraries
□ BLE_Sensor_Peripheral_BLE_Standards.ino firmware uploaded
□ Serial monitor configured at 115200 baud
□ Extended USB cable available for freezer testing
□ Power consumption measurement setup ready
□ Arduino mounted securely for stable operation
```

#### 9.1.2 iPhone 15 Pro Max Setup Checklist
```  
□ iOS 17.0+ installed and updated to latest version
□ BLE Central app installed with Int16 temperature parsing
□ Bluetooth permissions enabled for BLE Central app
□ Background App Refresh enabled for BLE Central app
□ BLE Central widget added to home screen
□ Siri enabled and configured for App Intents
□ Developer tools access configured (if needed)
```

#### 9.1.3 Test Equipment Checklist
```
□ Calibrated reference thermometer (±0.1°C accuracy)
□ Calibrated reference hygrometer (±1% RH accuracy)  
□ Digital multimeter for power measurements
□ nRF Connect app installed for BLE analysis
□ Freezer access confirmed for negative temperature testing
□ Heat source (hair dryer) available for temperature range testing
□ Humidity control materials (desiccant, humidifier) ready
□ Documentation tools (camera, screen recording) prepared
```

### 9.2 Troubleshooting Guide

#### 9.2.1 Arduino Issues
- **Sensor initialization fails**: Check library installation, power supply
- **BLE advertising not detected**: Verify nRF52840 firmware, reset Arduino
- **Serial output garbled**: Confirm 115200 baud rate, USB cable quality
- **Temperature readings unstable**: Allow thermal stabilization, check sensor placement

#### 9.2.2 iOS Issues  
- **App won't connect to Arduino**: Check Bluetooth permissions, restart app
- **Negative temperatures display as positive**: Verify Int16 parsing implementation
- **Widget not updating**: Check Background App Refresh settings, iOS version compatibility
- **Siri integration fails**: Verify App Intents configuration, iOS 16+ requirement

#### 9.2.3 BLE Communication Issues
- **Connection drops frequently**: Check signal strength, electromagnetic interference
- **Data transmission delays**: Monitor change thresholds, BLE congestion
- **Service discovery fails**: Verify Environmental Sensing Service advertisement
- **Characteristic read errors**: Check characteristic properties, permissions

### 9.3 Reference Standards

#### 9.3.1 Bluetooth SIG Specifications
- **Environmental Sensing Service**: UUID 181A specification
- **Temperature Characteristic**: UUID 2A6E, sint16 format requirement  
- **Humidity Characteristic**: UUID 2A6F, uint16 format requirement
- **Error Value Standards**: INT16_MIN (-32768) for temperature, UINT16_MAX (65535) for humidity

#### 9.3.2 Sensor Specifications
- **HS3003 Temperature**: ±0.25°C accuracy, -40°C to +120°C range
- **HS3003 Humidity**: ±2.8% RH accuracy, 0% to 100% RH range
- **Arduino Operating**: -40°C to +85°C ambient temperature range
- **iPhone 15 Pro Max Operating**: 0°C to 35°C ambient temperature range

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | July 19, 2025 | QA Team | Initial TPD creation for Arduino Nano 33 Sense Rev 2 + iPhone 15 Pro Max testing |

**Review and Approval**

| Role | Name | Date | Signature |
|------|------|------|-----------|
| QA Lead | - | - | - |
| Hardware Engineer | - | - | - |  
| iOS Developer | - | - | - |
| Project Manager | - | - | - |