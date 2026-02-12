# 🦗 Cricket - Siri Voice Bug Testing Guide

## Background

**Current Issue (iOS 26.0.1 beta):**
- Siri doesn't speak responses (shows text only)
- Affects all Siri queries, not just Cricket app
- Test: "Hey Siri, what time is it?" → Shows time but doesn't speak

**Workaround:**
- Use Shortcuts app with "Speak Text" action
- Requires tapping "Done" button during execution

---

## When to Test

Test after each of these updates:
- ✅ **iOS 26.x beta updates** (most likely to fix the bug)
- ✅ **iOS 26.0 final release** (when it exits beta)
- ✅ **macOS 15.x updates** (if Mac has similar issue)
- ✅ **watchOS updates** (if you add Apple Watch support later)

---

## Step 1: Test Basic Siri Voice (NOT Cricket-specific)

Before testing Cricket, verify Siri voice works in general:

### iOS Testing:
1. **Say:** "Hey Siri, what time is it?"
   - ✅ **FIXED** if: Siri speaks the time out loud
   - ❌ **Still broken** if: Only shows text, no voice

2. **Say:** "Hey Siri, what's the weather?"
   - ✅ **FIXED** if: Siri speaks the weather
   - ❌ **Still broken** if: Only shows text

3. **Check Settings:**
   - Go to **Settings → Apple Intelligence & Siri** (or "Siri & Search" in older iOS)
   - Verify **"Spoken Responses"** = "Automatic" or "Always"
   - Verify **"Type to Siri"** is OFF (voice should be default)

### macOS Testing:
1. Click Siri icon or say "Hey Siri"
2. Ask: "What time is it?"
3. Verify Siri speaks response

**If basic Siri voice doesn't work, STOP HERE.** The bug is still present. Cricket won't work either.

---

## Step 2: Test Cricket App Intents Directly (Without Shortcuts)

Once basic Siri voice works, test Cricket App Intents:

### Method A: Voice Commands (Recommended)

**Temperature Query:**
1. **Say:** "Hey Siri, Cricket temp"
2. **Expected behavior:**
   - 🦗 Cricket chirp plays
   - 📱 App opens briefly (for chirp audio)
   - 🗣️ **Siri speaks:** "Your local temperature is X.X °C, or XX degrees Fahrenheit"
   - No "Done" button
   - No manual tap needed

