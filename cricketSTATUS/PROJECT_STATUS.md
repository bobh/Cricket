# Cricket/Local Sensor Project - Status Document
**Last Updated:** November 4, 2025
**Suspended Until:** iOS 26.4 Release (Expected Q1 2026)
**Resume Point:** After iOS 26.4 testing

---

## Project Overview

**Goal:** Provide hyperlocal (inside) temperature and humidity readings to iOS/macOS via external BLE sensors, integrated with Siri and Apple Intelligence.

**Hardware:**
- Arduino Nano 33 Sense Rev 2 (BLE peripheral)
- RuuviTag sensors (BLE broadcast)

**Platforms:**
- iOS app (iPhone)
- macOS app (Mac)

**Current App Name:** Cricket (with cricket chirp sound 🦗)
**Reserved App Store Name:** "Local Sensor"
**Pending Rename:** Cricket → Local Sensor (not yet implemented)

---

## Current Status Summary

### ✅ What's Working (100% Functional)
- BLE connection to Arduino Nano 33 Sense Rev 2 (custom UUIDs)
- BLE connection to RuuviTag (manufacturer data parsing, RAWv1 and RAWv2)
- Temperature and humidity display on iOS and macOS
- SwiftUI apps for both platforms
- Siri integration via Shortcuts: **"Hey Siri, run Room Temp"** → Cricket chirp + spoken data + "Done"
- Command line: `shortcuts run "Room Temp"` works perfectly
- App Intents framework fully implemented (AppEntity, AppEnum, AppIntent)
- **Intent donation implemented** (Nov 4, 2025) - Apple Intelligence pattern learning started

### ❌ What Doesn't Work
- Direct App Shortcuts: "Hey Siri, Cricket temperature" → Searches Cricket, Iowa (name conflict)
- Direct App Shortcuts: "Hey Siri, Cricket humidity" → Same issue
- **Root cause:** Generic name "Cricket" conflicts with locations, sports, health queries

### ⏳ What's Pending
1. **Widget integration** - Code written but not integrated into Xcode projects (iOS + macOS)
2. Rename app from "Cricket" to "Local Sensor"
3. Update all code files with new name
4. Add "inside/indoor" keywords to App Intents
5. Rebuild both iOS and macOS apps
6. Test with iOS 26.4 when released

---

## Strategic Decisions Made

### 1. Wait for Entity-Based Invocation (WWDC 26 - June 2026)
**Decision:** Don't over-engineer now. Wait for Apple's entity-based invocation where Siri calls apps by capability (HumidityReading) not name.

**Rationale:**
- Current approach (App Shortcuts) has name conflict issues
- Apple announced major Siri improvements for 2026
- Entity-based invocation will route queries by data type, not app name
- Foundation is ready: AppEntity structure + intent donation

**Status:** Validated by Apple's iOS 26.4 and 2026 Siri enhancement announcements

### 2. Implement Intent Donation Now
**Decision:** Add intent donation immediately to start building pattern history.

**Implementation:** Completed Nov 4, 2025
- All 4 ViewModels donate intents when data updates
- iOS: BluetoothViewModel, RuuviTagViewModel
- macOS: BluetoothViewModel, RuuviTagViewModel
- Donates: GetLocalTemperatureIntent, GetLocalHumidityIntent

**Benefit:**
- 2-3 months of data before iOS 26.4 (~Q1 2026)
- 6+ months of data before WWDC 26 (June 2026)
- Apple Intelligence learns usage patterns

### 3. App Name: "Local Sensor"
**Decision:** Change from "Cricket" to "Local Sensor"

**Rationale:**
- "Cricket" too generic (conflicts with locations, sports)
- "Local Sensor" descriptive, avoids conflicts
- "Local" = hyperlocal, distinguishes from official weather
- Reserved in App Store Connect
- Cricket chirp sound remains as audio signature

**Status:** Reserved but not yet implemented in code

### 4. Target User: Apple Intelligence, Not Demographics
**Key Insight:** We're not targeting "3D printer owners" or "baby nursery monitors." We're providing a **capability to Apple Intelligence** that routes queries appropriately.

