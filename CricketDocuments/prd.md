# Demetor Hyperlocal Environmental Monitoring System
## Product Requirements Document (PRD)

### Document information
- **Version**: 2.0
- **Date**: October 6, 2025
- **Status**: Updated
- **Product**: Demetor App - Hyperlocal Environmental Monitoring System
- **Revision Notes**: Updated to reflect WWDC 2025 features and remove inapplicable integrations

## Product overview

### Product summary
Demetor is a comprehensive hyperlocal environmental monitoring system that provides accurate temperature and humidity readings precisely where the user is located. The system addresses the fundamental limitation that modern smartphones cannot provide reliable environmental data due to inadequate sensors and thermal interference from device components.

The solution combines external Bluetooth Low Energy (BLE) sensors with native iOS/macOS applications to deliver real-time, hyperlocal environmental data directly to users' devices, complete with widget integration, Siri support, interactive snippets (WWDC 2025), and automation capabilities via App Intents and Shortcuts.

## Goals

### Business goals
- Establish Demetor as the premier solution for hyperlocal environmental monitoring
- Create a scalable platform supporting both commercial and DIY sensor ecosystems
- Enable seamless integration with iOS ecosystem features (widgets, interactive snippets, Siri, App Intents, Shortcuts)
- Leverage WWDC 2025 system integration capabilities for enhanced user experience
- Generate value through superior accuracy compared to distant weather stations

### User goals
- Access real-time temperature and humidity data for their exact location
- Eliminate reliance on distant weather station data that may not reflect local conditions
- Integrate environmental data into daily routines through iOS widgets and automation
- Choose between ready-to-use commercial sensors or customizable DIY solutions
- Receive reliable, consistent environmental monitoring without device thermal interference

### Non-goals
- Cloud-based data storage or synchronization (all data remains local)
- Social sharing features or collaborative monitoring
- Handoff/Continuity features between devices (sensor is location-specific)
- Historical data analysis or trend visualization (future enhancement)
- Support for non-BLE sensor technologies
- Integration with third-party weather services
- Commercial weather station replacement for public use

## User personas

### Primary maker enthusiast
Technical users who enjoy building and customizing IoT solutions. Comfortable with Arduino development and interested in extending functionality. Values open-source approach and hardware flexibility.

### Convenience-focused consumer
Users who want immediate functionality without technical setup. Prefers commercial sensors like RuuviTag for instant deployment. Values simplicity and reliability over customization.

### Smart home integrator
Power users who integrate environmental monitoring into broader home automation systems. Uses Siri integration and iOS Shortcuts for automation. Requires consistent, accessible data for decision-making.

### Role-based access
All users have identical access to core functionality. No authentication or user management required as the system operates entirely locally on user devices.

## Functional requirements

### Core sensor connectivity (High priority)
- **FR-001**: Support connection to Arduino-based BLE environmental sensors
- **FR-002**: Support connection to RuuviTag commercial environmental sensors
- **FR-003**: Maintain stable BLE connections with automatic reconnection
- **FR-004**: Parse temperature data with 0.1°C precision including negative temperatures
- **FR-005**: Parse humidity data with 0.1% precision
- **FR-006**: Handle sensor error states gracefully with appropriate user feedback

### iOS application features (High priority)
- **FR-007**: Display real-time temperature and humidity readings in native iOS app
- **FR-008**: Provide iOS Home Screen widget for quick environmental data access
- **FR-009**: Implement Interactive Snippets (WWDC 2025) for Spotlight search integration
- **FR-010**: Enable Siri voice queries for current temperature and humidity
- **FR-011**: Support iOS Shortcuts automation via App Intents framework
- **FR-012**: Provide Control Center integration for quick sensor status view
- **FR-013**: Allow switching between sensor types (Arduino vs RuuviTag) in settings
- **FR-014**: Persist user preferences and sensor data across app launches
- **FR-015**: Display Arduino reset instructions when switching from RuuviTag mode

### Arduino DIY sensor system (Medium priority)
- **FR-016**: Provide complete Arduino Nano 33 Sense Rev 2 firmware for environmental sensing
- **FR-017**: Implement custom 128-bit BLE UUIDs for environmental service and characteristics (Bluetooth SIG compliance)
- **FR-018**: Support IEEE 754 float32 data format for temperature and humidity
- **FR-019**: Support power-optimized operation for extended battery life
- **FR-020**: Include sensor averaging algorithms for improved accuracy
- **FR-021**: Provide serial debug output for development and troubleshooting

