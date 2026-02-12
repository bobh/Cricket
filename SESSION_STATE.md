# Demetor Project - Session State Snapshot
**Date:** October 8, 2025
**Status:** Ready for macOS WWDC 2025 feature testing

---

## 📋 Current Project Status

### ✅ Completed Work

#### **macOS Version** (`/Users/bobh/Desktop/Demetor/MACOS/DemetorMac/`)
- **Status:** Fully functional + WWDC 2025 features implemented
- **Features:**
  - ✅ Arduino Nano 33 Sense Rev 2 BLE connection (custom 128-bit UUIDs)
  - ✅ RuuviTag beacon scanning (RAWv1/RAWv2 support)
  - ✅ Sensor switching (hammer/wireless icons)
  - ✅ Temperature display (Celsius + Fahrenheit for Arduino)
  - ✅ Humidity display
  - ✅ **App Intents for Siri** - Compiled and metadata generated
  - ✅ **3 Shortcuts** - Temperature, Humidity, Sensor Status
  - ✅ Shortened Siri phrases: "Demetor temperature", "Demetor humidity"
- **Build Status:** BUILD SUCCEEDED
- **Next Step:** Test Siri and Shortcuts integration

#### **iOS Simplified Version** (`/Users/bobh/Desktop/Demetor/IOS/BLE_Central.xcodeproj`)
- **Status:** Fully functional
- **Features:**
  - ✅ Arduino BLE connection working
  - ✅ RuuviTag support working
  - ✅ Simple icon switcher UI
  - ✅ Bluetooth permissions properly configured
  - ✅ Info.plist fixed with all required keys
  - ✅ Tested on iPhone 15 Pro Max
- **Build Status:** BUILD SUCCEEDED
- **Ready for deployment**

#### **iOS Verbose Version** (`/Users/bobh/Desktop/Demetor Verbose/IOS/BLE_Central.xcodeproj`)
- **Status:** Fully functional
- **Features:**
  - ✅ Arduino BLE connection working with debug logging
  - ✅ RuuviTag support working
  - ✅ Welcome screens, Settings, full verbose UI
  - ✅ All Info.plist fixes applied
  - ✅ App Groups removed
  - ✅ Custom 128-bit UUIDs implemented
  - ✅ IEEE 754 float32 parsing working
- **Build Status:** BUILD SUCCEEDED
- **Console Output Verified:**
  ```
  [BLE] Connected to peripheral: A5DB3058...
  [BLE] Temperature parsed: 26.0°C
  [BLE] Humidity parsed: 36.3%
  ```
- **Ready for deployment**

---

## 🔧 Technical Details

### **Bluetooth Configuration**

#### **Custom 128-bit UUIDs (Bluetooth SIG Compliant):**
```
Service:      5971E8F1-BC4D-4A5F-A6FD-3591131A98C6
Temperature:  78B20AF1-E597-40C1-A69C-304205B7E099
Humidity:     0BA15AA1-A805-4205-BC82-AF2E4A9364C5
```

#### **Data Format:**
- **Arduino:** IEEE 754 float32 (4 bytes, little-endian)
- **RuuviTag:**
  - RAWv1 (format 0x03): sint16/uint16, big-endian, 0.01 resolution
  - RAWv2 (format 0x05): sint16/uint16, big-endian, 0.005/0.0025 resolution

### **Key Fixes Applied**

#### **iOS Info.plist Requirements:**
```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
<key>CFBundleExecutable</key>
<string>$(EXECUTABLE_NAME)</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>CFBundleShortVersionString</key>
<string>1.0</string>
<key>CFBundlePackageType</key>
<string>APPL</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Demetor needs Bluetooth to connect...</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Demetor connects to BLE sensors...</string>
<key>UILaunchScreen</key>
<dict>
    <key>UIImageName</key>
    <string>AppIcon</string>
</dict>
<key>UISupportedInterfaceOrientations</key>
<array>...</array>
```

#### **Xcode project.pbxproj:**
```
GENERATE_INFOPLIST_FILE = NO;
INFOPLIST_FILE = BLE_Central/Info.plist;
```

#### **ViewModels:**
- Changed from `@AppStorage` with App Groups to `@Published` properties
- Added `DispatchQueue.main` for thread safety
- Added disconnect/reconnect handlers with 2-second delays
- Removed `WidgetCenter` dependency

---

## 🎯 Next Actions (In Order)

### **1. Test macOS WWDC 2025 Features**

#### **A. Run Demetor macOS App:**
```bash
# App location:
/Users/bobh/Library/Developer/Xcode/DerivedData/DemetorMac-ailmkmuovgrtwshggjgybymuhvhq/Build/Products/Debug/Demetor_mac.app

# Or rebuild:
cd /Users/bobh/Desktop/Demetor/MACOS/DemetorMac
xcodebuild -project DemetorMac.xcodeproj -scheme Demetor_mac build
```