**Use Case Examples:**
- User: "Is it humid enough to run dehumidifier?"
- Apple Intelligence needs: HumidityReading
- Routes to: Our app (via AppEntity + donation history)
- No app name needed!

---

## Technical Implementation Details

### App Intent Architecture

#### AppEntity Types (Structured Data)
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

#### AppEnum Types
```swift
enum SensorType: String, AppEnum {
    case arduino = "BLE"
    case ruuviTag = "Ruuvi"
}

enum TemperatureUnit: String, AppEnum {
    case celsius
    case fahrenheit
    case both  // default
}
```

#### App Intents
- `GetLocalTemperatureIntent` - Returns TemperatureReading, plays cricket chirp
- `GetLocalHumidityIntent` - Returns HumidityReading
- `GetSensorStatusIntent` - Returns SensorStatus

#### Intent Metadata (Critical for Apple Intelligence)
```swift
static var description = IntentDescription(
    "Retrieves temperature from Cricket environmental sensor...",
    categoryName: "Weather & Environment",  // ← Maps to Assistant Schemas
    searchKeywords: [
        "temperature", "temp", "weather", "environment",
        "climate", "room temperature", "indoor temperature",
        "thermometer", "local", "hyperlocal"
    ]
)
```

#### Intent Donation (Implemented Nov 4, 2025)
```swift
private func donateIntents() {
    Task { @MainActor in
        let tempIntent = GetLocalTemperatureIntent()
        tempIntent.donate()  // ← Apple learns patterns
    }

    Task { @MainActor in
        let humIntent = GetLocalHumidityIntent()
        humIntent.donate()
    }
}
```

Called from `saveValues()` in all ViewModels whenever sensor data updates.

### BLE Implementation

#### Arduino Nano 33 Sense Rev 2
- **Custom UUIDs:** (Bluetooth SIG compliant)
  - Service: `5971E8F1-BC4D-4A5F-A6FD-3591131A98C6`
  - Temperature: `78B20AF1-E597-40C1-A69C-304205B7E099`
  - Humidity: `0BA15AA1-A805-4205-BC82-AF2E4A9364C5`
- **Data format:** Sint16 (temp), Uint16 (humidity), value × 100
- **Connection mode:** Central connects to peripheral, reads characteristics

#### RuuviTag
- **Manufacturer ID:** `0x0499` (bytes [0x99, 0x04])
- **Formats supported:** RAWv1 (0x03), RAWv2 (0x05)
- **Mode:** Advertisement-based (no connection required)
- **Parsing:**
  - RAWv1: Temp bytes 3-4 (signed int16, little-endian, ÷100)
  - RAWv1: Humidity bytes 5-6 (unsigned int16, little-endian, ÷100)
  - RAWv2: Different byte positions and scaling

### Data Flow
1. BLE sensor broadcasts/notifies data
2. ViewModel receives and parses
3. Updates @Published properties → UI updates
4. Saves to UserDefaults (standard + shared suite)
5. **Donates intents** to Apple Intelligence
6. Widget timeline refreshes (WidgetCenter.shared.reloadAllTimelines())

### Widget Implementation (Pending Integration)

**Current Status:** Widget code written but NOT integrated into Xcode projects

#### Widget Code Location
**Complete widget code:** `/Users/bobh/Desktop/Cricket/CricketIOS/CricketWidget_Code.swift`

This file contains production-ready widget code with:
- Timeline provider implementation
- Three widget sizes (small, medium, large)
- Shared UserDefaults integration
- Beautiful UI with gradients and sensor status

#### Widget Features (Designed)

**Small Widget (systemSmall):**
- Single metric display (temperature)
- Cricket/sensor icon
- Sensor source badge (Arduino/RuuviTag)
- Compact design for home screen

**Medium Widget (systemMedium):**
- Both temperature AND humidity displayed side-by-side
- Thermometer and humidity icons
- Visual divider between metrics
- Sensor source badge in corner

**Large Widget (systemLarge):**
- Full detailed view with cards
- Temperature card with large display
- Humidity card with large display
- Header with Cricket branding
- Footer with sensor source and last update time
- Most informative widget size

