# Product Requirements Document (PRD)
## Arduino BLE Environmental Sensor Peripheral

---

### Document Information
- **Version**: 1.0
- **Date**: July 18, 2025
- **Author**: Development Team
- **Status**: Final

---

## 1. Product Overview

### 1.1 Product Name
Arduino BLE Environmental Sensor Peripheral

### 1.2 Product Description
A Bluetooth Low Energy (BLE) peripheral application for Arduino Nano 33 BLE Sense Rev2 that continuously monitors environmental conditions (temperature and humidity) and transmits data to iOS mobile applications. The device features intelligent power management and change-based transmission to maximize battery life while maintaining real-time data accuracy.

### 1.3 Target Market
- IoT developers and hobbyists
- Environmental monitoring applications
- Educational institutions teaching IoT/BLE concepts
- Prototyping and proof-of-concept projects
- Smart home and building automation systems

---

## 2. Product Objectives

### 2.1 Primary Objectives
- Provide reliable environmental sensor data via BLE
- Maximize battery life through intelligent power management
- Ensure seamless integration with iOS BLE Central applications (✅ Compatible as of July 2025)
- Maintain data accuracy through sensor averaging algorithms

### 2.2 Success Metrics
- Battery life: >24 hours continuous operation
- Data transmission accuracy: ±0.25°C temperature, ±2.8% RH humidity (HS3003 sensor limits)
- Data transmission precision: 0.01°C temperature, 0.01% humidity (BLE format resolution)
- BLE connection reliability: >95% uptime
- Response time: <2 seconds for initial connection
- Memory efficiency: <50% program storage, <30% dynamic memory

---

## 3. Functional Requirements

### 3.1 Core Features

#### 3.1.1 Environmental Sensing
- **FR-001**: Read temperature from HS3003 sensor using Arduino_HS3003 library with 0.01°C resolution (±0.25°C accuracy)
- **FR-002**: Read humidity from HS3003 sensor using Arduino_HS3003 library with 0.01% resolution (±2.8% RH accuracy)
- **FR-003**: Sample sensors at 500ms intervals
- **FR-004**: Maintain 5-reading running average for each sensor
- **FR-005**: Detect and handle sensor failures gracefully

#### 3.1.2 BLE Communication
- **FR-006**: Implement Environmental Sensing Service (UUID: 181A)
- **FR-007**: Provide Temperature Characteristic (UUID: 2A6E) with read/notify
- **FR-008**: Provide Humidity Characteristic (UUID: 2A6F) with read/notify
- **FR-009**: Advertise as "Arduino Sensor" with 1-second intervals
- **FR-010**: Support automatic reconnection after disconnect

#### 3.1.3 Data Transmission
- **FR-011**: Transmit data only when changes exceed thresholds
- **FR-012**: Temperature threshold: ±0.5°C change
- **FR-013**: Humidity threshold: ±2% change
- **FR-014**: Send temperature in sint16 format (value × 100), humidity in uint16 format (value × 100)
- **FR-015**: Transmit error values: -32768 (temperature), 65535 (humidity) on sensor failure

### 3.2 Power Management
- **FR-016**: Use minimal delays between operations
- **FR-017**: Disable unused peripherals (LEDs, etc.)
- **FR-018**: Optimize BLE advertising intervals
- **FR-019**: Implement change-based transmission to reduce power

### 3.3 User Interface
- **FR-020**: Provide serial debug output at 115200 baud
- **FR-021**: Display connection status messages
- **FR-022**: Show sensor readings and transmission events
- **FR-023**: Report sensor initialization and error states

---

## 4. Technical Requirements

### 4.1 Hardware Requirements
- **Platform**: Arduino Nano 33 BLE Sense Rev2
- **Microcontroller**: Nordic nRF52840 (ARM Cortex-M4)
- **Sensor**: HS3003 (temperature/humidity)
- **BLE Support**: nRF52840 SoC with ArduinoBLE library
- **Connectivity**: Bluetooth 5.0 Low Energy
- **Power**: USB or external 3.3V-5V supply

