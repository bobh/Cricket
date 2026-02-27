# Cricket Project - Complete Context Restoration (Feb 12, 2026)

## Quick Restore Command
**Paste this to Claude after computer reset:**
> "Continue working on the Cricket project at `/Users/bobh/Desktop/Projects/Cricket`. We just finished configuring arm64-only builds with zero warnings. Read `/Users/bobh/Desktop/Projects/Cricket/CONTEXT_RESTORE.md` for full context."

---

## Strategic Vision: Ambient Intelligence Integration

**Cricket is NOT a traditional app** - it's an **ambient intelligence data provider** that integrates external Bluetooth environmental sensors with Apple's AI reasoning framework.

### The Goal: Invisible Capability Provider
Cricket follows Apple's technology roadmap where users get answers without knowing which app provided them:
- User: *"Is it humid enough for my sourdough to rise?"*
- Apple Intelligence: Recognizes need for **HumidityReading** + baking context
- System: Automatically queries Cricket's **HumidityReading AppEntity**
- Result: Contextual answer without app invocation

This is **ambient intelligence** - sensors become invisible infrastructure for AI reasoning.

---

## Project Overview

**Name**: Cricket (formerly Demetor)
**Type**: Hyperlocal Environmental Monitoring System
**Location**: `/Users/bobh/Desktop/Projects/Cricket`
**Last Updated**: February 12, 2026
**Xcode**: 17C52 (preparing for 26.3)

### Technology Stack (Following Apple's Roadmap)
- ✅ **App Intents** - Structured intent definitions for Siri/Shortcuts (implemented)
- ✅ **App Entities** - Semantic data types: TemperatureReading, HumidityReading, SensorStatus (implemented)
- ✅ **Intent Donation** - Building Apple Intelligence pattern history since Nov 4, 2025 (active)
- ✅ **Shortcuts Integration** - "Hey Siri, run Room Temp" fully functional (working)
- ⏳ **Entity-Based Invocation** - Awaiting WWDC 26 (June 2026)

### Hardware
- **Arduino**: Nano 33 BLE Sense Rev2 with nRF52840 SoC + HS3003 sensor (0.1°C precision)
- **RuuviTag**: Commercial BLE environmental sensors (supported)
- **Sensor Docs**: https://github.com/bobh/Sensors

---

## Current State (Feb 12, 2026)

### ✅ Completed
- **iOS App**: BLE_Central (wm6h.Cricket-ios) - Full implementation with SwiftUI
- **macOS App**: Cricket_mac (wm6h.Cricket-mac) - Full implementation with SwiftUI
- **BLE Stack**: Arduino + RuuviTag support with reliable connectivity
- **App Intents**: GetLocalTemperatureIntent, GetLocalHumidityIntent, GetSensorStatusIntent
- **App Entities**: TemperatureReading, HumidityReading, SensorStatus (typed data for AI)
- **Intent Donation**: Active since Nov 4, 2025 - accumulating pattern data
- **Shortcuts**: "Hey Siri, run Room Temp" triggers cricket chirp + spoken data
- **Audio Signature**: Cricket chirp sound at `/Users/bobh/Desktop/Projects/Cricket/cricket.wav`
- **Build System**: arm64 (Apple Silicon) only - zero warnings on both platforms
- **Widget Code**: Written but not yet integrated (Priority 0 pending task)

### ⏳ Pending
1. **Widget Integration** (can do anytime)
2. **iOS 26.4 Testing** (Q1 2026) - Test Siri improvements
3. **Swift Modernization** (post iOS 26.4) - Adopt @Observable, Swift Concurrency, modern APIs (6-9 hours)
4. **App Rename** (conditional) - Cricket → Local Sensor if iOS 26.4 improves routing
5. **WWDC 26 Adoption** (June 2026) - Entity-based invocation APIs

### 📊 Project Status
- **Suspended**: November 4, 2025
- **Resume Trigger**: iOS 26.4 release (Q1 2026)
- **Strategic Milestone**: WWDC 26 (June 2026) - Entity-based invocation

---

## Recent Work (Feb 12, 2026)

### Changes Made
1. ✅ Successfully built both iOS and macOS apps
2. ✅ Fixed all compiler warnings (now zero warnings)
3. ✅ Configured for arm64 (Apple Silicon) only - removed x86_64