### Platform expansion (Medium priority)
- **FR-022**: Develop macOS companion application with identical functionality
- **FR-023**: Maintain local data persistence between iOS and macOS versions
- **FR-024**: Support universal app architecture for seamless cross-platform experience

## User experience

### Entry points
Users discover the system through three primary paths: purchasing RuuviTag sensors and seeking compatible apps, exploring Arduino IoT projects, or searching for hyperlocal weather solutions in the App Store.

### Core experience
The central experience revolves around immediate access to environmental data. Users open the app to see current temperature and humidity displayed prominently, with clear connection status. Interactive Snippets (WWDC 2025) provide live sensor data directly in Spotlight search results. The iOS widget provides instant access without launching the app, while Siri integration enables hands-free queries during daily activities. Control Center integration offers quick status views with a single swipe.

### Advanced features
Power users leverage iOS Shortcuts to create automation based on environmental conditions, such as adjusting smart home systems when humidity exceeds thresholds. DIY enthusiasts customize Arduino sensors with additional capabilities while maintaining compatibility with the core app.

### UI/UX highlights
The interface prioritizes clarity with large, readable temperature and humidity displays, intuitive sensor switching, and immediate visual feedback for connection status. The design follows iOS Human Interface Guidelines for consistency and accessibility.

## Narrative

As someone who needs accurate environmental data for my specific location, I want to place a small sensor near me and instantly see real-time temperature and humidity readings on my iPhone without dealing with distant weather station data that doesn't reflect conditions in my room, workspace, or immediate outdoor area, so I can make informed decisions about comfort, health, and daily activities while having the flexibility to use either convenient commercial sensors or customize my own DIY solution.

## Success metrics

### User-centric metrics
- App Store rating above 4.5 stars
- User retention rate above 80% after first week
- Widget usage rate above 60% of active users
- Average session duration of 30+ seconds (indicating data value)
- Siri integration usage by 40% of users within first month

### Business metrics
- 10,000+ app downloads in first year
- Support adoption of 500+ Arduino DIY sensors in maker community
- Compatible sensor ecosystem growth of 25% quarterly
- Cross-platform (iOS/macOS) user adoption rate of 30%
- Zero critical security or privacy incidents

### Technical metrics
- BLE connection success rate above 95%
- App crash rate below 0.5%
- Widget update latency under 5 seconds
- Battery impact under 5% per hour during active monitoring
- Arduino sensor battery life exceeding 24 hours continuous operation

## Technical considerations

### Integration points
The system integrates with iOS Core Bluetooth framework for BLE communication, WidgetKit for Home Screen widgets, Interactive Snippets (WWDC 2025) for Spotlight integration, App Intents for Siri integration, and iOS Shortcuts for automation. Control Center widgets provide quick status views. Arduino sensors use custom 128-bit BLE UUIDs (Bluetooth SIG compliant) for environmental service and temperature/humidity characteristics, transmitting IEEE 754 float32 data. RuuviTag sensors use manufacturer advertisement data with RAWv1 format parsing.

### Data storage and privacy
All environmental data remains local on user devices using iOS App Groups for sharing between main app and extensions. No cloud storage or external data transmission occurs, ensuring complete user privacy. Sensor readings are temporarily cached for widget and Siri access.

### Scalability and performance
The BLE architecture naturally limits concurrent connections, supporting one sensor per device instance. The iOS app efficiently manages memory usage under 200MB and maintains 60fps UI performance. Arduino sensors optimize power consumption through change-based transmission and intelligent averaging.

### Potential challenges
BLE connection reliability may vary with environmental interference and device distance. iOS background app refresh policies could affect widget update frequency. Arduino development requires technical knowledge that may limit DIY adoption. RuuviTag sensor availability and cost may impact commercial sensor adoption.

## Milestones and sequencing

### Project estimate
Complete system development estimated at 6-8 months with 2-3 person development team. iOS app development requires 3-4 months, Arduino firmware 2-3 months, and macOS app 2 months with shared codebase.

### Team size
Optimal team includes iOS/macOS developer, Arduino/embedded systems developer, and product manager/designer. Additional QA support recommended for BLE compatibility testing across sensor types.

