# 🦗 Cricket - Siri Voice Commands

## ✅ Setup Complete!
- Info.plist configured with Siri support
- App Intents registered
- Metadata extracted successfully
- BUILD SUCCEEDED

## 📱 Installation Requirements
**CRITICAL**: Siri integration only works on **physical iOS devices** - not simulators!

1. Install Cricket app on your iPhone
2. Open the app at least once
3. Wait 10-15 minutes for iOS to index the shortcuts
4. Go to **Settings → Siri & Search → Cricket** → Enable "Use with Ask Siri"

## 🗣️ Siri Voice Commands

The app display name is **"Cricket"** so use these phrases:

### Temperature 🌡️
- 🗣️ **"Hey Siri, Cricket temp"**
- 🗣️ **"Hey Siri, check Cricket temperature"**
- 🗣️ **"Hey Siri, what's my temperature in Cricket"**
- 🗣️ **"Hey Siri, temperature in Cricket"**
- 🗣️ **"Hey Siri, get local temperature with Cricket"**

**Expected Response:**
- 🦗 *Cricket chirp sound plays*
- "Your local temperature is 23.4 °C"

### Humidity 💧
- 🗣️ **"Hey Siri, Cricket humidity"**
- 🗣️ **"Hey Siri, check Cricket humidity"**
- 🗣️ **"Hey Siri, what's my humidity in Cricket"**
- 🗣️ **"Hey Siri, humidity in Cricket"**
- 🗣️ **"Hey Siri, get local humidity with Cricket"**

**Expected Response:**
- "Your local humidity is 45.7 %"

### Sensor Status 📶
- 🗣️ **"Hey Siri, Cricket status"**
- 🗣️ **"Hey Siri, check Cricket sensor"**
- 🗣️ **"Hey Siri, Cricket sensor status"**
- 🗣️ **"Hey Siri, is Cricket connected"**

**Expected Response:**
- "Your Arduino sensor is: Connected to Arduino"

## 🎯 Recommended Commands (Shortest)
These are the easiest to remember:
- **"Hey Siri, Cricket temp"** 🦗
- **"Hey Siri, Cricket humidity"**
- **"Hey Siri, Cricket status"**

## ✅ Verification Steps

### 1. Check in Shortcuts App
1. Open **Shortcuts** app
2. Tap **+** to create new shortcut
3. Search for **"Cricket"**
4. You should see:
   - 🌡️ Get Local Temperature
   - 💧 Get Local Humidity
   - 📶 Get Sensor Status

### 2. Check Siri Settings
1. **Settings → Siri & Search**
2. Scroll to **"Cricket"**
3. Enable **"Use with Ask Siri"**
4. Enable **"Show in Search"**
5. Enable **"Suggest Shortcuts"**

### 3. Test Commands
Try the shortest commands first:
```
"Hey Siri, Cricket temp"
"Hey Siri, Cricket humidity"
"Hey Siri, Cricket status"
```

## 🔧 Troubleshooting

### "I don't see that in your apps"
**Causes:**
- App not indexed yet → **Wait 15 minutes, then restart phone**
- Siri disabled → **Check Settings → Siri & Search → Cricket**
- Testing on simulator → **Must use physical iPhone**

### "Here's what I found on the web"
**Causes:**
- App intents not indexed → **Wait longer, restart device**
- Wrong phrase → **Use exact phrases with "Cricket" in them**
- App name mismatch → **Say "Cricket" not "BLE_Central"**

**Solutions:**
1. Delete and reinstall the app
2. Restart your iPhone
3. Wait 15-20 minutes after installation
4. Make sure you opened Cricket at least once

### No temperature data available
**Causes:**
- Arduino not connected → **Open app, connect Arduino**
- No readings yet → **Wait for first sensor reading**

**This is normal** - The intent works, just no data yet!

## 🎵 Cricket Chirp Sound
The temperature command plays a delightful cricket chirp before Siri speaks!
- Only plays for **temperature queries**
- Not played for humidity or status
- Uses `cricket.wav` from app bundle (60 KB)

## 📊 How It Works

```
"Hey Siri, Cricket temp"
         ↓
Siri recognizes "Cricket temp" phrase
         ↓
Launches GetLocalTemperatureIntent
         ↓
Intent reads UserDefaults
         ↓
Plays cricket.wav (0.8 seconds)
         ↓
Returns temperature string to Siri
         ↓
Siri speaks: "Your local temperature is 23.4 °C"
```

## 🚀 Advanced: Custom Shortcuts

Create your own phrases:

1. Open **Shortcuts** app
2. Tap **+** to create new
3. Add **"Get Local Temperature"** (from Cricket)
4. Add **"Speak Text"** action
5. Customize the response text
6. Name it: "Room Temperature"
7. Now say: **"Hey Siri, Room Temperature"**

### Example Custom Shortcuts
- "Morning temperature" → Gets temp, says "Good morning, it's X degrees"
- "Bedtime humidity" → Gets humidity, adjusts smart humidifier
- "Climate check" → Gets both temp and humidity, formats nicely

## 📝 Technical Details

### Files Modified
- `Info.plist` - Added NSUserActivityTypes, NSSiriUsageDescription
- `BLE_CentralApp.swift` - App Shortcuts registration
- `CricketAppIntents.swift` - Three App Intents implemented

### Data Storage
- Keys: `currentTemperature`, `currentHumidity`, `connectionStatus`
- Location: `UserDefaults.standard`
- Updated: Every time sensor sends new data
- Persists: Even when app is closed

### Supported iOS Versions
- iOS 16.0+ (App Intents framework)
- iOS 18.0 recommended (improved Siri)

## 🎉 Success Checklist
- [ ] App installed on iPhone (not simulator)
- [ ] App opened at least once
- [ ] Waited 15 minutes for indexing
- [ ] Siri enabled for Cricket in Settings
- [ ] Shortcuts visible in Shortcuts app
- [ ] Arduino connected and showing data
- [ ] Said: "Hey Siri, Cricket temp"
- [ ] Heard cricket chirp 🦗
- [ ] Heard Siri speak temperature
- [ ] Works without opening app

## 🆘 Still Not Working?

1. **Delete the app completely**
2. **Restart your iPhone**
3. **Reinstall Cricket from Xcode**
4. **Open Cricket app**
5. **Connect to Arduino sensor**
6. **Wait 20 minutes** (seriously, iOS indexing is slow)
7. **Restart iPhone again**
8. **Try: "Hey Siri, Cricket temp"**

If still broken:
- Check iOS version (need 16.0+)
- Check Siri language (English works best)
- Try in Shortcuts app first (before Siri)
- Check Console.app for errors

Happy Cricket-ing! 🦗🌡️💧
