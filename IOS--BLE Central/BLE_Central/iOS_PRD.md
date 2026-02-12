# Product Requirements Document (PRD)
## iOS BLE Central Environmental Monitoring App

---

### Document Information
- **Version**: 1.0
- **Date**: July 19, 2025
- **Author**: Development Team
- **Status**: Final

---

## 1. Product Overview

### 1.1 Product Name
BLE Central - Environmental Monitoring iOS App

### 1.2 Product Description
A native iOS application built with SwiftUI that serves as a Bluetooth Low Energy (BLE) central device for monitoring environmental conditions from multiple sensor types. The app connects to Arduino-based BLE peripherals and RuuviTag sensors, displaying real-time temperature and humidity data with integrated widget support and Siri integration.

**⚠️ External Sensor Requirement**: This app requires external BLE sensors to function. Complete sensor documentation and setup guides are available at: **https://github.com/bobh/Sensors**

### 1.3 Target Market
- IoT developers and hobbyists using Arduino sensors
- Environmental monitoring enthusiasts
- Smart home automation users
- Educational institutions teaching mobile BLE development
- Industrial monitoring applications requiring mobile dashboards
- Users with existing RuuviTag sensor deployments

---

## 2. Product Objectives

### 2.1 Primary Objectives
- Provide seamless BLE connectivity to environmental sensors
- Display real-time sensor data with intuitive user interface
- Support multiple sensor types (Arduino BLE, RuuviTag)
- Enable quick access via iOS widgets and Siri integration
- Maintain reliable data persistence and sharing across app extensions

### 2.2 Success Metrics
- BLE connection success rate: >95%
- App launch time: <2 seconds cold start
- Widget update latency: <5 seconds from sensor update
- User retention: >80% after first week
- App Store rating: >4.5 stars
- Crash-free sessions: >99.5%
- Battery impact: <5% per hour of continuous use

---

## 3. Functional Requirements

### 3.1 Core Features

#### 3.1.1 BLE Central Management
- **FR-001**: Scan for and connect to BLE peripheral devices automatically
- **FR-002**: Maintain stable connection to selected sensor device
- **FR-003**: Handle BLE state changes (powered off, unauthorized, etc.)
- **FR-004**: Display connection status in real-time
- **FR-005**: Implement automatic reconnection after connection loss

#### 3.1.2 Sensor Data Acquisition
- **FR-006**: Read temperature data from Environmental Sensing Service (181A)
- **FR-007**: Read humidity data from Environmental Sensing Service (181A)
- **FR-008**: Parse temperature characteristic (2A6E) in sint16 format (supports negative temperatures)
- **FR-009**: Parse humidity characteristic (2A6F) in uint16 format
- **FR-010**: Support RuuviTag manufacturer advertisement data parsing
- **FR-011**: Handle sensor error values (-32768 temp, 65535 humidity)

#### 3.1.3 Data Display and Visualization
- **FR-012**: Display current temperature in Celsius with 0.1°C precision
- **FR-013**: Display current humidity in percentage with 0.1% precision
- **FR-014**: Show appropriate icons (thermometer, water drop) for each metric
- **FR-015**: Provide visual connection status indicator
- **FR-016**: Display sensor source type (Standard BLE vs RuuviTag)

#### 3.1.4 Settings and Configuration
- **FR-017**: Allow user to switch between Standard BLE and RuuviTag modes
- **FR-018**: Persist user preferences across app launches
- **FR-019**: Provide settings accessible via toolbar button
- **FR-020**: Implement segmented picker for sensor source selection

### 3.2 iOS Integration Features

#### 3.2.1 Widget Support
- **FR-021**: Provide iOS Home Screen widget displaying current readings
- **FR-022**: Update widget automatically when new sensor data arrives
- **FR-023**: Handle widget data refresh via App Group shared storage
- **FR-024**: Display placeholder values when no data available
- **FR-025**: Configure widget with descriptive name "Environmental Readings"

#### 3.2.2 App Intents and Siri Integration
- **FR-026**: Implement GetTemperatureIntent for Siri voice queries
- **FR-027**: Implement GetHumidityIntent for Siri voice queries
- **FR-028**: Return current sensor values via App Intents framework
- **FR-029**: Handle no-data scenarios gracefully in voice responses