### 4.2 Software Requirements
- **IDE**: Arduino IDE 2.0 or later
- **Board Package**: Arduino Mbed OS Nano Boards
- **Libraries**: ArduinoBLE (official Arduino BLE library for nRF52840), Arduino_HS3003 (HS3003/HS300x sensor library)
- **Architecture**: mbed_nano

### 4.3 Performance Requirements
- **Sampling Rate**: 500ms (2 Hz)
- **Averaging Window**: 5 samples (2.5 seconds)
- **BLE Latency**: <100ms for characteristic updates
- **Memory Usage**: <50% program storage, <30% RAM
- **Operating Temperature**: -10°C to +70°C
- **Operating Humidity**: 0-95% RH (non-condensing)
- **Sensor Accuracy**: ±0.25°C (temperature), ±2.8% RH (humidity)
- **Sensor Resolution**: 0.01°C (temperature), 0.01% RH (humidity)

---

## 5. Communication Protocol

### 5.1 BLE Service Structure
```
Environmental Sensing Service (181A)
├── Temperature Characteristic (2A6E)
│   ├── Properties: Read, Notify
│   ├── Format: sint16 (Celsius × 100)
│   └── Example: 2350 = 23.50°C, -500 = -5.00°C
└── Humidity Characteristic (2A6F)
    ├── Properties: Read, Notify
    ├── Format: uint16 (Percent × 100)
    └── Example: 4520 = 45.20%
```

### 5.2 Data Format
- **Temperature**: 16-bit signed integer (°C × 100) - Bluetooth SIG standard sint16
- **Humidity**: 16-bit unsigned integer (% × 100) - Bluetooth SIG standard uint16
- **Error Values**: 
  - Temperature: -32768 (INT16_MIN) for sensor failure
  - Humidity: 65535 (UINT16_MAX) for sensor failure
- **Byte Order**: Little-endian
- **Temperature Range**: -327.68°C to +327.67°C (supports negative temperatures)

---

## 6. User Stories

### 6.1 Developer Stories
- **US-001**: As a developer, I want to integrate environmental sensors into my IoT project so that I can monitor conditions remotely
- **US-002**: As a developer, I want reliable BLE communication so that my mobile app receives consistent data
- **US-003**: As a developer, I want power-efficient operation so that my battery-powered device lasts longer

### 6.2 End User Stories
- **US-004**: As an end user, I want to see real-time temperature and humidity data on my iOS app
- **US-005**: As an end user, I want the device to automatically reconnect after losing connection
- **US-006**: As an end user, I want to know when sensor readings are invalid or unreliable

---

## 7. Non-Functional Requirements

### 7.1 Reliability
- **NFR-001**: System shall operate continuously for 24+ hours
- **NFR-002**: BLE connection shall maintain 95% uptime
- **NFR-003**: Sensor readings shall be accurate within specified tolerances
- **NFR-004**: System shall recover from sensor failures automatically

### 7.2 Performance
- **NFR-005**: Initial BLE connection shall complete within 2 seconds
- **NFR-006**: Sensor readings shall update every 500ms
- **NFR-007**: BLE notifications shall be sent within 100ms of threshold breach
- **NFR-008**: Memory usage shall not exceed 50% of available resources

### 7.3 Maintainability
- **NFR-009**: Code shall be well-documented with clear comments
- **NFR-010**: Serial debug output shall provide meaningful status information
- **NFR-011**: Configuration parameters shall be easily adjustable
- **NFR-012**: Code shall follow Arduino coding standards

---

## 8. Constraints and Assumptions

### 8.1 Technical Constraints
- **TC-001**: Limited to Arduino Nano 33 BLE Sense Rev2 hardware with nRF52840 SoC
- **TC-002**: Dependent on ArduinoBLE library compatibility (official Arduino library for nRF52840)
- **TC-003**: BLE range limited to ~10 meters (typical indoor)
- **TC-004**: Single concurrent BLE connection supported