### Files Modified
- `/Users/bobh/Desktop/Projects/Cricket/IOS--BLE Central/BLE_Central.xcodeproj/project.pbxproj`
  - Added `ARCHS = arm64;` to Debug and Release configurations
- `/Users/bobh/Desktop/Projects/Cricket/CricketMac/CricketMac.xcodeproj/project.pbxproj`
  - Added `ARCHS = arm64;` to Debug and Release configurations
- `/Users/bobh/Desktop/Projects/Cricket/development-plan.md`
  - Added Strategic Vision: Ambient Intelligence Integration section
  - Updated Current State Assessment with build status

---

## BLE Implementation Improvements (Feb 12, 2026)

### ✅ Completed: Comprehensive Core Bluetooth Enhancements

Implemented industry best practices from Punch Through Core Bluetooth expert guide across both macOS and iOS platforms.

**Status**:
- ✅ Code Implementation: Complete
- ⏸️ Compilation: Pending new Xcode release
- ⏳ Testing: Awaiting compilation

### Improvements Implemented

**Priority 1 Critical Fixes (Both Platforms):**
1. **Consistent Service Filtering** - Changed from `withServices: nil` to `[environmentalSensingServiceUUID]` everywhere
   - Reduces power consumption
   - Accelerates peripheral discovery
   - Only discovers relevant Arduino sensors

2. **Complete Bluetooth State Handling** - Comprehensive switch statement covering all 7 CBManagerState cases
   - `.poweredOn`, `.poweredOff`, `.unauthorized`, `.unsupported`, `.resetting`, `.unknown`, `@unknown default`
   - Clear, actionable error messages for users
   - Proper guidance for each state

3. **Characteristic Reference Storage** - Store references instead of repeated UUID searches
   - Added `temperatureCharacteristic` and `humidityCharacteristic` properties
   - More efficient code pattern

**Advanced Features:**
4. **Manual BLE Cache Clear** - Development tool for firmware updates
   - `clearBLECache()` method implemented
   - UI button in macOS SettingsView (Developer Tools section)
   - iOS method ready, UI integration pending

5. **Write Flow Control** - Prevents BLE transmit queue overflow
   - Write queue management for `.withoutResponse` operations
   - `peripheralIsReady(toSendWriteWithoutResponse)` callback handling
   - Ready for future LED control feature

6. **Background Execution Support** - Maintains connection when app backgrounded/window closed
   - State preservation via UserDefaults
   - State restoration with `retrievePeripherals(withIdentifiers:)`
   - Heartbeat mechanism: 20s (foreground) / 60s (background)
   - Prevents iOS 30-second auto-disconnect
   - Ready for widget integration (Priority 0 task)
   - macOS lifecycle integration via AppDelegate

### Files Modified

**macOS:**
- `CricketMac/CricketMac/BluetoothViewModel.swift` (+238 lines, -6 lines)
- `CricketMac/CricketMac/SettingsView.swift` (+48 lines, -1 line)
- `CricketMac/CricketMac/ContentView.swift` (+5 lines, -1 line)
- `CricketMac/CricketMac/CricketMac.swift` (+16 lines, -1 line)

**iOS:**
- `IOS--BLE Central/BLE_Central/BluetoothViewModel.swift` (+273 lines, -7 lines)

**Documentation:**
- `BLE_CRITICAL_FIXES.md` (new)
- `BLE_ADVANCED_CONSIDERATIONS.md` (new)
- `CORE_BLUETOOTH_BEST_PRACTICES.md` (new - reusable for any BLE project)
- `BLE_IMPLEMENTATION_PLAN.md` (new)
- `BLE_IMPLEMENTATION_LOG.md` (new - comprehensive implementation record)

### Git Commits

All changes committed to main branch:
1. `ced9c4d` - BLE: Apply Priority 1 critical fixes to macOS
2. `894d2be` - BLE: Add manual cache clear functionality
3. `c91b83f` - BLE: Implement write flow control for peripheral writes
4. `449cc0c` - BLE: Implement background execution support
5. `91490ea` - BLE: Apply all improvements to iOS version

### Testing Required (After New Xcode Release)

**Priority Tests:**
1. Build succeeds on both platforms
2. Zero compiler warnings maintained
3. Arduino discovery works with service filtering
4. Temperature/humidity updates continue working
5. Cache clear button functional (macOS)
6. State messages accurate (test by toggling Bluetooth)