### 3.3 Data Management
- **FR-030**: Store sensor data in shared UserDefaults with App Group
- **FR-031**: Use App Group ID: "group.com.yourcompany.BLECentral"
- **FR-032**: Persist temperature and humidity values across app sessions
- **FR-033**: Maintain sensor source preference in persistent storage
- **FR-034**: Synchronize data between main app, widget, and App Intents

---

## 4. Technical Requirements

### 4.1 Platform Requirements
- **Minimum iOS Version**: iOS 14.0
- **Target iOS Version**: iOS 17.0+
- **Architecture**: Universal (iPhone/iPad)
- **Development Framework**: SwiftUI
- **Programming Language**: Swift 5.9+

### 4.2 Hardware Requirements
- **BLE Support**: Bluetooth 4.0+ (BLE)
- **Device Types**: iPhone 6s and later, iPad (5th generation) and later
- **Memory**: Minimum 1GB RAM recommended
- **Storage**: <50MB app size

### 4.3 Development Requirements
- **IDE**: Xcode 15.0+
- **Deployment Target**: iOS 14.0
- **Code Signing**: Apple Developer Account required
- **Testing**: iOS Simulator and physical devices

### 4.4 Performance Requirements
- **App Launch**: <2 seconds cold start on iPhone 12 or later
- **BLE Scan Duration**: <10 seconds to discover sensors
- **Connection Time**: <5 seconds to establish BLE connection
- **UI Responsiveness**: 60fps scrolling and animations
- **Memory Usage**: <100MB typical, <200MB peak
- **Battery Impact**: Minimal background processing when not active
- **Widget Update**: <5 seconds latency from sensor data change

---

## 5. BLE Communication Protocol

### 5.1 Standard BLE Sensor Communication
```
Service: Environmental Sensing Service (181A)
├── Temperature Characteristic (2A6E)
│   ├── Properties: Read, Notify
│   ├── Data Format: sint16 (value × 100)
│   ├── Range: -327.68°C to +327.67°C (supports negative temperatures)
│   └── Parsing: Int16(littleEndian) / 100.0
└── Humidity Characteristic (2A6F)
    ├── Properties: Read, Notify
    ├── Data Format: uint16 (value × 100)
    ├── Range: 0% to 655.35% RH
    └── Parsing: UInt16(littleEndian) / 100.0
```

### 5.2 RuuviTag Advertisement Protocol
```
Advertisement Data:
├── Manufacturer Data Key: CBAdvertisementDataManufacturerDataKey
├── Company ID: [0x99, 0x04] (Ruuvi)
├── Data Format: RAWv1 (byte[2] = 0x03)
├── Temperature: bytes 3-4 (Int16, signed, value × 100)
└── Humidity: bytes 5-6 (UInt16, unsigned, value × 100)
```

### 5.3 Error Handling
- **Connection Failures**: Display status and retry automatically
- **Invalid Data**: Show "--" for unavailable readings
- **Sensor Errors**: Handle -32768 (temp) and 65535 (humidity) as error values
- **BLE State Changes**: Update UI and inform user of BLE availability

---

## 6. User Stories

### 6.1 Primary User Stories
- **US-001**: As a user, I want to see current temperature and humidity from my Arduino sensor so I can monitor environmental conditions
- **US-002**: As a user, I want the app to automatically connect to my sensor so I don't have to manually pair each time
- **US-003**: As a user, I want to switch between different sensor types so I can use both Arduino and RuuviTag sensors
- **US-004**: As a user, I want to see sensor data on my Home Screen widget so I can check readings without opening the app

### 6.2 Advanced User Stories
- **US-005**: As a user, I want to ask Siri for temperature readings so I can get data hands-free
- **US-006**: As a user, I want the app to remember my sensor choice so I don't have to reconfigure each time
- **US-007**: As a user, I want clear visual indicators of connection status so I know if my sensor is working
- **US-008**: As a user, I want the app to handle negative temperatures correctly (-327.68°C to +327.67°C range) so I can monitor freezing and extreme cold conditions

### 6.3 Developer Stories
- **US-009**: As a developer, I want to integrate my Arduino Environmental Sensing Service so my sensor works with this app
- **US-010**: As a developer, I want to understand BLE data formats so I can create compatible sensors
- **US-011**: As a developer, I want to extend the app for additional sensor types so I can support more hardware