### Phase 1: Core iOS app and Arduino sensor (Months 1-4)
Develop fully functional iOS app with Arduino BLE sensor support, including widgets and basic Siri integration. Complete Arduino firmware with Environmental Sensing Service implementation.

### Phase 2: RuuviTag integration and advanced features (Months 5-6)
Add RuuviTag sensor support to iOS app, implement comprehensive App Intents for Shortcuts automation, and enhance widget functionality with improved update reliability.

### Phase 3: macOS expansion and optimization (Months 7-8)
Develop macOS companion app with universal binary support, optimize cross-platform data synchronization, and conduct comprehensive testing across all supported platforms and sensor types.

## User stories

### US-001: Basic environmental monitoring
**Title**: View current temperature and humidity readings
**Description**: As a user, I want to see current temperature and humidity readings from my external sensor so I can monitor environmental conditions at my exact location.
**Acceptance criteria**:
- Temperature displayed with 0.1°C precision including negative values
- Humidity displayed with 0.1% precision
- Readings update automatically when sensor provides new data
- Clear visual indicators show data freshness and connection status
- Error states display meaningful messages when sensor unavailable

### US-002: Sensor device connection
**Title**: Connect to BLE environmental sensor
**Description**: As a user, I want the app to automatically discover and connect to my environmental sensor so I can start monitoring without complex pairing procedures.
**Acceptance criteria**:
- App automatically scans for compatible BLE sensors on launch
- Connection process completes within 10 seconds of sensor discovery
- Connection status clearly displayed with visual indicators
- Automatic reconnection after connection loss within 30 seconds
- Support for both Arduino and RuuviTag sensor types

### US-003: Sensor type selection
**Title**: Choose between Arduino and RuuviTag sensors
**Description**: As a user, I want to select whether I'm using an Arduino sensor or RuuviTag sensor so the app uses the appropriate communication protocol.
**Acceptance criteria**:
- Settings interface provides clear sensor type selection
- Sensor type preference persists across app launches
- Switching sensor types takes effect immediately
- App displays current sensor type in main interface
- Both sensor types provide identical user experience for core functionality

### US-004: iOS widget integration
**Title**: Access readings via Home Screen widget
**Description**: As a user, I want to see current environmental readings on my Home Screen widget so I can check conditions without opening the app.
**Acceptance criteria**:
- Widget displays current temperature and humidity readings
- Widget updates automatically when new sensor data received
- Widget shows placeholder values when no sensor connected
- Widget maintains readable format in all supported sizes
- Widget data remains current even when main app not recently opened

### US-004A: Interactive Snippets (WWDC 2025)
**Title**: View live sensor data in Spotlight search
**Description**: As a user, I want to see live temperature and humidity readings directly in Spotlight search results so I can check conditions instantly without opening the app.
**Acceptance criteria**:
- Spotlight search for "temperature" or "Demetor" shows interactive snippet with live data
- Snippet displays current temperature and humidity with clear formatting
- Snippet updates automatically when new sensor data becomes available
- Tapping snippet opens main app to full dashboard
- Snippet shows appropriate placeholder when sensor disconnected

### US-005: Siri voice integration
**Title**: Query environmental data via Siri
**Description**: As a user, I want to ask Siri for current temperature and humidity readings so I can get environmental data hands-free.
**Acceptance criteria**:
- Siri responds to "What's the temperature?" with current reading
- Siri responds to "What's the humidity?" with current reading
- Voice responses include appropriate units (Celsius, percentage)
- Siri gracefully handles cases when no sensor data available
- Integration works both via voice commands and typed queries

### US-006: iOS Shortcuts automation
**Title**: Create automation based on environmental conditions
**Description**: As a power user, I want to create iOS Shortcuts that trigger based on environmental readings so I can automate responses to environmental changes.
**Acceptance criteria**:
- App Intents provide current temperature value to Shortcuts
- App Intents provide current humidity value to Shortcuts
- Shortcuts can access readings even when app not actively running
- Integration supports conditional logic in Shortcuts workflows
- Automation triggers reliably based on environmental thresholds

