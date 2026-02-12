# 🦗 Cricket macOS Shortcuts Setup Guide

## ✅ Modern App Intents Implementation

Cricket macOS app uses **App Intents** for seamless Siri and Shortcuts integration - no shell scripts needed!

---

## 📱 Create Cricket Shortcuts on macOS

### Shortcut 1: Room Temperature 🌡️ (with Cricket Chirp)

**Step-by-Step Instructions:**

1. Open **Shortcuts** app (in Applications folder)

2. Go to **File → New Shortcut** (or press ⌘N)

3. In the right sidebar search box, type: **"Cricket"**
   - You should see Cricket app actions appear

4. Click on **"Get Local Temperature"** to add it to your workflow
   - This action will appear in the main workflow area

5. In the search box again, type: **"Speak"**

6. Click on **"Speak Text"** to add it below the temperature action
   - It should automatically connect the temperature output to Speak Text
   - You'll see "Temperature" connected to the Speak Text input

7. Click on **"Untitled Shortcut"** at the top and rename it to: **"Room Temperature"** or **"Cricket"**

8. The shortcut is automatically saved

9. **Test it:** Click the play button (▶) at the top right
   - You should hear: Cricket chirp 🦗 + spoken temperature!

10. **Wait 1-2 minutes** for Siri to index the new shortcut

11. **Try Siri:** Say **"Hey Siri, run Room Temperature"** or **"Hey Siri, run Cricket"**

**Result:** Cricket chirp 🦗 + "Your local temperature is 22.3 °C (72 Fahrenheit) and humidity is 45.2 %"

---

### Shortcut 2: Room Humidity 💧

**Step-by-Step Instructions:**

1. Open **Shortcuts** app
2. **File → New Shortcut** (⌘N)
3. Search for **"Cricket"**
4. Add **"Get Local Humidity"** action
5. Search for **"Speak"**
6. Add **"Speak Text"** action
7. Rename to **"Room Humidity"**
8. Click play (▶) to test
9. Say: **"Hey Siri, run Room Humidity"**

**Result:** "Your local humidity is 45.2 %"

---

### Shortcut 3: Sensor Status 📶

**Step-by-Step Instructions:**

1. Open **Shortcuts** app
2. **File → New Shortcut** (⌘N)
3. Search for **"Cricket"**
4. Add **"Get Sensor Status"** action
5. Search for **"Speak"**
6. Add **"Speak Text"** action
7. Rename to **"Sensor Status"**
8. Click play (▶) to test
9. Say: **"Hey Siri, run Sensor Status"**

**Result:** "Your Arduino sensor is: Connected to Arduino" (or RuuviTag status)

---

## 🎯 How to Use Your Shortcuts

### Method 1: Click to Run
- Open Shortcuts app
- Click any shortcut to run it immediately

### Method 2: Siri Voice Commands
- **"Hey Siri, run Room Temperature"** 🦗
- **"Hey Siri, run Room Humidity"** 💧
- **"Hey Siri, run Sensor Status"** 📶

### Method 3: Keyboard Shortcut
1. Right-click any shortcut
2. Select **"Details"**
3. Click **"Add Keyboard Shortcut"**
4. Press your preferred key combination
5. Now you can trigger it instantly!

### Method 4: Menu Bar (via Shortcuts)
- Shortcuts appear in the Shortcuts menu bar icon
- Quick access without opening the app

---

## 🎵 What You'll Hear

### Temperature Shortcut:
1. 🦗 **Cricket chirp** (0.8 seconds)
2. 🗣️ **Mac speaks:** "Your local temperature is 23.4 °C (74 Fahrenheit) and humidity is 45.7 %"

### Humidity Shortcut:
1. 🗣️ **Mac speaks:** "Your local humidity is 45.7 %"

### Status Shortcut:
1. 🗣️ **Mac speaks:** "Your Arduino sensor is: Connected to Arduino"

---

## 🔧 Advanced: Customize Your Shortcuts

### Add Pause Before Speaking
If you want a longer pause after the chirp:
1. Edit the Temperature shortcut
2. After "Get Local Temperature", click the **+** button
3. Add **"Wait"** action
4. Set it to **1 second**
5. Then add "Speak Text"

### Custom Spoken Messages
Customize what your Mac says:
1. Edit any shortcut
2. After the Cricket action, add **"Text"** action
3. Type: "The temperature is [temperature]"
4. Use the variable picker (click "temperature") to insert the actual value
5. Connect this to "Speak Text" instead of the default