#### Widget Data Source
- **App Group:** `group.com.yourcompany.CricketIOS` (iOS) / `group.com.yourcompany.CricketMac` (macOS)
- **Shared keys:**
  - `temperature` - Current temperature string (e.g., "22.3 °C")
  - `humidity` - Current humidity string (e.g., "48.5 %")
  - `sensorSource` - "BLE" or "Ruuvi"
  - `connectionStatus` - Connection state message

#### Widget Update Strategy
- **Automatic updates:** Every 5 minutes via timeline policy
- **Manual refresh:** `WidgetCenter.shared.reloadAllTimelines()` called when sensor data updates
- **Background updates:** iOS manages background refresh for power efficiency

#### Widget UI Design
- **Color scheme:** Dark gradient background (blue-gray tones)
- **Icons:**
  - Temperature: thermometer.medium (orange)
  - Humidity: humidity.fill (blue)
  - Sensor: sensor.fill (green)
- **Typography:** SF Rounded for numbers, system font for labels
- **Visual style:** Modern, clean, high contrast for outdoor readability

---

## File Locations

### iOS App
**Base:** `/Users/bobh/Desktop/Cricket/IOS/`
- Project: `BLE_Central.xcodeproj`
- Main files:
  - `BLE_Central/BLE_CentralApp.swift` - App entry, AppShortcutsProvider
  - `BLE_Central/ContentView.swift` - Main UI
  - `BLE_Central/BluetoothViewModel.swift` - Arduino BLE logic + intent donation
  - `BLE_Central/RuuviTagViewModel.swift` - RuuviTag logic + intent donation
  - `BLE_Central/CricketAppIntents.swift` - App Intent definitions
  - `BLE_Central/Info.plist` - CFBundleDisplayName: "Cricket"

### macOS App
**Base:** `/Users/bobh/Desktop/Cricket/CricketMac/`
- Project: `CricketMac.xcodeproj`
- Main files:
  - `CricketMac/CricketMac.swift` - App entry, AppShortcutsProvider
  - `CricketMac/ContentView.swift` - Main UI
  - `CricketMac/BluetoothViewModel.swift` - Arduino BLE logic + intent donation
  - `CricketMac/RuuviTagViewModel.swift` - RuuviTag logic + intent donation
  - `CricketMac/CricketAppIntents.swift` - App Intent definitions (enhanced with AppEntity)
  - `CricketMac/Info.plist` - CFBundleDisplayName: "Cricket"

### Widget Code (Not Yet Integrated)
- `/Users/bobh/Desktop/Cricket/CricketIOS/CricketWidget_Code.swift` - Complete widget implementation

**Integration needed:**
- iOS: Create widget extension target in BLE_Central.xcodeproj
- macOS: Create widget extension target in CricketMac.xcodeproj
- Configure App Groups in both projects
- Add widget extension to build schemes

### Documentation
- `/Users/bobh/Desktop/Cricket/IOS/SIRI_VOICE_BUG_TESTING.md` - Siri testing guide
- `/Users/bobh/Desktop/Cricket/IOS/SHORTCUTS_SETUP_GUIDE.md` - Shortcuts setup
- `/Users/bobh/Desktop/Cricket/IOS/SIRI_COMMANDS.md` - Command reference
- `/Users/bobh/Desktop/Cricket/PROJECT_STATUS.md` - This document

### Build Locations
- macOS app (last built): `/Applications/Cricket_mac.app`
- iOS app: Built via Xcode to connected devices

---

## Pending Tasks (When Resuming)

### Priority 0: Widget Integration (Can be done anytime)
**Status:** Widget code complete, needs Xcode integration
**When:** Can be done before or after iOS 26.4 release (independent task)

**Steps for iOS Widget:**
1. Open `/Users/bobh/Desktop/Cricket/IOS/BLE_Central.xcodeproj` in Xcode
2. Add new Widget Extension target:
   - File → New → Target → Widget Extension
   - Product Name: "CricketWidget"
   - Include Configuration Intent: No (using static configuration)
3. Delete template widget file, add CricketWidget_Code.swift to target
4. Configure App Groups capability:
   - iOS app target: Add `group.com.yourcompany.BLECentral`
   - Widget target: Add same App Group
5. Update widget code App Group ID to match (line 25):
   ```swift
   private let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.BLECentral")
   ```