**Humidity Query:**
3. **Say:** "Hey Siri, Cricket humidity"
4. **Expected behavior:**
   - 🗣️ **Siri speaks:** "Your local humidity is X.X %"
   - No chirp (humidity doesn't play chirp)

**Status Query:**
5. **Say:** "Hey Siri, Cricket status"
6. **Expected behavior:**
   - 🗣️ **Siri speaks:** "Your Arduino sensor is: Connected to Arduino"

### Method B: Type to Siri (Alternative)

If voice doesn't work, try typing:
1. Activate Siri (long-press power/home button)
2. Type: "Cricket temp"
3. Verify Siri **speaks** the response

---

## Step 3: Test App Intents from Shortcuts App

Even if Siri voice works, test Shortcuts behavior changed:

### Test WITHOUT "Speak Text" Action:

1. **Open Shortcuts app**
2. **Create new shortcut:**
   - Add action: **"Get Local Temperature"** (from Cricket)
   - Do NOT add "Speak Text"
   - Do NOT add "Wait"
3. **Run the shortcut by tapping it**
4. **Expected behavior (bug fixed):**
   - 🦗 Cricket chirp plays
   - 📱 App opens briefly
   - 🗣️ **Siri automatically speaks** the temperature
   - ❌ **NO "Done" button**
   - Returns to Shortcuts automatically

5. **If still broken:**
   - "Done" button appears
   - Must tap "Done" to continue
   - No voice unless you add "Speak Text"

### Test WITH "Speak Text" Action (Current Workaround):

6. **Edit your existing "Room Temperature" shortcut**
7. **Remove the "Speak Text" action**
8. **Run the shortcut**
9. **If bug is fixed:**
   - Siri speaks automatically (no "Speak Text" needed)
   - You can delete the "Speak Text" workaround

---

## Step 4: Compare Before/After Behavior

| Feature | iOS 26.0.1 Beta (Broken) | Fixed iOS |
|---------|-------------------------|-----------|
| "Hey Siri, what time is it?" | Shows text only | Speaks time |
| "Hey Siri, Cricket temp" | Shows text only | Speaks temp + chirp |
| Cricket chirp plays | ✅ Yes (via openAppWhenRun) | ✅ Yes |
| Shortcuts: Get Temperature | Shows "Done" button | No "Done" button |
| Shortcuts: Need "Speak Text"? | ✅ Yes (workaround) | ❌ No (automatic) |
| App opens for chirp | ✅ Yes | ✅ Yes |

---

## Step 5: What to Do When Bug is Fixed

### Option A: Keep Current Shortcuts (Safe)

Your existing shortcuts will continue to work:
- Cricket chirp ✅
- "Speak Text" speaks temperature ✅
- "Done" button still appears (harmless)

**Advantage:** No changes needed, guaranteed to work

### Option B: Update Shortcuts (Cleaner)

1. **Edit "Room Temperature" shortcut**
2. **Remove "Speak Text" action**
3. **Test:** Siri should speak automatically
4. **Benefit:** No more "Done" button, more seamless

Do this for all three shortcuts:
- Room Temperature
- Room Humidity
- Sensor Status

### Option C: Update Cricket App Code (Optional)

If you want to remove the workaround code:

**In CricketAppIntents.swift:**
```swift
// OPTIONAL: Change this back to false (currently true)
static var openAppWhenRun: Bool = false
```

**Trade-off:**
- ✅ App won't open visibly (more seamless)
- ❌ Cricket chirp may not play reliably from Shortcuts context
- ✅ Direct Siri voice commands ("Hey Siri, Cricket temp") will still work

**Recommendation:** Keep `openAppWhenRun = true` so cricket chirp always works!

---

## Step 6: Testing Checklist

After each iOS/macOS update, check these:

### Basic Siri:
- [ ] "Hey Siri, what time is it?" speaks out loud
- [ ] "Hey Siri, what's the weather?" speaks out loud
- [ ] Settings → Siri → Spoken Responses = works

### Cricket Voice Commands:
- [ ] "Hey Siri, Cricket temp" → speaks temperature + chirp
- [ ] "Hey Siri, Cricket humidity" → speaks humidity
- [ ] "Hey Siri, Cricket status" → speaks status
- [ ] All above work without "Done" button

### Cricket Shortcuts:
- [ ] Tap "Room Temperature" → speaks temp (no "Done" button)
- [ ] Tap "Room Humidity" → speaks humidity (no "Done" button)
- [ ] Tap "Sensor Status" → speaks status (no "Done" button)
- [ ] Cricket chirp plays for temperature queries

### Special Cases:
- [ ] Test with iPhone locked (should still speak)
- [ ] Test with silent mode ON (should still speak if ringer vol > 0)
- [ ] Test with Bluetooth headphones connected
- [ ] Test from Apple Watch (if added later)

---

## Reporting Issues

If Siri voice is still broken after iOS update:

### Apple Feedback:
1. Go to **Feedback Assistant** app (on beta iOS)
2. Report: "Siri ProvidesDialog not speaking in App Intents"
3. Include:
   - iOS version
   - Device model
   - Cricket app as example
   - Expected: Siri speaks IntentDialog
   - Actual: Shows text only

### Quick Workaround Check:
- If Siri voice still broken, your Shortcuts workaround still works ✅
- No changes needed to Cricket app
- Just keep using "Speak Text" action

---

## Version History

| iOS/macOS Version | Siri Voice Status | Cricket Workaround Needed? | Test Date |
|-------------------|-------------------|----------------------------|-----------|
| iOS 26.0.1 beta | ❌ Broken | ✅ Yes (use Shortcuts + Speak Text) | Oct 2024 |
| macOS 26.1 (25B78) | ✅ **FIXED** | ❌ No workaround needed | Nov 4, 2025 |
| 26.x beta | 🟡 Test needed | ⏳ TBD | - |
| 26.0 final | 🟡 Test needed | ⏳ TBD | - |

---

## Quick Test Commands

Copy/paste these for easy testing:

```
# Basic Siri tests:
"Hey Siri, what time is it?"
"Hey Siri, what's the weather?"

# Cricket voice commands:
"Hey Siri, Cricket temp"
"Hey Siri, Cricket humidity"
"Hey Siri, Cricket status"

# Alternative phrases:
"Hey Siri, check Cricket temperature"
"Hey Siri, what's my temperature in Cricket?"
"Hey Siri, get local temperature with Cricket"
```

---

## Expected Timeline

Based on Apple's beta cycles:

- **iOS 26 beta** (current): Bug likely present through beta period
- **iOS 26 RC** (Release Candidate): May be fixed here
- **iOS 26.0 final** (spring 2025?): Should definitely be fixed
- **iOS 26.1** (if not fixed in 26.0): Likely fixed in first update

**Plan:** Keep your Shortcuts workaround until iOS 26 final release.

---

## Contact

If you discover the bug is fixed, update this document with:
- iOS version number where fix appeared
- Date confirmed
- Any behavior changes noted

Happy Cricket monitoring! 🦗🌡️💧
