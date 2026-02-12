# Demetor for macOS

## Hyperlocal Environmental Monitoring

Demetor for macOS empowers curious individuals to become citizen scientists by building their own hyperlocal environmental monitoring network. The app is intentionally incomplete without external sensors - this isn't a bug, it's the whole point!

## Features

### 🔧 **Maker Philosophy**
- **Intentionally incomplete** without external sensors
- Celebrates the **IKEA effect** - build it yourself, value it more
- Encourages **citizen science** and hyperlocal data collection
- **Anyone can play with cutting-edge electronics**

### 📡 **Dual Sensor Support**
- **Arduino DIY Path**: Build from Arduino Nano 33 Sense Rev 2
- **RuuviTag Path**: Use commercial sensors for instant monitoring
- Switch between sensor types anytime

### 🖥️ **Native macOS Experience**
- **Split-view interface** with sidebar navigation
- **Environmental monitoring** with large, readable displays
- **Real-time BLE connectivity** to your sensors
- **Settings and about pages** with maker resources

## 📚 **Sensor Documentation & Setup**

**⚠️ Important**: These apps require external sensors to function. For complete setup instructions, visit:
**https://github.com/bobh/Sensors**

## Supported Sensors

### Arduino DIY Sensors
- **Hardware**: Arduino Nano 33 Sense Rev 2 (with HS3003 sensor)
- **Communication**: BLE Environmental Sensing Service (181A)
- **Data Format**: 
  - Temperature: sint16 (supports negative temperatures)
  - Humidity: uint16
- **Perfect for**: Learning, customization, maximum maker pride
- **Setup Guide**: See https://github.com/bobh/Sensors for complete Arduino build instructions

### RuuviTag Commercial Sensors  
- **Hardware**: RuuviTag environmental sensors
- **Communication**: BLE manufacturer advertisement data
- **Data Format**: RAWv1 format parsing
- **Perfect for**: Instant monitoring, reliability, good entry point
- **Setup Guide**: See https://github.com/bobh/Sensors for RuuviTag configuration

## System Requirements

- **macOS**: 13.0 or later
- **Bluetooth**: BLE 4.0+ support
- **Hardware**: Intel or Apple Silicon Mac
- **External Sensor**: Arduino Nano 33 Sense Rev 2 or RuuviTag (required)

## App Architecture

### Core Components
- **BluetoothViewModel**: Handles Arduino BLE sensor communication
- **RuuviTagViewModel**: Manages RuuviTag advertisement parsing  
- **ContentView**: Split-view interface with sidebar navigation
- **MonitorView**: Environmental data display
- **SettingsView**: Sensor switching and maker resources
- **AboutView**: Philosophy and supported sensors

### Data Management
- **App Groups**: Local data sharing (group.com.yourcompany.DemetorMac)
- **UserDefaults**: Persistent storage for readings and preferences
- **No Cloud**: All data remains on your Mac

## Getting Started

1. **Choose Your Path**: Arduino DIY or RuuviTag commercial
2. **Set up your sensor**: Follow Arduino guide or RuuviTag instructions
3. **Launch Demetor**: The app will scan for your sensor automatically
4. **Monitor your environment**: View hyperlocal temperature and humidity
5. **Explore settings**: Switch sensor types, access maker resources

## Philosophy

Modern smartphones can't provide truly local environmental data because they lack proper sensors and generate heat that distorts readings. Demetor celebrates this limitation by turning it into an opportunity for hands-on learning and experimentation.

**The IKEA Effect**: When you invest effort in building something, you value it more and engage deeper with the results. Whether you build an Arduino sensor or configure a RuuviTag, you're creating a personal connection to your hyperlocal data.

**Citizen Science**: Your sensor contributes to a distributed network of hyperlocal environmental monitoring. No weather station can tell you the conditions in your specific workspace, room, or immediate outdoor area.

## Development Notes

This macOS app shares the same philosophy as the iOS version but is built as a separate, native macOS application. The SwiftUI codebase adapts the iOS components for macOS conventions:

- **Navigation**: Split-view with sidebar (instead of tab/navigation stack)
- **Window Management**: Proper macOS window sizing and toolbar
- **UI Patterns**: macOS-appropriate spacing, colors, and interactions
- **Data Sharing**: macOS App Groups for potential future extensions

## Future Enhancements

- **Menu bar integration** for quick sensor readings
- **Notification Center widgets** for glanceable data
- **Multiple sensor support** for different rooms/locations
- **Data export** for analysis and sharing
- **Community features** for connecting with other citizen scientists

---

**Remember**: Demetor is intentionally incomplete without an external sensor. This is the core philosophy - embrace the maker journey and build your own hyperlocal monitoring network!