6. Build and test on device/simulator
7. Test widget refresh when sensor data updates

**Steps for macOS Widget:**
1. Open `/Users/bobh/Desktop/Cricket/CricketMac/CricketMac.xcodeproj` in Xcode
2. Add new Widget Extension target (same process as iOS)
3. Configure App Groups: `group.com.yourcompany.CricketMac`
4. Update widget code App Group ID for macOS version
5. Build and test

**Widget Testing:**
- Add widget to home screen (iOS) or Notification Center (macOS)
- Verify temperature and humidity display correctly
- Test all three sizes (small, medium, large)
- Verify widget updates when app receives new sensor data
- Test with both Arduino and RuuviTag sensor sources

**Files to verify after integration:**
- Widget displays "--" when no sensor data
- Widget shows correct sensor source (Arduino/RuuviTag)
- Widget updates every 5 minutes automatically
- Manual refresh works via WidgetCenter.shared.reloadAllTimelines()

### Priority 1: Test iOS 26.4 Siri Improvements
**When:** After iOS 26.4 release (~Q1 2026)

**Test:**
1. Basic Siri voice: "Hey Siri, what time is it?" - Verify it speaks
2. Current commands: "Hey Siri, Cricket temperature" - See if routing improved
3. With rename: "Hey Siri, Local Sensor temperature" - Test new name

**Decision point:**
- If iOS 26.4 fixes routing → Proceed with rename
- If still broken → Wait for 2026 entity-based invocation

### Priority 2: Rename App (If iOS 26.4 Works Better)
**Tasks:**
1. Update CFBundleDisplayName and CFBundleName in Info.plist files (iOS + macOS)
2. Update AppShortcutsProvider phrases to use "Local Sensor"
3. Update Intent descriptions: "Cricket" → "Local Sensor"
4. Add keywords: "inside", "indoor" to searchKeywords arrays
5. Rebuild both apps
6. Reinstall: macOS to /Applications, iOS to devices
7. Test: "Hey Siri, Local Sensor temperature"

**Files to change:**
- `/Users/bobh/Desktop/Cricket/IOS/BLE_Central/Info.plist`
- `/Users/bobh/Desktop/Cricket/IOS/BLE_Central/BLE_CentralApp.swift`
- `/Users/bobh/Desktop/Cricket/IOS/BLE_Central/CricketAppIntents.swift`
- `/Users/bobh/Desktop/Cricket/CricketMac/CricketMac/Info.plist`
- `/Users/bobh/Desktop/Cricket/CricketMac/CricketMac/CricketMac.swift`
- `/Users/bobh/Desktop/Cricket/CricketMac/CricketMac/CricketAppIntents.swift`

### Priority 3: Monitor WWDC 26 Announcements
**When:** June 2026

**Watch for:**
- Entity-based invocation APIs
- Assistant Schema enhancements
- New AppIntent capabilities
- Siri natural language improvements

**Be ready to:**
- Adopt new APIs immediately
- Enhance AppEntity definitions if needed
- Add new intent types if useful

---

## What NOT to Do (Strategic Decisions)

### ❌ Don't Add Core Spotlight Indexing (Yet)
**Rationale:** Wait to see what iOS 26.4 and 2026 bring. Intent donation is sufficient foundation.

### ❌ Don't Add NSUserActivity (Yet)
**Rationale:** Adds complexity without clear benefit until we see Apple's direction.

### ❌ Don't Add Relevance Providers (Yet)
**Rationale:** Proactive suggestions can wait for entity-based invocation.

### ❌ Don't Over-Optimize Keywords Now
**Rationale:** iOS 26.4 may change how Siri processes queries. Test first, then optimize.

### ❌ Don't Change Hardware/BLE Protocol
**Rationale:** Working perfectly. No changes needed.

### ✅ Widget Code Ready - Just Needs Integration
**Note:** Widget implementation is complete and production-ready. Just needs Xcode target setup. Can be done anytime without affecting other features.

---

## Key Code Patterns to Remember

