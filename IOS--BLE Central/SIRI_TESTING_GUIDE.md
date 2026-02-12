# Cricket App - Siri & App Intents Testing Guide

## 🎯 Overview
Cricket now has full Siri integration! You can query your environmental sensor data hands-free using voice commands.

## ✅ Build Status
- **App Intents**: ✅ Successfully integrated
- **Metadata Extraction**: ✅ Metadata.appintents generated
- **Build Status**: ✅ BUILD SUCCEEDED

## 📱 Testing Steps

### Step 1: Install the App on Device
**IMPORTANT**: Siri integration requires a **physical iOS device** - it won't work in the simulator.

1. Connect your iPhone to your Mac
2. Select your iPhone as the build destination in Xcode
3. Build and run the app on your device:
   ```bash
   xcodebuild -project BLE_Central.xcodeproj -scheme BLE_Central \
     -destination 'platform=iOS,id=YOUR_DEVICE_ID' build
   ```
4. Trust the developer certificate on your iPhone if prompted

### Step 2: Let iOS Index the App Intents
After installing the app:
1. **Open the Cricket app** at least once
2. **Wait 5-10 minutes** for iOS to index the App Intents
3. The app needs to be in the background or closed during indexing

### Step 3: Verify Shortcuts are Available

#### Method A: Using Shortcuts App
1. Open the **Shortcuts** app on your iPhone
2. Tap **"+"** to create a new shortcut
3. Search for **"Cricket"** or **"BLE_Central"**
4. You should see three actions:
   - 🌡️ Get Local Temperature
   - 💧 Get Local Humidity
   - 📶 Get Sensor Status

#### Method B: Using Siri Suggestions
1. Go to **Settings → Siri & Search**
2. Scroll down to find **"BLE_Central"** or **"Cricket"**
3. Enable **"Use with Ask Siri"**
4. You may see suggested shortcuts

### Step 4: Test Siri Commands

Try these voice commands with Siri:

#### Temperature Queries:
- 🗣️ **"Hey Siri, BLE_Central local temperature"**
- 🗣️ **"Hey Siri, BLE_Central temperature"**
- 🗣️ **"Hey Siri, what's my local temperature in BLE_Central"**
- 🗣️ **"Hey Siri, get my temperature from BLE_Central"**

Expected Response:
- 🦗 *Cricket chirp sound*
- "Your local temperature is 23.4 °C" (or "No temperature data available...")

#### Humidity Queries:
- 🗣️ **"Hey Siri, BLE_Central local humidity"**
- 🗣️ **"Hey Siri, BLE_Central humidity"**
- 🗣️ **"Hey Siri, what's my local humidity in BLE_Central"**
- 🗣️ **"Hey Siri, get my humidity from BLE_Central"**

Expected Response:
- "Your local humidity is 45.7 %" (or "No humidity data available...")

#### Sensor Status:
- 🗣️ **"Hey Siri, BLE_Central sensor status"**
- 🗣️ **"Hey Siri, BLE_Central sensor"**
- 🗣️ **"Hey Siri, check my BLE_Central sensor"**
- 🗣️ **"Hey Siri, is my BLE_Central sensor connected"**

Expected Response:
- "Your Arduino sensor is: Connected to Arduino" (or current status)

## 🎵 Special Features

### Cricket Chirp Sound
When you ask for temperature, Cricket plays a delightful cricket chirp sound! 🦗
- Sound file: `cricket.wav` (included in app bundle)
- 0.8 second audio feedback before Siri speaks

## 🔧 Troubleshooting

### "Sorry, I can't help with that"
**Possible causes:**
1. **App not indexed yet** → Wait 10-15 minutes after first launch
2. **Siri disabled for app** → Check Settings → Siri & Search → BLE_Central
3. **Testing on simulator** → Must use physical device

### "No temperature data available"
**Possible causes:**
1. **Arduino not connected** → Check Bluetooth connection in app
2. **No sensor data yet** → Wait for first reading from sensor
3. **App in background** → Data persists in UserDefaults, should still work

### App Intent not found
**Solutions:**
1. **Rebuild the app** → Clean build folder, rebuild and reinstall
2. **Restart device** → Sometimes iOS needs a restart to index properly
3. **Check bundle ID** → Ensure `wm6h.Cricket-ios` is correct

## 📊 Data Flow

```
Arduino Sensor → BLE → BluetoothViewModel → UserDefaults
                                                    ↓
                                            App Intent reads
                                                    ↓
                                            Siri speaks result
```

**Key Details:**
- Data saved to `UserDefaults.standard`
- Keys: `currentTemperature`, `currentHumidity`, `connectionStatus`
- Data persists even when app is closed
- App Intents run in background without opening app

## 🎯 Expected Behavior

### With Connected Sensor:
1. Open Cricket app → Arduino connects
2. Data displays in app (e.g., "23.4 °C", "45.7 %")
3. Data saved to UserDefaults automatically
4. Ask Siri → Immediate response with current data
5. Hear cricket chirp (for temperature queries)

### Without Connected Sensor:
1. Open Cricket app → Shows "Scanning..." or "No Arduino found"
2. No data saved (temperature = "--")
3. Ask Siri → "No temperature data available from your Arduino sensor"

## 🚀 Advanced Usage

### Creating Custom Shortcuts
1. Open **Shortcuts** app
2. Create new shortcut
3. Add **"Get Local Temperature"** action from Cricket
4. Add **"Speak Text"** action
5. Customize the spoken response
6. Give it a custom name
7. Now say: "Hey Siri, [your custom name]"

### Automation Examples
- **Morning routine**: "Check my room temperature"
- **Before sleep**: "What's the humidity level"
- **Home automation**: Trigger actions based on sensor readings

## 📝 Implementation Details

### App Intents Code
Located in: `/Users/bobh/Desktop/Cricket/IOS/BLE_Central/CricketAppIntents.swift`

Three intents implemented:
1. `GetLocalTemperatureIntent` - Returns temperature with cricket chirp
2. `GetLocalHumidityIntent` - Returns humidity reading
3. `GetSensorStatusIntent` - Returns connection status

### App Shortcuts Provider
Located in: `/Users/bobh/Desktop/Cricket/IOS/BLE_Central/BLE_CentralApp.swift`

Registers phrases with Siri and defines shortcut appearance.

## ✅ Testing Checklist

- [ ] App installed on physical iOS device
- [ ] App opened at least once
- [ ] Waited 10 minutes for indexing
- [ ] Shortcuts visible in Shortcuts app
- [ ] "Use with Ask Siri" enabled in Settings
- [ ] Arduino sensor connected and showing data
- [ ] Temperature Siri command works
- [ ] Humidity Siri command works
- [ ] Sensor status command works
- [ ] Cricket chirp sound plays for temperature

## 🎉 Success Indicators

When everything is working:
- ✅ Siri recognizes "BLE_Central" commands
- ✅ Cricket chirp plays before temperature response
- ✅ Accurate sensor readings returned
- ✅ Works without opening the app
- ✅ Works even when app is closed
- ✅ Fast response (<2 seconds)

## 📞 Support

If you encounter issues:
1. Check Console logs when invoking Siri
2. Verify UserDefaults contains data (use debugger)
3. Rebuild app with clean build
4. Restart iOS device
5. Check iOS version (requires iOS 16.0+)

Happy Cricket-ing! 🦗🌡️💧