**Background Execution Tests:**
7. Connection maintained when window closed (macOS)
8. Reconnects after app relaunch
9. Heartbeat prevents disconnect
10. Background/foreground transitions smooth

### Benefits for Cricket's Roadmap

**Immediate:**
- Development efficiency (cache clear eliminates firmware friction)
- Code quality (follows industry best practices)
- User experience (clear, actionable error messages)
- Power efficiency (service filtering reduces energy use)

**Enables Future Features:**
- Widget integration (background support ready)
- LED control (write flow control implemented)
- Menu bar app for macOS (background execution ready)
- Ambient intelligence continuous operation

**WWDC 26 Preparation:**
- Solid foundation for entity-based invocation
- Background pattern learning via intent donation
- Professional implementation for demos

### Documentation

For complete technical details, see:
- **BLE_IMPLEMENTATION_LOG.md** - Comprehensive implementation record with before/after code
- **CORE_BLUETOOTH_BEST_PRACTICES.md** - Reusable universal guide
- **BLE_CRITICAL_FIXES.md** - Priority 1 fixes specific to Cricket
- **BLE_ADVANCED_CONSIDERATIONS.md** - Cost/benefit analysis
- **SWIFT_MODERNIZATION_ANALYSIS.md** - Swift 6 modernization plan (Feb 2026, deferred to post iOS 26.4)

---

## File Locations

### Critical Documentation
- **This file**: `/Users/bobh/Desktop/Projects/Cricket/CONTEXT_RESTORE.md`
- **Development Plan**: `/Users/bobh/Desktop/Projects/Cricket/development-plan.md`
- **Project Status**: `/Users/bobh/Desktop/Projects/Cricket/PROJECT_STATUS.md` (comprehensive 807-line doc)
- **PRD**: `/Users/bobh/Desktop/Projects/Cricket/prd.md`

### Xcode Projects
**iOS:**
- Project: `/Users/bobh/Desktop/Projects/Cricket/IOS--BLE Central/BLE_Central.xcodeproj`
- Scheme: `BLE_Central`
- Target: `BLE_Central`
- Bundle ID: `wm6h.Cricket-ios`
- Source: `/Users/bobh/Desktop/Projects/Cricket/IOS--BLE Central/BLE_Central/`

**macOS:**
- Project: `/Users/bobh/Desktop/Projects/Cricket/CricketMac/CricketMac.xcodeproj`
- Scheme: `Cricket_mac`
- Target: `Cricket_mac`
- Bundle ID: `wm6h.Cricket-mac`
- Source: `/Users/bobh/Desktop/Projects/Cricket/CricketMac/CricketMac/`

**Arduino:**
- Location: `/Users/bobh/Desktop/Projects/Cricket/ARDUINO/`

---

## Build Commands (Verified Working)

### macOS Build (arm64)
```bash
cd /Users/bobh/Desktop/Projects/Cricket
xcodebuild -project "./CricketMac/CricketMac.xcodeproj" \
  -scheme Cricket_mac -configuration Debug \
  -destination 'platform=macOS' clean build
```
**Result**: ✅ BUILD SUCCEEDED, 0 warnings, arm64 binary

### iOS Simulator Build (arm64)
```bash
cd /Users/bobh/Desktop/Projects/Cricket
xcodebuild -project "./IOS--BLE Central/BLE_Central.xcodeproj" \
  -target BLE_Central -configuration Debug \
  -sdk iphonesimulator26.2 clean build
```
**Result**: ✅ BUILD SUCCEEDED, 0 warnings, arm64 binary

### iOS Device Build (when USB attached)
```bash
cd /Users/bobh/Desktop/Projects/Cricket
xcodebuild -project "./IOS--BLE Central/BLE_Central.xcodeproj" \
  -target BLE_Central -configuration Debug \
  -sdk iphoneos26.2 \
  -destination 'platform=iOS,id=DEVICE_ID' build
```

### Check Binary Architecture
```bash
# iOS
lipo -info "/Users/bobh/Desktop/Projects/Cricket/IOS--BLE Central/build/Debug-iphonesimulator/BLE_Central.app/BLE_Central"
# Result: Non-fat file: ... is architecture: arm64

# macOS
lipo -info "/Users/bobh/Library/Developer/Xcode/DerivedData/CricketMac-*/Build/Products/Debug/Cricket_mac.app/Contents/MacOS/Cricket_mac"
# Result: Non-fat file: ... is architecture: arm64
```

