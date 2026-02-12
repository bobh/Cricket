# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS SwiftUI application that connects to Bluetooth Low Energy (BLE) sensors for environmental monitoring (temperature and humidity). The app supports two types of BLE sensors:

1. **Standard BLE sensors** using Environmental Sensing Service (181A) with standard characteristics
2. **RuuviTag sensors** using manufacturer-specific advertisement data

## Architecture

### Core Components

- **BluetoothViewModel** (`ContentView.swift:14-98`): Handles standard BLE sensor communication using CBCentralManager and CBPeripheral delegates. Connects to sensors with Environmental Sensing Service, reads temperature (2A6E) and humidity (2A6F) characteristics.

- **RuuviTagViewModel** (`RuuviTagViewModel.swift`): Specialized for RuuviTag sensors that broadcast data via manufacturer advertisement packets. Parses RAWv1 format data without establishing connections.

- **ContentView** (`ContentView.swift:100-183`): Main UI that displays sensor data based on selected source (BLE or Ruuvi). Uses @AppStorage for persistence across app launches.

- **SettingsView** (`SettingsView.swift`): Simple settings interface allowing users to switch between "Standard BLE" and "RuuviTag" sensor sources.

### Data Sharing Architecture

The app uses **App Groups** (`group.com.yourcompany.BLECentral`) to share sensor data between the main app and widgets/app intents:

- Temperature and humidity values stored in shared UserDefaults
- **ReadingsWidget** (`ReadingsWidget.swift`): iOS widget displaying current sensor readings
- **ReadingsAppIntent** (`ReadingsAppIntent.swift`): App Intents for Siri/Shortcuts integration

### BLE Data Handling

**Standard BLE sensors:**
- Temperature characteristic (2A6E): IEEE-11073 16-bit SFLOAT format, divided by 100
- Humidity characteristic (2A6F): Similar format, divided by 100
- Supports both read and notify operations
- Updates shared storage and triggers widget refresh on value changes

**RuuviTag sensors:**
- Manufacturer ID: 0x0499 (bytes [0x99, 0x04])
- RAWv1 format (data[2] == 0x03)
- Temperature: bytes 3-4 as signed int16, divided by 100 
- Humidity: bytes 5-6 as unsigned int16, divided by 100
- Advertisement-based, no connection required

## Development Commands

### Building and Testing
- Build the project using Xcode's standard build system (⌘B)
- The project targets iOS and includes WidgetKit extension
- No custom build scripts or testing frameworks are configured

### Key Configuration
- **App Group ID**: `group.com.yourcompany.BLECentral` - used for data sharing between app, widgets, and intents
- **Bluetooth Usage Description**: Required for BLE access, defined in Info.plist
- **Widget Configuration**: StaticConfiguration widget named "ReadingsWidget"

## Important Implementation Details

### BLE Connection Management
- BluetoothViewModel connects to first discovered peripheral (ContentView.swift:40-47)
- Automatic service and characteristic discovery
- Real-time updates via CBPeripheral notifications
- Connection status displayed in UI

### Data Persistence Strategy
- All sensor data stored in shared UserDefaults with App Group
- Widget timeline refreshed via `WidgetCenter.shared.reloadAllTimelines()` on data updates
- Settings persist across app launches using @AppStorage

### Arduino Sensor Compatibility
The iOS app is designed to work with Arduino Nano 33 Sense Rev 2 peripherals that:
- Implement Environmental Sensing Service (UUID: 181A)
- Provide temperature (2A6E) and humidity (2A6F) characteristics
- Use sint16 format for temperature (supports negative values)
- Use uint16 format for humidity
- Values transmitted as (actual_value × 100) for 0.01 precision

### Error Handling
- Default sensor values: "--" when no data available
- RuuviTag parser validates manufacturer ID and data format
- BLE errors handled through delegate methods
- Sensor failure values: -32768 (temperature), 65535 (humidity) from Arduino

## Widget and App Intents Integration

- Widget updates automatically when sensor data changes
- App Intents provide GetTemperatureIntent and GetHumidityIntent for Siri integration  
- All use shared UserDefaults for consistent data access
- Widget display format: "Temperature: XX.X°C" and "Humidity: XX.X%"