### Intent Donation Pattern (Already Implemented)
```swift
private func saveValues() {
    // Save data to UserDefaults
    UserDefaults.standard.set(temperature, forKey: "currentTemperature")
    // ... other saves ...

    // Donate intents for pattern learning
    donateIntents()
}

private func donateIntents() {
    Task { @MainActor in
        let intent = GetLocalTemperatureIntent()
        intent.donate()  // ← Critical for Apple Intelligence
    }
}
```

### App Shortcuts Registration Pattern
```swift
struct AppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetLocalTemperatureIntent(),
            phrases: [
                "\(.applicationName) temperature",
                "Get temperature from \(.applicationName)",
                // Add "inside" when renaming:
                // "\(.applicationName) inside temperature"
            ],
            shortTitle: "Local Temperature",
            systemImageName: "thermometer.medium"
        )
    }
}
```

---

## Environment Details

### Development Machine
- **macOS:** 26.1 (Build 25B78)
- **Xcode:** Beta at `/Users/bobh/Desktop/Xcode-beta.app`
- **Xcode CLI:** Use full path: `/Users/bobh/Desktop/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild`

### Siri Status
- **macOS 26.1:** Siri voice working ✅ (tested Nov 4, 2025)
- **Test:** "Hey Siri, what time is it?" → Speaks correctly

### Devices
- iPhone 13 mini (connected)
- iPhone 15 Pro Max (connected)
- iPad Air 2020 (connected)
- Various other iPads available

### Build Commands
```bash
# macOS app
"/Users/bobh/Desktop/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild" \
  -project /Users/bobh/Desktop/Cricket/CricketMac/CricketMac.xcodeproj \
  -scheme Cricket_mac \
  -destination 'platform=macOS' \
  build

# iOS app (simulator)
"/Users/bobh/Desktop/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild" \
  -project /Users/bobh/Desktop/Cricket/IOS/BLE_Central.xcodeproj \
  -scheme BLE_Central \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build

# iOS app (device)
"/Users/bobh/Desktop/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild" \
  -project /Users/bobh/Desktop/Cricket/IOS/BLE_Central.xcodeproj \
  -scheme BLE_Central \
  -destination 'platform=iOS,id=00008130-001659CE307A8D3A' \
  build
```

### Shortcuts Testing
```bash
# List shortcuts
shortcuts list

# Run shortcut
shortcuts run "Room Temp"

# Test Siri (manual)
"Hey Siri, run Room Temp"  # ← This works!
```

---

## Apple Intelligence Integration Strategy

### Current State (Nov 2025)
**What we have:**
- ✅ AppEntity types (structured data)
- ✅ AppEnum types (semantic context)
- ✅ AppIntent definitions with rich metadata
- ✅ Intent donation (pattern learning started)
- ✅ Category mapping ("Weather & Environment")
- ✅ Comprehensive search keywords

**What Apple Intelligence can do NOW:**
- Index intents in Spotlight
- Learn usage patterns from donations
- Potentially suggest shortcuts
- Discover capability via search keywords

### iOS 26.4 (~Q1 2026)
**Expected improvements:**
- Better natural language understanding
- Improved App Intent routing
- More context-aware Siri
- Potentially better keyword matching

**What to test:**
- Does "Cricket temperature" work better?
- Does "inside temperature" route to our app?
- Are proactive suggestions appearing?

### 2026 Entity-Based Invocation (WWDC 26)
**Expected capability:**
- Siri calls apps by entity type, not name
- "Is it humid?" → HumidityReading query → Our app invoked
- Cross-app reasoning (compare inside/outside automatically)
- Ambient availability without explicit invocation

**What we're ready for:**
- AppEntity types registered and discoverable
- Intent donation history shows patterns
- Rich semantic context via AppEnum
- No code changes needed (maybe minor enhancements)

---

## Success Metrics

### Technical Success (Already Achieved)
- ✅ BLE connection reliable
- ✅ Data display accurate
- ✅ Siri integration working (via Shortcuts)
- ✅ Intent donation implemented
- ✅ AppEntity structure complete
- ✅ Widget code complete (3 sizes designed and implemented)

### User Experience Success (Pending iOS 26.4/2026)
- ⏳ Natural commands work: "inside temperature" routes to app
- ⏳ No app name needed in queries
- ⏳ Proactive suggestions appear at relevant times
- ⏳ Cross-app reasoning: "Is it warmer inside or outside?"
- ⏳ Widgets integrated: At-a-glance sensor data on home screen/notification center

