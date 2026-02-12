# Demetor macOS - Siri & Shortcuts Setup Guide

## ✅ App Intents Implementation Complete

The following features are now built into Demetor macOS:

### **Siri Voice Commands:**
- "What's my local temperature in Demetor"
- "What's my local humidity in Demetor"
- "Check my Demetor sensor"

### **Shortcuts App Integration:**
1. **Local Temperature** - Get current temperature reading
2. **Local Humidity** - Get current humidity reading
3. **Sensor Status** - Check Arduino/RuuviTag connection status

---

## 🔧 Setup Steps (Required After Each Build)

### Step 1: Run the App
1. Launch **Demetor_mac.app** from Xcode or Finder
2. Wait for sensor data to populate (connect Arduino or RuuviTag)
3. Verify temperature/humidity readings appear

### Step 2: Register App Intents with System
The app needs to tell macOS about its Siri capabilities:

```bash
# Method 1: Quit and relaunch the app
# This registers the App Intents automatically

# Method 2: Force re-registration
pluginkit -a /Users/bobh/Library/Developer/Xcode/DerivedData/DemetorMac-ailmkmuovgrtwshggjgybymuhvhq/Build/Products/Debug/Demetor_mac.app
pluginkit -r /Users/bobh/Library/Developer/Xcode/DerivedData/DemetorMac-ailmkmuovgrtwshggjgybymuhvhq/Build/Products/Debug/Demetor_mac.app

# Method 3: Reset App Intents cache
rm -rf ~/Library/Caches/com.apple.Spotlight/
killall Spotlight
```

### Step 3: Enable Siri (If Not Already Enabled)
1. Open **System Settings** → **Siri & Spotlight**
2. Turn on **Ask Siri**
3. Choose **Keyboard Shortcut** or **Voice** activation
4. For voice: Enable microphone access for Siri

### Step 4: Test Siri Commands
**Voice Method:**
- Press Fn+Space (or your Siri shortcut)
- Say: "What's my local temperature in Demetor"

**Keyboard Method:**
- Press Fn+Space twice (or hold Command+Space)
- Type: "What's my local temperature in Demetor"

### Step 5: Verify Shortcuts
1. Open **Shortcuts app** (Applications folder)
2. Look for "Demetor" in the app sidebar
3. You should see:
   - Local Temperature
   - Local Humidity
   - Sensor Status
4. Click any shortcut to run it

---

## 🐛 Troubleshooting

### Siri Says "I don't see that app"
**Problem:** App Intents not registered with system

**Solution:**
```bash
# Quit Demetor app completely
# Run registration commands
pluginkit -a /path/to/Demetor_mac.app
pluginkit -r /path/to/Demetor_mac.app

# Relaunch app
open /path/to/Demetor_mac.app
```

### Shortcuts Don't Appear
**Problem:** Spotlight hasn't indexed the app

**Solution:**
```bash
# Reset Spotlight index
sudo mdutil -E /

# Wait 2-3 minutes for reindexing
# Check Shortcuts app again
```

### "No Data Available"
**Problem:** App hasn't stored sensor data yet

**Solution:**
1. Make sure Demetor is running
2. Verify Arduino or RuuviTag is connected
3. Check that readings appear in the main window
4. Wait 5 seconds for UserDefaults to sync
5. Try Siri command again

### Siri Returns Text But No Voice
**Normal behavior** - App Intents return string values that Siri displays

---

## 📝 Technical Details

### App Intents Metadata Location:
```
Demetor_mac.app/Contents/Resources/Metadata.appintents/
├── extract.actionsdata
└── version.json
```

### UserDefaults Keys Used:
- `currentTemperature` - "23.4 °C" format
- `currentHumidity` - "45.7 %" format
- `connectionStatus` - "Connected to Arduino" or "Receiving data from RuuviTag"
- `sensorSource` - "BLE" or "Ruuvi"

### Supported Siri Phrase Patterns:
```
"What's my local [temperature|humidity] in Demetor"
"Get my [temperature|humidity] from Demetor"
"Show my Demetor [temperature|humidity]"
"Check my Demetor sensor"
"Is my Demetor sensor connected"
```

---

## ✅ Verification Checklist

- [ ] Demetor app is running with active sensor data
- [ ] App has been launched at least once since last build
- [ ] Siri is enabled in System Settings
- [ ] Shortcuts app shows Demetor shortcuts
- [ ] Siri responds to "What's my local temperature in Demetor"
- [ ] Shortcuts can be run manually from Shortcuts app

---

## 🎯 Next Steps

Once Siri integration is verified, you can:
1. Create custom Shortcuts automations (e.g., "Log temperature every hour")
2. Use shortcuts in HomeKit scenes
3. Create Focus Mode triggers based on temperature
4. Add Menu Bar widget for quick access (Phase 2)
