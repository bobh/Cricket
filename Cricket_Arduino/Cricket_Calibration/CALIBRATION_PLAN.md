# Cricket Sensor Calibration System

## Problem Statement

**Current Readings:**
- Arduino: 20.9°C
- RuuviTag: 20.1°C (trusted reference)
- **Difference**: Arduino reads 0.8°C too high

**Goal**: Calibrate Arduino to match RuuviTag over various temperature/humidity conditions.

---

## Challenge

Cricket currently only exposes the **active sensor** to UserDefaults, making it impossible to log both sensors simultaneously with the current architecture.

---

## Solution: Multi-Sensor Data Export

### Option A: Modify Cricket (Recommended)
**Modify both ViewModels to always write data, not just when active**

This allows simultaneous logging of both sensors.

**Changes Required:**
1. Remove `isActiveSource` check from `saveValues()` in both ViewModels
2. Use unique UserDefaults keys for each sensor:
   - Arduino: `arduino_temperature`, `arduino_humidity`
   - RuuviTag: `ruuvi_temperature`, `ruuvi_humidity`

**Benefit**: Logger can read both sensors simultaneously
**Effort**: 30 minutes coding + testing
**Risk**: Low

---

### Option B: Manual Logging (Immediate)
**Simple spreadsheet-based approach**

**Steps:**
1. Open both Cricket instances (one Arduino, one RuuviTag)
2. 4 times daily (e.g., 6am, noon, 6pm, midnight):
   - Record Arduino temp/humidity
   - Record RuuviTag temp/humidity
   - Note timestamp
3. After 1-2 weeks, analyze data
4. Calculate calibration offsets

**Benefit**: Works immediately, no code changes
**Effort**: Manual recording (5 min, 4x daily)
**Risk**: None

---

### Option C: UI Scraping (Advanced)
**Use AppleScript to read values from Cricket windows**

Extract displayed values programmatically from both windows.

**Benefit**: No Cricket modifications needed
**Effort**: 2-3 hours (AppleScript development)
**Risk**: Fragile (breaks if UI changes)

---

## Recommended Approach

**Phase 1: Quick Start (Manual - Today)**
- Use Option B (spreadsheet) to start collecting data immediately
- Template provided below

**Phase 2: Automate (Next Session)**
- Implement Option A (modify Cricket)
- Deploy automated logger
- Continue collecting data

---

## Phase 1: Manual Calibration Log

### Spreadsheet Template

Create: `~/Desktop/Projects/Cricket/Calibration/calibration_log.csv`

```csv
timestamp,arduino_temp_c,arduino_humidity,ruuvi_temp_c,ruuvi_humidity,notes
2026-02-27 10:40,20.9,,20.1,28.4,Initial reading
```

### Collection Schedule
- **6:00 AM** - Morning (cold)
- **12:00 PM** - Midday (warm)
- **6:00 PM** - Evening (cooling)
- **12:00 AM** - Night (cold)

### Duration
- **Minimum**: 3 days (12 samples)
- **Recommended**: 7 days (28 samples)
- **Ideal**: 14 days (56 samples)

---

## Analysis: Calibration Formula

After collecting data, we'll calculate:

### Linear Calibration
```
Arduino_calibrated = Arduino_raw + offset
```

### Temperature Offset
```
offset = average(RuuviTag_temp - Arduino_temp)
```

### Humidity Offset (if Arduino has humidity sensor)
```
humidity_offset = average(RuuviTag_humidity - Arduino_humidity)
```

### Advanced: Temperature-Dependent Calibration
If offset varies with temperature:
```
offset = m * Arduino_temp + b
```
(Linear regression on collected data)

---

## Current Arduino Calibration

**Location**: `/Users/bobh/Desktop/Projects/Arduino/Cricket_Peripheral/Cricket_Peripheral.ino`

**Current Value:**
```cpp
float tempCalibration = -1.0;  // Line 51
```

**Current Status:**
- Arduino: 20.9°C
- With -1.0°C offset, raw sensor probably reads: ~21.9°C
- RuuviTag: 20.1°C
- **Needed adjustment**: Additional -0.8°C (total offset should be -1.8°C)

**Quick Fix (If offset is constant):**
```cpp
float tempCalibration = -1.8;  // Adjusted to match RuuviTag
```

⚠️ **However**, single-point calibration is risky. Better to collect data across temperature range.

---

## Phase 2: Automated Logger (Future)

Once we modify Cricket to expose both sensors simultaneously:

### sensor_logger.py
- Reads both Arduino and RuuviTag from UserDefaults
- Logs to JSONL file with timestamps
- Runs automatically 4x daily via launchd

### calibration_analyzer.py
- Reads collected data
- Calculates optimal offset (or linear formula)
- Generates Arduino code snippet
- Produces visualization plots

### launchd Configuration
- Runs at 6am, 12pm, 6pm, 12am daily
- Logs to file automatically
- No user interaction needed

---

## Humidity Calibration

**Note**: Screenshot doesn't show Arduino humidity reading.

**Questions:**
1. Does Arduino have humidity sensor working?
2. If yes, what is current Arduino humidity reading?
3. Is there a humidity calibration constant in Arduino code?

**Arduino Code Check:**
```cpp
// Line 51: Temperature calibration exists
float tempCalibration = -1.0;

// Humidity calibration?
// TODO: Check if humidityCalibration variable exists
```

If no humidity calibration exists, we can add:
```cpp
float humidityCalibration = 0.0;  // To be determined from data

// In takeSensorReading():
humidity = HS300x.readHumidity() + humidityCalibration;
```

---

## Expected Results

### After Calibration:
- Arduino and RuuviTag should read within ±0.3°C
- Humidity within ±2%
- Consistent across temperature ranges (15°C - 25°C)

### Calibration Accuracy:
- **Excellent**: Difference < 0.2°C
- **Good**: Difference < 0.5°C
- **Acceptable**: Difference < 1.0°C
- **Poor**: Difference > 1.0°C (may indicate sensor issue)

---

## Next Steps

### Immediate (Today):
1. ✅ Create calibration log spreadsheet
2. ✅ Set 4 daily reminders (6am, noon, 6pm, midnight)
3. ✅ Record first data point
4. ✅ Check Arduino humidity reading

### This Week:
1. Collect data for 7 days (28 samples minimum)
2. Keep both Cricket instances running
3. Place sensors in same location (avoid temperature gradients)

### Next Session:
1. Analyze collected data
2. Calculate calibration factors
3. Update Arduino code
4. Verify calibration accuracy

---

## Questions to Answer

Before starting data collection:

1. **Sensor Placement**: Are Arduino and RuuviTag in the same location?
   - Should be within 10cm of each other
   - Away from heat sources, windows, direct airflow

2. **Arduino Humidity**: Does Arduino show humidity? What's the current reading?

3. **Collection Method**: Manual spreadsheet or wait for automated solution?

4. **Duration**: 3 days (quick), 7 days (recommended), or 14 days (thorough)?

---

## Files Created

- `CALIBRATION_PLAN.md` (this file) - Strategy document
- `sensor_logger.py` (incomplete) - Future automated logger
- `calibration_log.csv` (to create) - Manual data collection

---

**Status**: Plan ready, awaiting user decision on collection method and duration.
