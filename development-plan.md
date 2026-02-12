# Cricket (Demetor) Hyperlocal Environmental Monitoring System - Development Plan

## Strategic Vision: Ambient Intelligence Integration

**Cricket** is an ambient intelligence data provider that integrates external Bluetooth environmental sensors with Apple's AI reasoning framework. Rather than being a traditional "app" that users explicitly invoke, Cricket positions itself as a **capability provider** for Apple Intelligence.

### Core Technology Stack
- **App Intents** ✅ (Implemented) - Structured intent definitions for Siri and Shortcuts
- **App Entities** ✅ (Implemented) - Semantic data types (TemperatureReading, HumidityReading)
- **Shortcuts Integration** ✅ (Implemented) - "Hey Siri, run Room Temp" works perfectly
- **Intent Donation** ✅ (Active) - Building Apple Intelligence pattern recognition history
- **Entity-Based Invocation** ⏳ (Awaiting WWDC 26) - Apple's next-gen ambient AI routing

### The Ambient Intelligence Approach
Cricket follows Apple's technology roadmap where AI systems discover and invoke capabilities by **semantic need**, not app name:
- User asks: *"Is it humid enough for my sourdough to rise?"*
- Apple Intelligence recognizes: Need for **HumidityReading** + baking context
- System automatically queries: Cricket's **HumidityReading AppEntity**
- User receives: Contextual answer without knowing which app provided data

This transforms Cricket from a traditional app into an **invisible ambient intelligence sensor layer**.

## Overview
Cricket is a comprehensive hyperlocal environmental monitoring system that provides accurate temperature and humidity readings through external BLE sensors (Arduino DIY + RuuviTag commercial), iOS/macOS applications, widgets, and Siri integration. The system addresses smartphone sensor limitations by using dedicated external sensors with 0.1° precision.

### 📚 **Essential Documentation**
**Sensor Setup & Documentation**: https://github.com/bobh/Sensors
- Complete Arduino building instructions
- RuuviTag setup and configuration  
- Troubleshooting guides
- Community contributions and advanced modifications

## Current State Assessment (Updated Feb 12, 2026)
- **Arduino**: BLE peripheral code exists with dual implementation (Claude/Grok versions) using Arduino Nano 33 BLE Sense Rev2 with nRF52840 SoC and Arduino_HS3003 sensor library
- **iOS**: ✅ Full SwiftUI app with BLE connectivity, RuuviTag support, App Intents, AppEntity types, intent donation
- **macOS**: ✅ Complete SwiftUI app with BLE connectivity, RuuviTag support, App Intents, AppEntity types, intent donation
- **Architecture**: ✅ arm64 (Apple Silicon) only - no universal binaries
- **Build Status**: ✅ Both iOS and macOS build with ZERO warnings
- **Shortcuts**: ✅ "Hey Siri, run Room Temp" fully functional with cricket chirp audio signature
- **App Entities**: ✅ TemperatureReading, HumidityReading, SensorStatus entities implemented
- **Intent Donation**: ✅ Active since Nov 4, 2025 - building Apple Intelligence pattern history
- **Status**: Functional production-quality prototype awaiting iOS 26.4 and WWDC 26 entity-based invocation

## 1. Project Setup and Infrastructure

### 1.1 Repository and Development Environment
- [ ] Set up proper Git repository with .gitignore for iOS/macOS development
  - Include Xcode project files, build artifacts, and sensitive data exclusions
- [ ] Create development environment documentation
  - Required Xcode version, Arduino IDE setup, library dependencies
- [ ] Set up branch strategy (main, develop, feature branches)
- [ ] Configure code signing and provisioning profiles for iOS/macOS development

### 1.2 Project Structure Optimization
- [ ] Reorganize project structure for scalability
  - Separate shared components between iOS and macOS
  - Create proper folder hierarchy for assets, documentation, and source code
- [ ] Set up App Groups configuration for data sharing between app, widget, and intents
  - Update bundle identifiers to production-ready naming convention
- [ ] Configure build settings for Release and Debug configurations

### 1.3 Arduino Environment Setup
- [ ] Standardize on single Arduino implementation for Nano 33 BLE Sense Rev2 (choose between Claude/Grok versions)
- [ ] Create Arduino library dependencies documentation (ArduinoBLE, Arduino_HS3003)
- [ ] Set up nRF52840-specific hardware testing procedures and calibration protocols
- [ ] Document HS3003/HS300x sensor accuracy specifications and operating ranges

## 2. Backend Foundation (Arduino Firmware)