### 8.2 Business Constraints
- **BC-001**: Must use standard Bluetooth SIG UUIDs for compatibility
- **BC-002**: Must comply with BLE advertising regulations
- **BC-003**: No external dependencies beyond Arduino ecosystem

### 8.3 Assumptions
- **AS-001**: iOS central app implements proper BLE client behavior
- **AS-002**: Arduino IDE and libraries remain backward compatible
- **AS-003**: HS3003 sensor maintains calibration over device lifetime (Arduino_HS3003 library provides accurate readings)
- **AS-004**: Operating environment within sensor specifications

---

## 9. Risk Assessment

### 9.1 Technical Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| BLE connection instability | Medium | High | Implement robust reconnection logic |
| Sensor calibration drift | Low | Medium | Regular calibration checks |
| Memory constraints | Low | High | Optimize code and monitor usage |
| Power consumption higher than expected | Medium | Medium | Implement additional power optimizations |

### 9.2 Business Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Arduino library compatibility issues | Medium | High | Test with multiple library versions |
| Hardware availability | Low | Medium | Document alternative compatible boards |
| iOS compatibility changes | Low | High | ✅ RESOLVED: iOS app updated July 2025 for sint16 compatibility |

---

## 10. Testing Strategy

### 10.1 Unit Testing
- Sensor reading accuracy validation
- BLE characteristic value formatting
- Average calculation algorithms
- Error handling paths

### 10.2 Integration Testing
- BLE service and characteristic registration
- iOS app communication protocol
- Sensor initialization and failure scenarios
- Power management effectiveness

### 10.3 Performance Testing
- Memory usage monitoring
- BLE connection stability over time
- Battery life measurement
- Environmental stress testing

---

## 11. Deployment

### 11.1 Prerequisites
- Arduino IDE 2.0+ installed
- Arduino Mbed OS Nano Boards package
- Required libraries installed (ArduinoBLE, Arduino_HS3003)
- Arduino Nano 33 BLE Sense Rev2 hardware

### 11.2 Installation Steps
1. Install required libraries via Arduino Library Manager
2. Connect Arduino Nano 33 BLE Sense Rev2 to computer
3. Select correct board and port in Arduino IDE
4. Upload BLE_Sensor_Peripheral.ino sketch
5. Monitor serial output for initialization confirmation

### 11.3 Verification
- Verify BLE advertising in iOS Settings > Bluetooth
- Confirm sensor readings in serial monitor
- Test connection with iOS BLE Central app
- Validate data transmission and reconnection

---

## 12. Future Enhancements

### 12.1 Planned Features
- **FE-001**: Over-the-air (OTA) firmware updates
- **FE-002**: Configurable sensor sampling rates
- **FE-003**: Data logging to onboard storage
- **FE-004**: Multiple sensor support (pressure, light, etc.)
- **FE-005**: Encrypted BLE communications

### 12.2 Potential Improvements
- **FE-006**: Web-based configuration interface
- **FE-007**: Cloud data synchronization
- **FE-008**: Machine learning for predictive analytics
- **FE-009**: Multi-device mesh networking
- **FE-010**: Solar power integration

---

## 13. Appendices

### 13.1 Acronyms and Definitions
- **BLE**: Bluetooth Low Energy
- **PRD**: Product Requirements Document
- **UUID**: Universally Unique Identifier
- **HS3003**: Renesas humidity and temperature sensor
- **mbed**: ARM mbed OS embedded operating system
- **IoT**: Internet of Things

### 13.2 References
- Bluetooth SIG Environmental Sensing Service Specification
- Arduino Nano 33 BLE Sense Rev2 Technical Documentation
- ArduinoBLE Library Documentation (official Arduino BLE library for nRF52840)
- Arduino_HS3003 Library Documentation (HS3003/HS300x sensor support)
- iOS Core Bluetooth Framework Documentation

---

**Document Approval**

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Manager | - | - | - |
| Technical Lead | - | - | - |
| QA Lead | - | - | - |