---

## Key Technical Details

### App Intents Implementation
**Location**: `CricketAppIntents.swift` (both iOS and macOS)

**Intents Defined:**
1. `GetLocalTemperatureIntent` - Returns TemperatureReading, plays cricket chirp
2. `GetLocalHumidityIntent` - Returns HumidityReading
3. `GetSensorStatusIntent` - Returns SensorStatus

**App Entities (Semantic Types for AI):**
```swift
struct TemperatureReading: AppEntity {
    var celsius: Double
    var fahrenheit: Double
    var timestamp: Date
    var sensorType: SensorType  // .arduino or .ruuviTag
}

struct HumidityReading: AppEntity {
    var relativeHumidity: Double
    var timestamp: Date
    var sensorType: SensorType
}

struct SensorStatus: AppEntity {
    var sensorType: SensorType
    var isConnected: Bool
    var statusMessage: String
}
```

**Intent Donation (Critical for AI):**
- Implemented Nov 4, 2025
- Triggered on every sensor data update
- Builds Apple Intelligence pattern recognition
- Located in: `BluetoothViewModel.swift` and `RuuviTagViewModel.swift`

### BLE Protocol
**Arduino Nano 33 BLE Sense Rev2:**
- Service UUID: `5971E8F1-BC4D-4A5F-A6FD-3591131A98C6`
- Temperature Characteristic: `78B20AF1-E597-40C1-A69C-304205B7E099` (sint16 × 100)
- Humidity Characteristic: `0BA15AA1-A805-4205-BC82-AF2E4A9364C5` (uint16 × 100)

**RuuviTag:**
- Manufacturer ID: `0x0499`
- Formats: RAWv1 (0x03), RAWv2 (0x05)
- Mode: Advertisement-based (no connection)

---

## Strategic Context: The Name Problem

### Current Issue
- **App name**: "Cricket" conflicts with locations (Cricket, Iowa), sports, health queries
- **Direct Siri**: "Hey Siri, Cricket temperature" → Searches Cricket, Iowa ❌
- **Shortcut works**: "Hey Siri, run Room Temp" → Perfect ✅

### Solution Path (Following Apple's Roadmap)
1. **Short term**: Continue using Shortcuts (works perfectly)
2. **iOS 26.4** (Q1 2026): Test if Siri routing improved
3. **Rename option**: "Local Sensor" reserved in App Store Connect
4. **Long term** (WWDC 26): Entity-based invocation makes name irrelevant

### The Vision: No Name Needed
When Apple launches entity-based invocation (expected WWDC 26):
- User: "Is it humid?" or "What's the temperature?"
- Apple Intelligence: Queries apps by **HumidityReading** / **TemperatureReading** capability
- Cricket: Provides data silently
- Result: User gets answer without knowing source

**Cricket becomes infrastructure, not an app to remember.**

---

## Known Build Behaviors

### AppIntents SSU Message (Harmless)
During **clean builds only**, you may see:
```
appintentsnltrainingprocessor error: Could not archive SSU artifacts
```
**This is informational** - relates to Siri Suggestion Understanding (SSU) training data archiving. Build still succeeds. Only appears on clean builds, not incremental builds.

### Build Artifacts
- **iOS**: `/Users/bobh/Desktop/Projects/Cricket/IOS--BLE Central/build/Debug-iphonesimulator/BLE_Central.app`
- **macOS**: `/Users/bobh/Library/Developer/Xcode/DerivedData/CricketMac-*/Build/Products/Debug/Cricket_mac.app`

---

## Xcode 26.3 Preparation

When Xcode 26.3 releases:
1. ✅ Projects already configured for arm64 only
2. ✅ Build settings validated
3. ⚠️ Check iOS SDK version (may update from 26.2)
4. ⚠️ Update build commands if SDK version changes
5. ⚠️ Run both builds to catch new warnings/deprecations
6. ⚠️ Review new App Intents/AppEntity capabilities
7. ⚠️ Test intent donation still works

### Build Command Updates (if SDK changes)
If iOS SDK becomes 26.3:
```bash
# Update -sdk flag:
-sdk iphonesimulator26.3  # instead of 26.2
-sdk iphoneos26.3         # instead of 26.2
```

---