### 2.1 Arduino Code Consolidation and Optimization
- [ ] Merge and optimize dual Arduino implementations into single production version for Nano 33 BLE Sense Rev2
  - Retain best features from both Claude and Grok versions
  - Utilize nRF52840 SoC capabilities and ArduinoBLE library
  - Ensure Bluetooth SIG compliance for temperature (sint16) and humidity (uint16)
  - Integrate Arduino_HS3003 library for HS3003/HS300x sensor support
- [ ] Implement comprehensive error handling and recovery mechanisms
  - Sensor initialization failure recovery
  - BLE connection loss handling
  - Invalid reading detection and reporting
- [ ] Optimize power consumption for battery operation
  - Implement deep sleep modes when not connected
  - Reduce advertising frequency when appropriate
  - Monitor and report battery status via additional BLE characteristic

### 2.2 Enhanced Sensor Features
- [ ] Implement advanced sensor calibration functionality
  - Factory calibration offset storage in EEPROM
  - User calibration interface through BLE commands
- [ ] Add sensor diagnostic capabilities
  - Self-test routines for HS3003 sensor validation
  - Connection quality reporting (RSSI, packet loss)
- [ ] Implement configurable sampling parameters
  - Adjustable sampling intervals via BLE commands
  - Configurable averaging window size
  - Dynamic threshold adjustment for change detection

### 2.3 BLE Protocol Enhancement
- [ ] Implement Device Information Service (180A) for proper device identification
  - Manufacturer name, model number, firmware version characteristics
- [ ] Add Battery Service (180F) for power level reporting
- [ ] Implement custom service for configuration and diagnostics
  - Calibration parameters, sampling settings, device status
- [ ] Add Over-The-Air (OTA) firmware update capability
  - Secure bootloader implementation
  - Version management and rollback capability

## 3. Feature-specific Backend (Arduino Advanced Features)

### 3.1 Multi-sensor Support Framework
- [ ] Design extensible architecture for additional sensor types
  - Modular sensor driver interface
  - Dynamic service advertisement based on available sensors
- [ ] Implement sensor fusion algorithms
  - Combined temperature/humidity validation
  - Outlier detection and filtering
- [ ] Add environmental condition alerts
  - Configurable threshold-based notifications
  - Historical data trend analysis

### 3.2 Data Logging and Analytics
- [ ] Implement local data storage on Arduino
  - Circular buffer for historical readings
  - Statistical analysis (min, max, average over time periods)
- [ ] Add data export capabilities
  - Bulk data transfer via BLE
  - CSV format support for analysis
- [ ] Implement sensor health monitoring
  - Drift detection over time
  - Maintenance scheduling alerts

## 4. Frontend Foundation (iOS/macOS Core)

### 4.1 iOS App Architecture Refinement
- [ ] Implement proper MVVM architecture
  - Separate business logic from UI components
  - Create dedicated service layer for BLE communication
- [ ] Enhance BLE connection management
  - Automatic device discovery with filtering
  - Connection retry logic with exponential backoff
  - Multiple device support and switching
- [ ] Implement comprehensive data validation
  - Error value detection and handling (-32768 for temp, 65535 for humidity)
  - Data range validation and outlier detection
- [ ] Add robust state management
  - Persist connection preferences and device history
  - Handle app lifecycle events (background/foreground transitions)

### 4.2 macOS App Foundation
- [ ] Create new macOS project with SwiftUI
  - Shared codebase with iOS where possible
  - macOS-specific UI patterns (toolbar, menus, window management)
- [ ] Implement Core Bluetooth for macOS
  - macOS-specific BLE permission handling
  - Background operation capabilities
- [ ] Design macOS-specific features
  - Menu bar integration
  - System notification support
  - Multi-window support for multiple sensors

### 4.3 Shared Framework Development
- [ ] Create shared Swift Package for common functionality
  - BLE communication protocols
  - Data models and parsing logic
  - Sensor-specific implementations (Arduino, RuuviTag)
- [ ] Implement unified data storage layer
  - Core Data or SwiftData for historical data
  - Sync capabilities between iOS and macOS
- [ ] Create shared UI components
  - Sensor reading displays
  - Connection status indicators
  - Settings interfaces

## 5. Feature-specific Frontend (User-Facing Features)

### 5.1 Enhanced User Interface
- [ ] Redesign main interface for better usability
  - Large, easily readable temperature and humidity displays
  - Visual indicators for connection status and data freshness
  - Trend graphs and historical data visualization
- [ ] Implement advanced settings panel
  - Sensor selection and pairing interface
  - Calibration and threshold configuration
  - Notification preferences
- [ ] Add sensor management features
  - Device discovery and pairing wizard
  - Multiple sensor support with naming and organization
  - Sensor health monitoring and diagnostics

### 5.2 Widget System Enhancement
- [ ] Expand widget functionality
  - Multiple widget sizes (small, medium, large)
  - Configurable display options (units, precision, layout)
  - Deep linking to main app from widgets
