# Automated Logger Setup Complete

## ✅ Status

The launchd job is configured to run **4 times daily**:
- 6:00 AM
- 12:00 PM (Noon)
- 6:00 PM
- 12:00 AM (Midnight)

## 🔐 Final Step: Grant Full Disk Access

macOS security is blocking launchd from running the logger. You need to grant Full Disk Access to bash:

### Steps:

1. **Open System Settings**
2. Go to **Privacy & Security** → **Full Disk Access**
3. Click the **lock icon** (bottom left) to make changes
4. Click the **+** button
5. Press **⌘⇧G** (Command-Shift-G) to "Go to Folder"
6. Type: `/bin/bash`
7. Click **Open**
8. Make sure the checkbox next to **bash** is **enabled** ✓

### Alternative: Grant to Python3

If you prefer to grant access to Python instead:
1. In step 6 above, type: `/usr/bin/python3`
2. Click Open and enable

## 🧪 Test After Granting Permission

Run this command to test:
```bash
launchctl start com.cricket.calibration.logger && sleep 3 && tail -5 ~/Documents/Cricket_Calibration/calibration_log.csv
```

You should see a new data entry with the current timestamp.

## 📂 File Locations

- **Data Files**: `~/Documents/Cricket_Calibration/`
- **Log Files**:
  - Output: `~/Documents/Cricket_Calibration/logger_output.log`
  - Errors: `~/Documents/Cricket_Calibration/logger_error.log`
- **launchd Config**: `~/Library/LaunchAgents/com.cricket.calibration.logger.plist`

## 🔍 Verify It's Running

Check if the job is loaded:
```bash
launchctl list | grep cricket
```

Should show: `-	0	com.cricket.calibration.logger`

## 📊 View Collected Data

```bash
cat ~/Documents/Cricket_Calibration/calibration_log.csv
```

## 🛑 Stop Automatic Logging

If you need to stop it:
```bash
launchctl unload ~/Library/LaunchAgents/com.cricket.calibration.logger.plist
```

## 🚀 Restart Automatic Logging

To restart:
```bash
launchctl load ~/Library/LaunchAgents/com.cricket.calibration.logger.plist
```

## ⚠️ Important Reminders

1. **Keep both Cricket apps running** (Arduino + RuuviTag)
2. **Keep MacBook Air on** (lid can be closed)
3. **Check once daily** that both sensors are still connected
4. **Run for 7 days** (28 samples minimum)
5. **Temperature range**: You'll get great data across 0-10°C (32-50°F)!

## 📈 After 7 Days

Run the analyzer:
```bash
cd ~/Documents/Cricket_Calibration
python3 analyze_calibration.py
```

This will calculate the optimal calibration offset for your Arduino sensor.