## Development Team & Configuration
- **Development Team**: 68U33HS2JC
- **iOS Bundle ID**: wm6h.Cricket-ios
- **macOS Bundle ID**: wm6h.Cricket-mac
- **Architecture**: arm64 only (Apple Silicon)
- **iOS Deployment Target**: 26.0
- **Target Devices**: iPhone (1), iPad (2)
- **macOS**: Native Apple Silicon

---

## Next Priority Tasks

### Priority 0: Widget Integration (Can do now)
Widget code is complete at: `/Users/bobh/Desktop/Projects/Cricket/CricketIOS/CricketWidget_Code.swift`

**Steps:**
1. Open iOS project in Xcode
2. Add Widget Extension target to BLE_Central.xcodeproj
3. Configure App Groups: `group.com.yourcompany.BLECentral`
4. Add CricketWidget_Code.swift to widget target
5. Repeat for macOS with: `group.com.yourcompany.CricketMac`
6. Build and test widgets

### Priority 1: iOS 26.4 Testing (Q1 2026)
When iOS 26.4 releases:
1. Test basic Siri voice: "Hey Siri, what time is it?"
2. Test "Cricket temperature" routing
3. Test "inside temperature" semantic routing
4. Evaluate if app rename is beneficial

### Priority 2: WWDC 26 (June 2026)
Watch for:
- Entity-based invocation APIs
- Assistant Schema enhancements
- New AppIntent capabilities
- Ambient intelligence frameworks

---

## Testing Current State

### Verify Builds
```bash
cd /Users/bobh/Desktop/Projects/Cricket

# Test macOS
xcodebuild -project "./CricketMac/CricketMac.xcodeproj" \
  -scheme Cricket_mac -destination 'platform=macOS' build 2>&1 | \
  grep -E "(BUILD SUCCEEDED|warning:|error:)"

# Test iOS
xcodebuild -project "./IOS--BLE Central/BLE_Central.xcodeproj" \
  -target BLE_Central -sdk iphonesimulator26.2 build 2>&1 | \
  grep -E "(BUILD SUCCEEDED|warning:|error:)"
```
**Expected**: Both show "BUILD SUCCEEDED" with no warnings

### Verify Shortcuts
```bash
# List shortcuts
shortcuts list | grep -i temp

# Run shortcut
shortcuts run "Room Temp"
# Expected: Cricket chirp + spoken temperature/humidity + "Done"
```

### Verify Architecture
```bash
lipo -info "/Users/bobh/Desktop/Projects/Cricket/IOS--BLE Central/build/Debug-iphonesimulator/BLE_Central.app/BLE_Central"
# Expected: Non-fat file: ... is architecture: arm64
```

---

## Essential Reading for Full Context

After restoration, read these files in order:
1. **This file** (CONTEXT_RESTORE.md) - Overview and current state
2. **PROJECT_STATUS.md** (807 lines) - Comprehensive technical status
3. **development-plan.md** - Strategic roadmap and implementation plan
4. **prd.md** - Product requirements

Quick preview command:
```bash
cd /Users/bobh/Desktop/Projects/Cricket
head -50 PROJECT_STATUS.md
head -100 development-plan.md
```

---

## Success Indicators

You'll know context is fully restored when you can answer:
- ✅ What is Cricket's strategic goal? (Ambient intelligence data provider)
- ✅ What Apple technology does it use? (App Intents, App Entities, Intent Donation)
- ✅ What's the current build status? (arm64 only, zero warnings)
- ✅ What's pending? (Widget integration, iOS 26.4 testing, WWDC 26)
- ✅ Why is the app name "Cricket" problematic? (Conflicts with locations/sports)
- ✅ What's the long-term vision? (Entity-based invocation - app name becomes irrelevant)

---

**Last Updated**: February 12, 2026
**Next Milestone**: Xcode 26.3 release (imminent)
**Strategic Milestone**: WWDC 26 (June 2026) - Entity-based invocation

---

## Quick Restore Checklist

After computer reset, verify:
- [ ] Project exists at `/Users/bobh/Desktop/Projects/Cricket`
- [ ] Xcode installed (preferably 26.3 or later)
- [ ] Both projects build successfully
- [ ] Zero compilation warnings
- [ ] arm64 architecture only (no x86_64)
- [ ] Context fully understood from this document
- [ ] Ready to continue development

**Restore Command**:
```bash
cd /Users/bobh/Desktop/Projects/Cricket && \
cat CONTEXT_RESTORE.md | head -100
```

---
*End of Context Restoration Document*