- [ ] Implement widget configuration
  - Sensor selection for multi-device setups
  - Custom display preferences
  - Update frequency settings
- [ ] Add Live Activities (iOS 16+)
  - Real-time environmental monitoring
  - Critical threshold notifications

### 5.3 Siri and Shortcuts Integration
- [ ] Enhance App Intents implementation
  - More natural language processing
  - Contextual responses with units and timestamps
  - Multi-sensor query support
- [ ] Create comprehensive Shortcuts actions
  - Environmental condition triggers
  - Automation based on readings (HVAC control, notifications)
  - Location-based sensor selection
- [ ] Implement Siri suggestions
  - Proactive suggestions based on usage patterns
  - Time-based and location-based recommendations

### 5.4 Accessibility and Localization
- [ ] Implement full VoiceOver support
  - Descriptive labels for all UI elements
  - Custom rotor controls for quick navigation
  - Accessibility hints for complex interactions
- [ ] Add Dynamic Type support
  - Scalable fonts throughout the interface
  - Layout adaptation for large text sizes
- [ ] Implement comprehensive localization
  - Multi-language support for UI text
  - Localized number and unit formatting
  - Cultural preferences for temperature units (°C/°F)

## 6. Integration and Cross-Platform Features

### 6.1 iOS-macOS Data Synchronization
- [ ] Implement CloudKit sync for user preferences
  - Sensor configurations and calibrations
  - User preferences and settings
  - Historical data backup
- [ ] Create Handoff support
  - Continue monitoring between iOS and macOS
  - Context preservation across devices
- [ ] Add Universal Control integration
  - Shared sensor access across devices
  - Unified notification system

### 6.2 Advanced Sensor Integration
- [ ] Implement sensor auto-discovery and pairing
  - Automatic Arduino sensor detection
  - RuuviTag advertisement parsing
  - Conflict resolution for multiple sensors
- [ ] Create sensor validation framework
  - Cross-reference readings between multiple sensors
  - Anomaly detection and alerts
  - Automatic sensor switching on failure
- [ ] Add sensor calibration wizard
  - Guided calibration process
  - Reference sensor comparison
  - Validation and accuracy testing

### 6.3 External Service Integration
- [ ] Add weather service integration for validation
  - Compare readings with local weather stations
  - Calibration assistance using reference data
- [ ] Implement HomeKit integration
  - Expose sensors as HomeKit accessories
  - Automation triggers for smart home systems
- [ ] Create export and sharing capabilities
  - Data export in multiple formats (CSV, JSON)
  - Sharing readings via social media or messaging
  - Integration with health and fitness apps

## 7. Testing and Quality Assurance

### 7.1 Unit and Integration Testing
- [ ] Create comprehensive unit test suite for iOS/macOS
  - BLE communication layer testing
  - Data parsing and validation testing
  - Widget and App Intent functionality
- [ ] Implement Arduino firmware testing
  - Sensor reading accuracy validation
  - BLE protocol compliance testing
  - Power consumption measurement
- [ ] Add integration testing
  - End-to-end communication testing
  - Multi-device scenario testing
  - Error condition handling validation

### 7.2 User Experience Testing
- [ ] Conduct usability testing with target users
  - Interface clarity and ease of use
  - Setup and pairing process evaluation
  - Accessibility compliance validation
- [ ] Perform battery life testing
  - iOS app background usage monitoring
  - Arduino sensor power consumption analysis
  - Optimization recommendations
- [ ] Test connection reliability
  - Range testing in various environments
  - Interference resilience evaluation
  - Reconnection performance measurement

### 7.3 Performance and Security Testing
- [ ] Conduct performance analysis
  - App launch time and responsiveness
  - Memory usage optimization
  - BLE communication efficiency
- [ ] Implement security testing
  - BLE communication security audit
  - Data storage encryption validation
  - Privacy compliance verification
- [ ] Add stress testing
  - Long-term operation stability
  - High-frequency data transmission testing
  - Error recovery validation

## 8. Documentation and Developer Resources

### 8.1 User Documentation
- [ ] Create comprehensive user guide
  - Initial setup and sensor pairing instructions
  - Feature overview and usage examples
  - Troubleshooting guide for common issues
- [ ] Develop quick start guide
  - Step-by-step sensor setup process
  - Basic app configuration
  - Widget and Siri setup instructions
- [ ] Create video tutorials
  - Arduino sensor assembly and programming
  - iOS/macOS app setup and configuration
  - Advanced features demonstration

### 8.2 Technical Documentation
- [ ] Document API and BLE protocol specifications
  - Characteristic definitions and data formats
  - Error codes and handling procedures
  - Extension points for additional sensors