### Combine Multiple Readings
Create a "Full Climate Report":
1. Add **"Get Local Temperature"** action
2. Add **"Get Local Humidity"** action
3. Add **"Text"** action
4. Type: "Temperature: [temperature]. Humidity: [humidity]"
5. Use variable picker to insert both values
6. Add **"Speak Text"** action

### Save to File
Log readings to a file:
1. Add **"Get Local Temperature"** action
2. Add **"Append to Text File"** action
3. Choose file location (e.g., Documents/Cricket_Log.txt)
4. Format: "[date] - [temperature]"

---

## 🐛 Troubleshooting

### "No Cricket actions appear in search"
**Causes:**
- Cricket Mac app not installed
- App hasn't been launched since installation
- System hasn't indexed App Intents yet

**Solutions:**
1. Make sure **Cricket_mac.app** is in `/Applications/`
2. Open Cricket app at least once
3. Wait 5-10 minutes for system to index
4. Restart Shortcuts app
5. Try searching again

### "Action not found" error when running shortcut
**Cause:** Cricket app was deleted or moved

**Solution:**
- Reinstall Cricket_mac.app to `/Applications/`
- Open it once
- Wait 2 minutes
- Try again

### "No temperature data available"
**Cause:** Cricket app isn't running or no sensor connected

**Solution:**
1. Open Cricket Mac app
2. Make sure Arduino or RuuviTag sensor is connected
3. Verify green "Connected" status in app
4. Wait for temperature reading to appear
5. Try the shortcut again

### Shortcut doesn't speak
**Cause:** System volume or text-to-speech issue

**Solution:**
1. Check system volume is up
2. Test: Say **"Hey Siri, what time is it?"** (should speak)
3. Check System Settings → Accessibility → Spoken Content
4. Try running shortcut manually from Shortcuts app

### No cricket chirp when running shortcut
**Cause:** Volume too low or audio file missing

**Solution:**
1. Turn up Mac volume
2. Check Mac is not muted
3. The chirp plays through the Cricket app, so the app must be able to access audio
4. Try running the shortcut manually to verify chirp plays

### Siri doesn't recognize shortcut name
**Cause:** Siri indexing delay or name conflict

**Solutions:**
1. Wait 1-2 minutes after creating shortcut
2. Say the FULL name: "Hey Siri, run Room Temperature" (not just "Room Temperature")
3. Try renaming to something unique like "Cricket Reading"
4. Check Shortcuts app shows the shortcut with correct name

---

## 📊 Requirements

### What You Need:
- ✅ **Cricket_mac.app** installed in `/Applications/`
- ✅ **Hardware:** Arduino Nano 33 Sense Rev 2 OR RuuviTag sensor
- ✅ **macOS:** Version 14.0 or later (for App Intents support)
- ✅ **Siri:** Enabled in System Settings

### What You DON'T Need:
- ❌ Shell scripts
- ❌ Terminal commands
- ❌ Manual UserDefaults access
- ❌ Programming knowledge

---

## 🏆 You're All Set!

You now have fully functional Cricket shortcuts using modern App Intents:
- ✅ Temperature with cricket chirp 🦗
- ✅ Humidity reading 💧
- ✅ Sensor connection status 📶

These shortcuts work seamlessly with:
- **Siri voice commands**
- **Keyboard shortcuts**
- **Menu bar access**
- **Automation workflows**

---

## 📊 Quick Reference

| Shortcut Name | App Intent | Sound | Speech |
|--------------|------------|-------|---------|
| Room Temperature | Get Local Temperature | 🦗 Chirp | "Your local temperature is X°C (XF)" |
| Room Humidity | Get Local Humidity | None | "Your local humidity is X%" |
| Sensor Status | Get Sensor Status | None | "Your [sensor] is: [status]" |

---

## 🔮 Future Enhancements (iOS 26.4+)

When Apple releases entity-based invocation (expected 2026):
- Natural queries: **"What's the inside temperature?"** (no app name needed)
- Smart routing: Apple Intelligence knows to use Cricket for indoor readings
- Ambient availability: Siri silently invokes Cricket when needed
- Cross-app reasoning: **"Is it warmer inside or outside?"**

Your shortcuts will keep working - Apple Intelligence will just get smarter! 🎉

---

Happy Cricket monitoring! 🦗🌡️💧
