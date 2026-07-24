# Cricket Sensor Calibration

Make Arduino sensor readings match RuuviTag (trusted reference).

## Quick Start

### Step 1: Data Collection (Manual)

**Open two Cricket apps:**
- One connected to Arduino
- One connected to RuuviTag

**4 times daily (6am, noon, 6pm, midnight):**
1. Open `calibration_log.csv`
2. Add a new row with current readings:
   ```csv
   2026-02-27 18:00,21.2,,20.3,29.1,Evening reading
   ```
3. Save file

**Duration**: 7 days minimum (28 samples)

---

### Step 2: Analyze Data

After collecting data for several days:

```bash
cd ~/Desktop/Projects/Cricket/Calibration
python3 analyze_calibration.py
```

**Output:**
- Temperature offset calculation
- Humidity offset calculation (if available)
- Arduino code to update
- Data quality assessment

---

### Step 3: Apply Calibration

**Update Arduino code:**

Edit `/Users/bobh/Desktop/Projects/Arduino/Cricket_Peripheral/Cricket_Peripheral.ino`

Find line ~51:
```cpp
float tempCalibration = -1.0;
```

Replace with analyzer's recommendation:
```cpp
float tempCalibration = -1.8;  // Example from analysis
```

**Upload to Arduino and verify!**

---

## Files

- **calibration_log.csv** - Manual data collection spreadsheet
- **analyze_calibration.py** - Calculates calibration factors
- **CALIBRATION_PLAN.md** - Detailed strategy document
- **sensor_logger.py** - Future automated logger (incomplete)

---

## Current Status

**From Screenshot (2026-02-27 10:40 AM):**
- Arduino: 20.9°C
- RuuviTag: 20.1°C, 28.4%
- **Difference**: Arduino is 0.8°C too high

**Quick estimate**: Change `tempCalibration` from `-1.0` to `-1.8`

⚠️ **But**: Don't trust single reading! Collect data across temperature range first.

---

## Tips

**Sensor Placement:**
- Place Arduino and RuuviTag within 10cm of each other
- Away from heat sources, windows, direct airflow
- Same air circulation

**Data Quality:**
- Minimum: 10 samples (3 days, quick check)
- Recommended: 28 samples (7 days)
- Excellent: 56 samples (14 days)

**Temperature Range:**
- Try to capture range: 15°C - 25°C
- More range = better calibration
- If always same temp, calibration less reliable

---

## Example CSV

```csv
timestamp,arduino_temp_c,arduino_humidity,ruuvi_temp_c,ruuvi_humidity,notes
2026-02-27 06:00,19.5,,18.9,32.1,Cold morning
2026-02-27 12:00,21.8,,21.0,28.5,Warm afternoon
2026-02-27 18:00,20.3,,19.6,30.2,Cooling evening
2026-02-27 24:00,19.1,,18.4,33.5,Cold night
```

---

## Questions?

See **CALIBRATION_PLAN.md** for detailed explanation.