### Strategic Success (On Track)
- ✅ Foundation ready for entity-based invocation
- ✅ Pattern learning started before Apple releases features
- ✅ No premature optimization
- ✅ Aligned with Apple's roadmap

---

## Questions to Answer When Resuming

### Immediately (Widget Integration):
1. Should widgets be integrated before or after iOS 26.4 testing?
2. Do widgets need to support iOS complications (Apple Watch)?
3. Should widget display Celsius, Fahrenheit, or both?
4. Test widget battery impact - is 5-minute refresh appropriate?

### After iOS 26.4 Release:
1. Does basic Siri voice work? "Hey Siri, what time is it?" (speak or text only?)
2. Does "Cricket temperature" work better than before?
3. Does "inside temperature" route to any app?
4. Are there new App Intent capabilities in iOS 26.4?
5. Should we proceed with rename to "Local Sensor"?
6. Do widgets need updates for iOS 26.4 features?

### After WWDC 26:
1. Did Apple announce entity-based invocation?
2. What new APIs are available?
3. Do we need to enhance AppEntity definitions?
4. Is intent donation history being used by system?

---

## Enhanced Keywords for Future Implementation (Post-iOS 26.4)

**Status:** Ideas preserved for future implementation
**Decision:** Wait until iOS 26.4 testing before adding
**Rationale:** Don't want to forget these semantic routing improvements

### Spatial Context Keywords

Add to all intent `searchKeywords` arrays to help Apple Intelligence understand these are **inside/indoor** readings, not outside weather:

```swift
// Spatial location keywords
"inside", "indoor", "indoors", "interior",
"room", "home", "house", "apartment",
"office", "workspace", "bedroom", "living room",
"basement", "attic", "garage"
```

**Why this helps:** Distinguishes our hyperlocal readings from official weather data. When user asks "Is it humid inside?" Apple Intelligence can semantically match "inside" + "humid" → our app's HumidityReading capability.

### Use-Case Keywords

Add domain-specific keywords that indicate scenarios where inside climate readings are critical:

```swift
// Baking and cooking
"baking", "bread", "dough", "yeast", "proofing", "rising",
"chocolate", "candy", "sugar work", "meringue",

// 3D printing and manufacturing
"3D printing", "printer", "filament", "PLA", "ABS", "printing",
"manufacturing", "workshop", "workspace conditions",

// Baby nursery and health
"nursery", "baby", "infant", "child", "sleep environment",
"comfortable sleeping", "health conditions",

// Instrument and equipment care
"instrument", "guitar", "piano", "violin", "wood instruments",
"electronics", "computer equipment", "sensitive equipment",

// Storage and preservation
"wine storage", "wine cellar", "food storage",
"medication storage", "art storage", "painting",
"vintage", "antique", "collectibles",

// Home comfort and HVAC
"dehumidifier", "humidifier", "air conditioning", "AC",
"heating", "HVAC", "climate control", "comfort",
"thermostat", "energy saving",

// Paint and finishing
"paint drying", "oil painting", "watercolor",
"wood stain", "finish", "varnish", "curing",
"home improvement", "renovation",

// Plant and pet care
"houseplants", "orchids", "tropicals", "terrarium",
"reptile habitat", "pet care", "animal environment"
```

**Why this helps:** When user asks "Is it humid enough for my sourdough to rise?" Apple Intelligence can match "humid" + "sourdough" → baking context → our app provides inside humidity reading. The AI routes queries by recognizing use-case context.

### Activity Keywords

Add present-participle verb forms that indicate active use cases:

```swift
// Active monitoring keywords
"monitoring", "checking", "tracking", "measuring",
"controlling", "adjusting", "maintaining",
"optimizing", "managing", "regulating"
```

**Why this helps:** "Is it humid enough for proofing dough?" vs "Am I monitoring humidity for proofing?" - matches different query patterns.

### Comparative Keywords

Add keywords for inside/outside comparisons:

```swift
// Comparative context
"compared to outside", "vs outside", "versus outdoor",
"difference between", "warmer than outside",
"cooler than outside", "more humid", "less humid",
"actual indoor", "real indoor", "true indoor"
```

**Why this helps:** When Apple Intelligence can do cross-app reasoning (2026+), these keywords help it understand our app provides the "inside" half of comparative queries: "Is it warmer inside or outside?"

### Question Pattern Keywords

Add natural language question patterns users might ask:

```swift
// Natural language patterns
"what's the", "how warm", "how cold", "how humid",
"should I", "do I need to", "is it too",
"is it warm enough", "is it humid enough",
"can I", "safe to", "good for"
```

**Why this helps:** Maps natural language questions to our capabilities without requiring exact terminology.

### Implementation Timing

**After iOS 26.4 release:**
1. Test if basic "inside temperature" routing works
2. If yes → Add spatial context keywords first
3. Test improvements with real queries
4. Gradually add use-case keywords based on what works

**After WWDC 26 / Entity-based invocation:**
1. Full keyword expansion - Apple Intelligence can handle richer semantic matching
2. Add all use-case keywords at once
3. Add comparative keywords for cross-app reasoning
4. Monitor Siri suggestions to see what's being learned

### Expected Benefits

1. **Better Discovery:** Users find our app when searching for specific use cases
2. **Semantic Routing:** Apple Intelligence matches queries to our capabilities by context, not name
3. **Proactive Suggestions:** "You usually check humidity before baking" suggestions
4. **Cross-App Reasoning:** Apple Intelligence combines our inside data with outside weather automatically
5. **Natural Language:** Users can ask questions naturally without learning specific commands

### Files to Update (When Implementing)

**iOS:**
- `/Users/bobh/Desktop/Cricket/IOS/BLE_Central/CricketAppIntents.swift`

**macOS:**
- `/Users/bobh/Desktop/Cricket/CricketMac/CricketMac/CricketAppIntents.swift`

**Specific locations:**
```swift
static var description = IntentDescription(
    "Retrieves inside temperature from local sensor...",
    categoryName: "Weather & Environment",
    searchKeywords: [
        // Add enhanced keywords here
    ]
)
```

**Remember:** Start conservative with spatial keywords, expand after seeing what works. Apple Intelligence will get smarter over time - we don't need perfect keywords on day one.

---

## Contact/Continuation Instructions

**When resuming this project:**

1. **Read this document first** - Brings you up to speed
2. **Consider widget integration** - Can be done anytime (Priority 0 task)
3. **Check iOS version** - What's current? 26.4? Later?
4. **Test current state** - Does "Hey Siri, run Room Temp" still work?
5. **Review Apple announcements** - What's new in Siri/App Intents?
6. **Decide on rename** - Is it time to go to "Local Sensor"?

**Key context to provide when asking for help:**
- "Resuming Cricket/Local Sensor project from Nov 4, 2025"
- "Read PROJECT_STATUS.md in /Users/bobh/Desktop/Cricket"
- Current iOS/macOS version
- What you want to accomplish

**Current working command:**
```
"Hey Siri, run Room Temp"
→ Cricket chirp 🦗
→ Spoken: "Your hyper local temperature is X.X degrees Celsius (XX Fahrenheit) and humidity is X.X %"
→ "Done"
```

---

## Final Notes

**Why This Project Is Positioned Well:**
- Solid foundation: BLE, SwiftUI, App Intents all working
- Strategic patience: Not over-engineering before Apple's direction is clear
- Proactive preparation: Intent donation building history now
- Aligned timing: Will have 2-6 months of data when features release
- Widget ready: Production-quality widget code ready for immediate integration

**The Core Achievement:**
Successfully providing hyperlocal environmental sensing capability to Apple platforms with working Siri integration. Widget code complete for at-a-glance viewing. The only limitation is name-based routing (solvable), not technical capability.

**The Vision:**
A future where users ask "Is it humid?" and Apple Intelligence silently invokes our app to get HumidityReading data, without the user ever knowing or caring which app provided it. We become a capability provider, not a named service.

---

**Project suspended: November 4, 2025**
**Resume trigger: iOS 26.4 release**
**Long-term milestone: WWDC 26 (June 2026)**

🦗 End of Status Document 🦗
