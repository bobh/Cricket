#!/usr/bin/env python3
"""
Cricket Calibration Analyzer

Analyzes collected sensor data and calculates calibration factors
to make Arduino match RuuviTag (trusted reference).

Usage:
    python3 analyze_calibration.py
"""

import csv
import statistics
from datetime import datetime
import os

# Paths
CALIBRATION_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(CALIBRATION_DIR, "calibration_log.csv")
ARDUINO_FILE = "/Users/bobh/Desktop/Projects/Arduino/Cricket_Peripheral/Cricket_Peripheral.ino"

def read_calibration_data():
    """Read calibration log CSV"""
    data = []

    with open(LOG_FILE, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Skip rows with missing critical data
            if not row['arduino_temp_c'] or not row['ruuvi_temp_c']:
                continue

            try:
                entry = {
                    'timestamp': row['timestamp'],
                    'arduino_temp': float(row['arduino_temp_c']),
                    'ruuvi_temp': float(row['ruuvi_temp_c']),
                    'temp_diff': None,  # Will calculate
                    'arduino_hum': float(row['arduino_humidity']) if row['arduino_humidity'] else None,
                    'ruuvi_hum': float(row['ruuvi_humidity']) if row['ruuvi_humidity'] else None,
                    'hum_diff': None,  # Will calculate
                    'notes': row.get('notes', '')
                }

                # Calculate differences (RuuviTag - Arduino)
                entry['temp_diff'] = entry['ruuvi_temp'] - entry['arduino_temp']

                if entry['arduino_hum'] and entry['ruuvi_hum']:
                    entry['hum_diff'] = entry['ruuvi_hum'] - entry['arduino_hum']

                data.append(entry)
            except ValueError as e:
                print(f"Warning: Skipping malformed row: {e}")
                continue

    return data

def analyze_temperature(data):
    """Analyze temperature calibration"""
    print("\n" + "="*60)
    print("TEMPERATURE CALIBRATION ANALYSIS")
    print("="*60)

    if not data:
        print("ERROR: No data to analyze!")
        return None

    # Extract temperature differences
    temp_diffs = [entry['temp_diff'] for entry in data]
    arduino_temps = [entry['arduino_temp'] for entry in data]
    ruuvi_temps = [entry['ruuvi_temp'] for entry in data]

    # Statistics
    mean_diff = statistics.mean(temp_diffs)
    median_diff = statistics.median(temp_diffs)
    stdev_diff = statistics.stdev(temp_diffs) if len(temp_diffs) > 1 else 0
    min_diff = min(temp_diffs)
    max_diff = max(temp_diffs)

    print(f"\nData Points: {len(data)}")
    print(f"Temperature Range:")
    print(f"  Arduino: {min(arduino_temps):.1f}°C - {max(arduino_temps):.1f}°C")
    print(f"  RuuviTag: {min(ruuvi_temps):.1f}°C - {max(ruuvi_temps):.1f}°C")

    print(f"\nDifference (RuuviTag - Arduino):")
    print(f"  Mean:   {mean_diff:+.2f}°C")
    print(f"  Median: {median_diff:+.2f}°C")
    print(f"  StdDev: {stdev_diff:.2f}°C")
    print(f"  Min:    {min_diff:+.2f}°C")
    print(f"  Max:    {max_diff:+.2f}°C")

    # Calibration recommendation
    print(f"\n{'─'*60}")
    print("RECOMMENDED TEMPERATURE CALIBRATION:")
    print(f"{'─'*60}")

    # Use median (more robust to outliers than mean)
    recommended_offset = median_diff

    print(f"\nArduino offset: {recommended_offset:+.2f}°C")
    print(f"\nArduino code (line ~51 in Cricket_Peripheral.ino):")
    print(f"  OLD: float tempCalibration = -1.0;")
    print(f"  NEW: float tempCalibration = {recommended_offset:.2f};")

    # Check if offset is consistent (low variance = simple offset works)
    if stdev_diff < 0.5:
        print(f"\n✅ GOOD: Low variance ({stdev_diff:.2f}°C) - simple offset calibration works!")
    elif stdev_diff < 1.0:
        print(f"\n⚠️  FAIR: Moderate variance ({stdev_diff:.2f}°C) - consider temperature-dependent calibration")
    else:
        print(f"\n❌ POOR: High variance ({stdev_diff:.2f}°C) - may need linear calibration or sensor issue")

    # Check if we have enough temperature range for linear calibration
    temp_range = max(arduino_temps) - min(arduino_temps)
    if temp_range < 3.0:
        print(f"\n⚠️  Temperature range ({temp_range:.1f}°C) is narrow - collect data across wider range")

    return recommended_offset

def analyze_humidity(data):
    """Analyze humidity calibration"""
    print("\n" + "="*60)
    print("HUMIDITY CALIBRATION ANALYSIS")
    print("="*60)

    # Filter entries with humidity data
    hum_data = [entry for entry in data if entry['hum_diff'] is not None]

    if not hum_data:
        print("\nNo humidity data collected.")
        print("Check if Arduino humidity sensor is working.")
        return None

    # Extract humidity differences
    hum_diffs = [entry['hum_diff'] for entry in hum_data]
    arduino_hums = [entry['arduino_hum'] for entry in hum_data]
    ruuvi_hums = [entry['ruuvi_hum'] for entry in hum_data]

    # Statistics
    mean_diff = statistics.mean(hum_diffs)
    median_diff = statistics.median(hum_diffs)
    stdev_diff = statistics.stdev(hum_diffs) if len(hum_diffs) > 1 else 0

    print(f"\nData Points: {len(hum_data)}")
    print(f"Humidity Range:")
    print(f"  Arduino: {min(arduino_hums):.1f}% - {max(arduino_hums):.1f}%")
    print(f"  RuuviTag: {min(ruuvi_hums):.1f}% - {max(ruuvi_hums):.1f}%")

    print(f"\nDifference (RuuviTag - Arduino):")
    print(f"  Mean:   {mean_diff:+.2f}%")
    print(f"  Median: {median_diff:+.2f}%")
    print(f"  StdDev: {stdev_diff:.2f}%")

    # Calibration recommendation
    print(f"\n{'─'*60}")
    print("RECOMMENDED HUMIDITY CALIBRATION:")
    print(f"{'─'*60}")

    recommended_offset = median_diff

    print(f"\nArduino humidity offset: {recommended_offset:+.2f}%")
    print(f"\nAdd to Cricket_Peripheral.ino (after line ~51):")
    print(f"  float humidityCalibration = {recommended_offset:.2f};")
    print(f"\nIn takeSensorReading() function (line ~247):")
    print(f"  OLD: humidity = HS300x.readHumidity();")
    print(f"  NEW: humidity = HS300x.readHumidity() + humidityCalibration;")

    return recommended_offset

def show_data_points(data):
    """Show individual data points"""
    print("\n" + "="*60)
    print("INDIVIDUAL DATA POINTS")
    print("="*60)
    print(f"\n{'Timestamp':<20} {'Arduino':<10} {'RuuviTag':<10} {'Diff':<8}")
    print(f"{'─'*20} {'─'*10} {'─'*10} {'─'*8}")

    for entry in data:
        timestamp = entry['timestamp'][:16]  # Truncate for display
        arduino = f"{entry['arduino_temp']:.1f}°C"
        ruuvi = f"{entry['ruuvi_temp']:.1f}°C"
        diff = f"{entry['temp_diff']:+.1f}°C"
        print(f"{timestamp:<20} {arduino:<10} {ruuvi:<10} {diff:<8}")

def main():
    print("="*60)
    print("Cricket Sensor Calibration Analyzer")
    print("="*60)

    # Check if log file exists
    if not os.path.exists(LOG_FILE):
        print(f"\nERROR: Calibration log not found at:")
        print(f"  {LOG_FILE}")
        print(f"\nCreate the file and add data points first.")
        return

    # Read data
    print(f"\nReading calibration data from:")
    print(f"  {LOG_FILE}")

    data = read_calibration_data()

    if not data:
        print(f"\nERROR: No valid data points found in log file.")
        print(f"Check the CSV format and ensure data is complete.")
        return

    # Show all data points
    show_data_points(data)

    # Analyze temperature
    temp_offset = analyze_temperature(data)

    # Analyze humidity
    hum_offset = analyze_humidity(data)

    # Summary
    print("\n" + "="*60)
    print("CALIBRATION SUMMARY")
    print("="*60)

    print(f"\nData Collection:")
    print(f"  Samples: {len(data)}")

    if len(data) < 10:
        print(f"  ⚠️  Recommendation: Collect at least 10 samples for reliable calibration")
    elif len(data) < 20:
        print(f"  ✅ Good: {len(data)} samples collected")
    else:
        print(f"  ✅ Excellent: {len(data)} samples - very reliable calibration")

    print(f"\nCalibration Values:")
    if temp_offset is not None:
        print(f"  Temperature: {temp_offset:+.2f}°C")
    if hum_offset is not None:
        print(f"  Humidity: {hum_offset:+.2f}%")

    print(f"\nNext Steps:")
    print(f"  1. Update Arduino code with calibration values")
    print(f"  2. Upload to Arduino")
    print(f"  3. Verify readings match RuuviTag")
    print(f"  4. Collect a few more samples to confirm")

    print("\n" + "="*60)

if __name__ == "__main__":
    main()