---

## 7. User Interface Requirements

### 7.1 Main Interface Design
- **UIR-001**: Navigation-based SwiftUI interface with title "Sensor Data"
- **UIR-002**: Prominent display of temperature and humidity with large, bold text
- **UIR-003**: System SF Symbol icons (thermometer, drop) for visual clarity
- **UIR-004**: Connection status text at top of interface
- **UIR-005**: Settings gear icon in navigation bar for easy access

### 7.2 Settings Interface
- **UIR-006**: Form-based settings view with navigation title "Settings"
- **UIR-007**: Segmented control for sensor source selection
- **UIR-008**: Clear labeling: "Standard BLE" and "RuuviTag" options
- **UIR-009**: Modal presentation from main interface

### 7.3 Accessibility Requirements
- **UIR-010**: VoiceOver support for all interactive elements
- **UIR-011**: Appropriate accessibility labels for sensor readings
- **UIR-012**: Settings button labeled "Settings" for screen readers
- **UIR-013**: Dynamic Type support for text scaling

### 7.4 Widget Interface
- **UIR-014**: Compact vertical layout showing both temperature and humidity
- **UIR-015**: Format: "Temperature: XX.X°C" and "Humidity: XX.X%"
- **UIR-016**: Fallback to "--" when no data available

---

## 8. Non-Functional Requirements

### 8.1 Reliability
- **NFR-001**: App shall maintain 99.5% crash-free session rate
- **NFR-002**: BLE connection shall recover automatically within 30 seconds
- **NFR-003**: Data persistence shall survive app termination and device restart
- **NFR-004**: Widget shall update reliably when app receives new sensor data

### 8.2 Performance
- **NFR-005**: UI shall remain responsive during BLE operations
- **NFR-006**: Memory usage shall not exceed 200MB during normal operation
- **NFR-007**: Battery drain shall be <5% per hour during active monitoring
- **NFR-008**: App launch shall complete within 2 seconds on supported devices

### 8.3 Usability
- **NFR-009**: Interface shall be intuitive for first-time users without instructions
- **NFR-010**: Sensor switching shall take effect immediately upon selection
- **NFR-011**: Error states shall provide clear user feedback
- **NFR-012**: App shall follow iOS Human Interface Guidelines

### 8.4 Compatibility
- **NFR-013**: App shall work with iOS 14.0 through latest iOS version
- **NFR-014**: App shall support iPhone and iPad form factors
- **NFR-015**: App shall work with both Arduino BLE peripherals (with sint16 temperature support) and RuuviTag sensors
- **NFR-016**: Widget shall function on iOS 14+ Home Screen and Today View

---

## 9. Security and Privacy Requirements

### 9.1 Bluetooth Privacy
- **SPR-001**: App shall request Bluetooth permissions appropriately
- **SPR-002**: Bluetooth usage description shall clearly explain sensor connectivity purpose
- **SPR-003**: App shall not store or transmit BLE device identifiers
- **SPR-004**: Sensor data shall remain local to device and shared App Group only

### 9.2 Data Privacy
- **SPR-005**: No sensor data shall be transmitted to external servers
- **SPR-006**: App Group data shall be encrypted at rest by iOS
- **SPR-007**: Widget data access shall be limited to same App Group
- **SPR-008**: Siri integration shall not store voice query history

---

## 10. Constraints and Assumptions

### 10.1 Technical Constraints
- **TC-001**: Limited to single concurrent BLE connection
- **TC-002**: BLE range typically limited to 10 meters
- **TC-003**: Widget updates dependent on iOS background app refresh policies
- **TC-004**: App Intents require iOS 16+ for full Siri integration

### 10.2 Business Constraints
- **BC-001**: Must comply with App Store Review Guidelines
- **BC-002**: Cannot include third-party analytics or advertising frameworks
- **BC-003**: Must use standard iOS frameworks only
- **BC-004**: App Group ID must match across all targets