### US-007: Arduino DIY sensor setup
**Title**: Deploy custom Arduino environmental sensor
**Description**: As a maker, I want to build and deploy an Arduino-based environmental sensor that works seamlessly with the iOS app so I can customize my monitoring solution.
**Acceptance criteria**:
- Arduino firmware compiles and uploads successfully to Nano 33 Sense Rev 2
- Sensor advertises using custom 128-bit BLE UUIDs (Bluetooth SIG compliant)
- iOS app discovers and connects to Arduino sensor automatically
- Temperature and humidity data transmitted with correct precision and format (IEEE 754 float32)
- Power optimization provides 24+ hours operation on battery power

### US-008: Commercial RuuviTag integration
**Title**: Use RuuviTag commercial sensor
**Description**: As a convenience-focused user, I want to use a RuuviTag sensor with the app so I can start monitoring immediately without building hardware.
**Acceptance criteria**:
- App discovers RuuviTag sensors via BLE advertisement scanning
- RuuviTag data parsed correctly from manufacturer advertisement packets
- Temperature and humidity readings match RuuviTag specifications
- Connection status accurately reflects RuuviTag availability
- No additional configuration required beyond sensor type selection

### US-009: Cross-platform data access
**Title**: Access environmental data on macOS
**Description**: As a user with multiple Apple devices, I want to access my environmental sensor data on both iOS and macOS so I can monitor conditions from any device.
**Acceptance criteria**:
- macOS app provides identical functionality to iOS version
- Sensor connections work seamlessly across both platforms
- Local data persistence maintains consistency on each device
- Widget functionality available on macOS where supported
- Universal app architecture provides native experience on each platform

### US-010: Connection reliability management
**Title**: Handle sensor connection interruptions
**Description**: As a user, I want the app to handle sensor disconnections gracefully and reconnect automatically so my monitoring continues reliably.
**Acceptance criteria**:
- App detects connection loss within 10 seconds
- Automatic reconnection attempts begin immediately after detection
- User interface clearly indicates connection state changes
- Data display shows last known readings during disconnection
- Successful reconnection restores normal operation without user intervention

### US-011: Sensor data validation
**Title**: Detect and handle invalid sensor readings
**Description**: As a user, I want the app to detect invalid sensor data and display appropriate messages so I know when readings are unreliable.
**Acceptance criteria**:
- App recognizes sensor error values (-32768 for temperature, 65535 for humidity)
- Invalid readings display as "--" or similar placeholder
- Error conditions trigger appropriate user notifications
- Recovery from error states occurs automatically when valid data resumes
- Widget and Siri integration handle error states gracefully

### US-012: Settings persistence
**Title**: Maintain app configuration across sessions
**Description**: As a user, I want my app settings and preferences to persist across app launches so I don't need to reconfigure repeatedly.
**Acceptance criteria**:
- Sensor type selection persists across app launches
- Last known sensor readings available immediately on app launch
- Connection preferences maintained in persistent storage
- Settings shared between main app and extensions via App Groups
- App state restoration works correctly after device restart

### US-013: Accessibility support
**Title**: Access environmental data with assistive technologies
**Description**: As a user with accessibility needs, I want full VoiceOver and assistive technology support so I can use the app effectively.
**Acceptance criteria**:
- All interface elements have appropriate accessibility labels
- VoiceOver announces temperature and humidity readings clearly
- Settings interface fully navigable with assistive technologies
- Dynamic Type scaling supported for text size preferences
- High contrast and reduced motion settings respected

### US-014: Battery impact optimization
**Title**: Minimize device battery consumption
**Description**: As a mobile user, I want the app to minimize battery consumption so environmental monitoring doesn't significantly impact my device usage.
**Acceptance criteria**:
- App consumes less than 5% battery per hour during active monitoring
- Background processing minimized when app not active
- BLE operations optimized for power efficiency
- Widget updates balanced between freshness and power consumption
- Arduino sensor battery life exceeds 24 hours continuous operation

### US-015: Error recovery and troubleshooting
**Title**: Recover from system errors and get troubleshooting help
**Description**: As a user encountering issues, I want clear error messages and recovery options so I can resolve problems independently.
**Acceptance criteria**:
- Bluetooth permission issues clearly explained with resolution steps
- BLE connection failures provide specific error information
- Sensor compatibility issues identified with helpful suggestions
- App crashes minimized with graceful error handling
- Debug information available for technical troubleshooting when needed