#### **B. Register App Intents (If Needed):**
```bash
pluginkit -a /Users/bobh/Library/Developer/Xcode/DerivedData/DemetorMac-ailmkmuovgrtwshggjgybymuhvhq/Build/Products/Debug/Demetor_mac.app
```

#### **C. Test Siri Commands:**
- Press `Fn+Space` and say: **"Demetor temperature"**
- Press `Fn+Space` and say: **"Demetor humidity"**
- Press `Fn+Space` and say: **"Demetor sensor"**

#### **D. Test Shortcuts App:**
1. Open **Shortcuts.app** (Applications folder)
2. Look for "Demetor" in sidebar
3. Click shortcuts to run:
   - Local Temperature
   - Local Humidity
   - Sensor Status

### **2. Phase 2 Features (Future)**
- Menu Bar widget for macOS
- Control Center widgets (iOS 18+/macOS 15+)
- Interactive Live Activities
- Focus Filters

---

## 📁 Project Structure

```
/Users/bobh/Desktop/Demetor/
├── MACOS/DemetorMac/
│   ├── DemetorMac.xcodeproj
│   └── DemetorMac/
│       ├── ContentView.swift
│       ├── BluetoothViewModel.swift
│       ├── RuuviTagViewModel.swift
│       ├── DemetorAppIntents.swift ⭐ NEW
│       ├── SettingsView.swift
│       ├── LEDColor.swift
│       └── Info.plist
├── IOS/
│   ├── BLE_Central.xcodeproj (Simplified - 290 lines)
│   └── BLE_Central/
│       ├── ContentView.swift
│       ├── RuuviTagViewModel.swift
│       └── Info.plist ✅ FIXED
└── DemetorDocuments/
    ├── PRD_Demetor_v2.0.md
    ├── SIRI_SETUP.md ⭐ NEW
    └── BLE_TROUBLESHOOTING.md ⭐ NEW

/Users/bobh/Desktop/Demetor Verbose/
└── IOS/
    ├── BLE_Central.xcodeproj (Verbose - 600+ lines)
    └── BLE_Central/
        ├── ContentView.swift ✅ FIXED
        ├── RuuviTagViewModel.swift ✅ FIXED
        ├── WelcomeView.swift
        ├── SettingsView.swift
        └── Info.plist ✅ FIXED
```

---

## 🔑 Key Files Modified

### **macOS:**
1. `/Users/bobh/Desktop/Demetor/MACOS/DemetorMac/DemetorMac/DemetorAppIntents.swift` ⭐ CREATED
2. `/Users/bobh/Desktop/Demetor/MACOS/DemetorMac/DemetorMac/BluetoothViewModel.swift` - Added UserDefaults saving
3. `/Users/bobh/Desktop/Demetor/MACOS/DemetorMac/DemetorMac/RuuviTagViewModel.swift` - Added UserDefaults saving

### **iOS Simplified:**
1. `/Users/bobh/Desktop/Demetor/IOS/BLE_Central/Info.plist` - Added all required keys
2. `/Users/bobh/Desktop/Demetor/IOS/BLE_Central.xcodeproj/project.pbxproj` - Added INFOPLIST_FILE
3. `/Users/bobh/Desktop/Demetor/IOS/BLE_Central/ContentView.swift` - @Published properties, no App Groups
4. `/Users/bobh/Desktop/Demetor/IOS/BLE_Central/RuuviTagViewModel.swift` - Fixed byte order, @Published

### **iOS Verbose:**
1. `/Users/bobh/Desktop/Demetor Verbose/IOS/BLE_Central/Info.plist` - Added all required keys
2. `/Users/bobh/Desktop/Demetor Verbose/IOS/BLE_Central.xcodeproj/project.pbxproj` - Added INFOPLIST_FILE
3. `/Users/bobh/Desktop/Demetor Verbose/IOS/BLE_Central/ContentView.swift` - Fixed UUIDs, @Published, debug logging
4. `/Users/bobh/Desktop/Demetor Verbose/IOS/BLE_Central/RuuviTagViewModel.swift` - Fixed byte order, @Published

---

## 🐛 Known Issues (All Resolved)

### ~~iOS App Not Requesting Bluetooth Permission~~
- **FIXED:** Added INFOPLIST_FILE to project.pbxproj
- **FIXED:** Added CFBundleIdentifier to Info.plist

### ~~iOS App Not Updating Readings~~
- **FIXED:** Changed from @AppStorage with App Groups to @Published
- **FIXED:** Updated to custom 128-bit UUIDs
- **FIXED:** Fixed data parsing from sint16 to IEEE 754 float32
- **FIXED:** Fixed RuuviTag byte order to big-endian

### ~~iOS Verbose Version Not Connecting~~
- **FIXED:** Added debug logging
- **FIXED:** Removed App Groups from ContentView @AppStorage
- **VERIFIED:** Connection working, data parsing successful