### 10.3 Assumptions
- **AS-001**: Users have compatible BLE sensors (Arduino or RuuviTag)
- **AS-002**: iOS device has Bluetooth 4.0+ capability
- **AS-003**: Arduino sensors implement standard Environmental Sensing Service
- **AS-004**: RuuviTag sensors broadcast RAWv1 format advertisement data
- **AS-005**: Users understand basic BLE pairing concepts

---

## 11. Risk Assessment

### 11.1 Technical Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| iOS BLE API changes | Medium | High | Use stable Core Bluetooth APIs, test on iOS betas |
| Widget refresh limitations | High | Medium | Document limitations, provide manual refresh guidance |
| BLE connection reliability | Medium | High | Implement robust retry logic and user feedback |
| Memory leaks in BLE operations | Low | High | Comprehensive testing with Instruments |

### 11.2 User Experience Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Confusing sensor selection | Medium | Medium | Clear UI labels and help text |
| Poor connection status feedback | Low | High | Prominent status display and error messages |
| Widget not updating | Medium | High | Clear documentation and troubleshooting guide |
| Accessibility compliance | Low | Medium | VoiceOver testing and dynamic type support |

---

## 12. Testing Strategy

### 12.1 Functional Testing
- BLE connection and disconnection scenarios
- Sensor data parsing accuracy
- UI state management across connection states
- Settings persistence and App Group data sharing
- Widget update reliability
- App Intents response accuracy

### 12.2 Integration Testing
- Arduino BLE peripheral communication
- RuuviTag advertisement data parsing
- iOS widget data synchronization
- Siri integration and voice responses
- Background app refresh behavior

### 12.3 Performance Testing
- Memory leak detection with Instruments
- Battery usage measurement
- UI responsiveness under BLE operations
- App launch time optimization
- Widget update latency measurement

### 12.4 Compatibility Testing
- iOS version compatibility (14.0 through latest)
- iPhone and iPad form factor support
- Multiple Arduino sensor types
- Various RuuviTag firmware versions

---

## 13. Deployment Requirements

### 13.1 App Store Submission
- Apple Developer Program membership
- App Store Connect configuration
- TestFlight beta testing phase
- App Store Review Guidelines compliance
- Privacy policy and App Store metadata

### 13.2 Development Team Setup
- Shared Apple Developer Account access
- Consistent App Group configuration
- Code signing certificate management
- Version control and branching strategy

### 13.3 Distribution Strategy
- Initial release via TestFlight for beta users
- App Store release with Arduino sensor compatibility
- Documentation and user guides
- Developer integration examples

---

## 14. Future Enhancements

### 14.1 Planned Features
- **FE-001**: Multiple simultaneous sensor connections
- **FE-002**: Historical data logging and trend visualization
- **FE-003**: Custom alert thresholds for temperature/humidity
- **FE-004**: Export data functionality (CSV, JSON)
- **FE-005**: Additional sensor types (pressure, light, CO2)

### 14.2 Advanced Features
- **FE-006**: Cloud data synchronization and backup
- **FE-007**: Apple Watch companion app
- **FE-008**: HomeKit integration for automation
- **FE-009**: Machine learning for predictive analytics
- **FE-010**: Multi-device sensor management

---

## 15. Appendices

### 15.1 Acronyms and Definitions
- **BLE**: Bluetooth Low Energy
- **PRD**: Product Requirements Document
- **UUID**: Universally Unique Identifier
- **CBCentralManager**: Core Bluetooth central manager class
- **CBPeripheral**: Core Bluetooth peripheral device class
- **App Group**: iOS shared container for data between app and extensions
- **App Intents**: iOS framework for Siri and Shortcuts integration

### 15.2 References
- Apple Core Bluetooth Framework Documentation
- iOS Human Interface Guidelines
- SwiftUI Framework Documentation
- WidgetKit Documentation
- App Intents Framework Documentation
- Bluetooth SIG Environmental Sensing Service Specification
- RuuviTag RAWv1 Data Format Specification

### 15.3 Related Documents
- Arduino BLE Sensor Peripheral PRD
- iOS App Store Review Guidelines
- Apple Developer Program Documentation

---

**Document Approval**

| Role | Name | Date | Signature |
|------|------|------|-----------|
| iOS Product Manager | - | - | - |
| iOS Technical Lead | - | - | - |
| UX/UI Designer | - | - | - |
| QA Lead | - | - | - |