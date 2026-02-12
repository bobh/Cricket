# 🦗 Cricket iPhone Shortcuts Setup Guide

## ✅ App Updated!
Cricket app has been reinstalled with the **cricket chirp sound** re-enabled for temperature queries!

---

## 📱 Create All Three Cricket Shortcuts

### Shortcut 1: Room Temperature 🌡️ (with Cricket Chirp)

1. Open **Shortcuts** app
2. Tap **"+"** (top right corner)
3. Tap **"Add Action"**
4. Search for **"Cricket"**
5. Tap **"Get Local Temperature"** to add it
6. Tap **"+"** below to add another action
7. Search for **"Speak Text"**
8. Tap **"Speak Text"** to add it
9. The temperature should automatically connect to Speak Text
10. Tap **"Done"** (top right)
11. Name it: **"Room Temperature"** or **"Cricket Temp"**
12. Tap **"Done"** again

**Result:** Cricket chirp plays 🦗 + Siri speaks temperature!

---

### Shortcut 2: Room Humidity 💧

1. Open **Shortcuts** app
2. Tap **"+"** (top right corner)
3. Tap **"Add Action"**
4. Search for **"Cricket"**
5. Tap **"Get Local Humidity"** to add it
6. Tap **"+"** below to add another action
7. Search for **"Speak Text"**
8. Tap **"Speak Text"** to add it
9. The humidity should automatically connect to Speak Text
10. Tap **"Done"** (top right)
11. Name it: **"Room Humidity"** or **"Cricket Humidity"**
12. Tap **"Done"** again

**Result:** Siri speaks humidity percentage!

---

### Shortcut 3: Sensor Status 📶

1. Open **Shortcuts** app
2. Tap **"+"** (top right corner)
3. Tap **"Add Action"**
4. Search for **"Cricket"**
5. Tap **"Get Sensor Status"** to add it
6. Tap **"+"** below to add another action
7. Search for **"Speak Text"**
8. Tap **"Speak Text"** to add it
9. The status should automatically connect to Speak Text
10. Tap **"Done"** (top right)
11. Name it: **"Sensor Status"** or **"Cricket Status"**
12. Tap **"Done"** again

**Result:** Siri speaks connection status!

---

## 🎯 How to Use Your Shortcuts

### Method 1: Tap to Run
- Open Shortcuts app
- Tap any shortcut to run it immediately

### Method 2: Add to Home Screen
1. Long-press on any shortcut
2. Choose **"Share"**
3. Choose **"Add to Home Screen"**
4. Now you have a one-tap widget!

### Method 3: Add to Widgets
1. Long-press on home screen
2. Tap **"+"** in top left
3. Search for **"Shortcuts"**
4. Add a Shortcuts widget
5. Configure it to show your Cricket shortcuts

### Method 4: Siri Voice Commands (When iOS 26 Fixes Voice Bug)
Once Apple fixes the Siri voice bug in iOS 26:
- **"Hey Siri, Room Temperature"** 🦗
- **"Hey Siri, Room Humidity"** 💧
- **"Hey Siri, Sensor Status"** 📶

For now, use the shortcut names you created!

---

## 🎵 What You'll Hear

### Temperature Shortcut:
1. 📱 **App briefly opens** (Cricket needs foreground access for audio)
2. 🦗 **Cricket chirp** (0.8 seconds)
3. 📱 **Returns to Shortcuts**
4. 🗣️ **Siri speaks:** "Your local temperature is 23.4 °C, or 74 degrees Fahrenheit"

### Humidity Shortcut:
1. 🗣️ **Siri speaks:** "Your local humidity is 45.7 %"

### Status Shortcut:
1. 🗣️ **Siri speaks:** "Your Arduino sensor is: Connected to Arduino"

---

## 🔧 Advanced: Customize Your Shortcuts

### Add Pause Before Speaking
If the chirp and voice overlap:
1. Edit the Temperature shortcut
2. After "Get Local Temperature", add **"Wait"**
3. Set it to **1 second**
4. Then add "Speak Text"

### Custom Spoken Messages
You can customize what Siri says:
1. Edit any shortcut
2. After the Cricket action, add **"Text"**
3. Type: "The temperature is [temperature]"
4. Use the variable picker to insert the actual temperature
5. Connect this to "Speak Text" instead

### Combine Multiple Readings
Create a "Full Climate Report":
1. Add "Get Local Temperature"
2. Add "Get Local Humidity"
3. Add "Text" action
4. Type: "Temperature: [temperature]. Humidity: [humidity]"
5. Add "Speak Text"

---

## 🎤 Troubleshooting

### "No temperature data available"
- Open the Cricket app
- Make sure Arduino is connected (green LED)
- Wait for temperature reading to appear
- Try the shortcut again

### Shortcut doesn't show Cricket actions
- Wait 10-15 minutes after installing app
- Restart your iPhone
- Open Cricket app at least once

### No cricket chirp when running shortcut
**Update (iOS 18+):** The app now opens briefly to play the chirp sound, then returns to your shortcut!

**If chirp still doesn't play:**
- Check iPhone is not in silent mode
- Turn up volume
- The app will briefly flash open (this is normal - it needs foreground access to play the chirp)

**Alternative:** Add cricket sound manually to your shortcut:
1. Edit the Temperature shortcut
2. Before "Get Local Temperature", add **"Play Sound"**
3. Choose **"Add to Shortcut"**
4. Select the cricket.wav file (you'll need to export it from the Cricket app first)
5. Now the shortcut plays: Cricket chirp → Gets temp → Speaks temp

### Chirp plays but no voice
- This is the iOS 26 beta Siri bug
- The "Speak Text" action should still work
- Check your iPhone volume while shortcut runs

---

## 🏆 You're All Set!

You now have three fully functional Cricket shortcuts:
- ✅ Temperature with cricket chirp 🦗
- ✅ Humidity reading 💧
- ✅ Sensor connection status 📶

All working around the iOS 26 Siri voice bug!

When iOS 26 beta is fixed, these same intents will work with:
- **"Hey Siri, Cricket temp"**
- **"Hey Siri, Cricket humidity"**
- **"Hey Siri, Cricket status"**

No app updates needed - it'll just start working! 🎉

---

## 📊 Quick Reference

| Shortcut Name | Action | Sound | Speech |
|--------------|--------|-------|---------|
| Room Temperature | Get temp + Speak | 🦗 Chirp | "Your local temperature is X°C" |
| Room Humidity | Get humidity + Speak | None | "Your local humidity is X%" |
| Sensor Status | Get status + Speak | None | "Your Arduino sensor is: [status]" |

Happy Cricket monitoring! 🦗🌡️💧