- [ ] Create developer integration guide
  - Third-party app integration possibilities
  - Data format specifications
  - SDK documentation for external developers
- [ ] Maintain system architecture documentation
  - Component interaction diagrams
  - Data flow documentation
  - Security and privacy implementation details

### 8.3 Maintenance Documentation
- [ ] Create troubleshooting procedures
  - Common connection issues and solutions
  - Sensor calibration and replacement procedures
  - Software update and rollback procedures
- [ ] Document update and deployment processes
- [ ] Maintain changelog and version history
  - Feature additions and improvements
  - Bug fixes and security updates
  - Breaking changes and migration guides

## 9. Deployment and Distribution

### 9.1 iOS App Store Preparation
- [ ] Configure App Store Connect metadata
  - App description, keywords, and screenshots
  - Privacy policy and data usage disclosure
  - Age rating and content guidelines compliance
- [ ] Prepare marketing materials
  - App Store screenshots for all device sizes
  - App preview videos demonstrating key features
  - Promotional text and feature highlights
- [ ] Implement analytics and crash reporting
  - Firebase Analytics or similar for usage insights
  - Crash reporting with symbolication
  - Performance monitoring and optimization

### 9.2 macOS App Store Preparation
- [ ] Configure macOS-specific App Store requirements
  - Sandboxing compliance and entitlements
  - Notarization for distribution outside App Store
  - macOS version compatibility testing
- [ ] Create macOS installer package
  - Direct distribution option alongside App Store
  - Automatic update mechanism
  - Uninstaller and clean removal process

### 9.3 Arduino Distribution
- [ ] Create Arduino IDE library package
  - Library manager compatible format
  - Example sketches and documentation
  - Version management and updates
- [ ] Prepare hardware kit documentation
  - Component sourcing guide
  - Assembly instructions with diagrams
  - Testing and validation procedures
- [ ] Set up community support
  - GitHub repository for issues and discussions
  - Wiki with advanced configuration options
  - Community contribution guidelines

## 10. Maintenance and Long-term Support

### 10.1 Monitoring and Analytics
- [ ] Implement usage analytics
  - Feature usage tracking (privacy-compliant)
  - Performance metrics collection
  - Error rate monitoring and alerting
- [ ] Set up app performance monitoring
  - Crash rate tracking and analysis
  - Battery usage monitoring
  - User retention and engagement metrics
- [ ] Create automated testing pipeline
  - Continuous integration for code changes
  - Automated testing on multiple device configurations
  - Performance regression detection

### 10.2 Update and Maintenance Procedures
- [ ] Establish regular update schedule
  - Monthly minor updates for bug fixes
  - Quarterly major updates for new features
  - Emergency security update procedures
- [ ] Create user feedback collection system
  - In-app feedback mechanism
  - App Store review monitoring and response
  - Beta testing program for power users
- [ ] Implement A/B testing framework
  - Feature rollout testing
  - UI/UX improvement validation
  - Performance optimization testing

### 10.3 Future Enhancement Planning
- [ ] Roadmap for additional sensor types
  - Air quality sensors integration
  - Light and UV sensors
  - Pressure and altitude sensors
- [ ] Plan for emerging technology integration
  - Matter/Thread compatibility for smart homes
  - Apple Watch companion app
  - AR visualization features
- [ ] Community and ecosystem development
  - Third-party sensor manufacturer partnerships
  - Developer API for custom integrations
  - Open source components and contributions

## Implementation Timeline

### Phase 1 (Months 1-2): Foundation and Core Features
- Project setup and Arduino code consolidation
- iOS app architecture refinement
- Basic macOS app creation
- Core BLE functionality enhancement

### Phase 2 (Months 3-4): Feature Development
- Advanced sensor features and diagnostics
- Enhanced UI/UX implementation
- Widget and Siri integration improvements
- Cross-platform data synchronization

### Phase 3 (Months 5-6): Integration and Testing
- Comprehensive testing implementation
- Advanced integration features
- Performance optimization
- Documentation creation

### Phase 4 (Months 7-8): Deployment and Polish
- App Store preparation and submission
- Final testing and bug fixes
- Marketing material creation
- Community support setup

## Success Metrics
- BLE connection success rate >95%
- App crash rate <0.5%
- Battery consumption <5% per hour
- Sensor accuracy within ±0.1°C and ±1%
- App Store rating >4.5 stars
- User retention rate >70% after 30 days

## Risk Mitigation
- **Hardware Dependencies**: Maintain multiple sensor options and suppliers
- **App Store Approval**: Follow guidelines strictly and prepare for review cycles
- **BLE Compatibility**: Test across wide range of iOS/macOS versions and devices
- **Battery Life**: Implement aggressive power optimization and monitoring
- **User Adoption**: Focus on intuitive UX and comprehensive onboarding