---

## 🎤 Siri Phrases Configured

### **Temperature:**
- "Demetor local temperature" ✅
- "Demetor temperature" ✅ (shortest)
- "Local temperature in Demetor"
- "What's my local temperature in Demetor"

### **Humidity:**
- "Demetor local humidity" ✅
- "Demetor humidity" ✅ (shortest)
- "Local humidity in Demetor"
- "What's my local humidity in Demetor"

### **Sensor Status:**
- "Demetor sensor status" ✅
- "Demetor sensor" ✅ (shortest)
- "Check my Demetor sensor"

**Note:** Apple requires `${applicationName}` in every phrase for AppShortcutsProvider

---

## 📊 App Intents Technical Details

### **UserDefaults Keys:**
```swift
"currentTemperature"  // "23.4 °C" format
"currentHumidity"     // "45.7 %" format
"connectionStatus"    // "Connected to Arduino" or "Receiving data from RuuviTag"
"sensorSource"        // "BLE" or "Ruuvi"
```

### **Metadata Location:**
```
/Users/bobh/Library/Developer/Xcode/DerivedData/DemetorMac-.../
Build/Products/Debug/Demetor_mac.app/Contents/Resources/Metadata.appintents/
├── extract.actionsdata
└── version.json
```

### **App Intents:**
1. `GetLocalTemperatureIntent` - Returns temperature string
2. `GetLocalHumidityIntent` - Returns humidity string
3. `GetSensorStatusIntent` - Returns connection status
4. `DemetorShortcuts: AppShortcutsProvider` - Defines Siri phrases

---

## 🧪 Testing Checklist

### **macOS:**
- [ ] App launches and connects to Arduino
- [ ] Temperature/humidity display and update
- [ ] Siri recognizes "Demetor temperature" command
- [ ] Siri returns correct temperature value
- [ ] Shortcuts app shows 3 Demetor shortcuts
- [ ] Shortcuts run successfully when clicked
- [ ] Sensor switching works (Arduino ↔ RuuviTag)

### **iOS Simplified:**
- [x] Bluetooth permission prompt appears ✅
- [x] Arduino connection successful ✅
- [x] Temperature/humidity update in real-time ✅
- [x] RuuviTag scanning works ✅
- [x] Sensor switching with reset message ✅

### **iOS Verbose:**
- [x] Bluetooth permission prompt appears ✅
- [x] Arduino connection successful ✅
- [x] Temperature/humidity update (verified: 26.0°C, 36.3%) ✅
- [x] Debug logging working ✅
- [x] Welcome screen displays ✅
- [x] Settings screen accessible ✅

---

## 💾 Build Commands Reference

### **macOS:**
```bash
cd /Users/bobh/Desktop/Demetor/MACOS/DemetorMac
xcodebuild -project DemetorMac.xcodeproj -scheme Demetor_mac build
```

### **iOS Simplified:**
```bash
cd /Users/bobh/Desktop/Demetor/IOS
xcodebuild -project BLE_Central.xcodeproj -scheme BLE_Central \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16 Pro' build
```

### **iOS Verbose:**
```bash
cd "/Users/bobh/Desktop/Demetor Verbose/IOS"
xcodebuild -project BLE_Central.xcodeproj -scheme BLE_Central \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16 Pro' build
```

---

## 🔄 Troubleshooting After System Reset

### **If Siri doesn't recognize Demetor:**
```bash
# Re-register app intents
pluginkit -a /path/to/Demetor_mac.app
pluginkit -r /path/to/Demetor_mac.app

# Or reset Spotlight index
rm -rf ~/Library/Caches/com.apple.Spotlight/
killall Spotlight
```

### **If App Intents metadata missing:**
```bash
# Rebuild from scratch
cd /Users/bobh/Desktop/Demetor/MACOS/DemetorMac
xcodebuild -project DemetorMac.xcodeproj -scheme Demetor_mac clean build
```

### **If iOS apps don't connect:**
1. Check Arduino is powered and reset (white button)
2. Verify iPhone Bluetooth is ON in Settings
3. Check console logs for `[BLE]` messages
4. Confirm custom UUIDs match Arduino sketch

---

## 📝 Decision Pending

**Choose iOS version to continue:**
- **Simplified:** Clean, minimal UI (290 lines)
- **Verbose:** Full maker culture philosophy, welcome screens, detailed settings (600+ lines)

Both versions are fully functional and ready for deployment.

---

## 🎯 Immediate Next Step

**Test macOS Siri Integration:**
1. Launch Demetor macOS app
2. Wait for Arduino connection
3. Say: "Hey Siri, Demetor temperature"
4. Verify Siri returns current reading

---

**Session saved:** October 8, 2025, 10:15 AM
**Ready to restore and continue WWDC 2025 testing**
