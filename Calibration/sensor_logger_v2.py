#!/usr/bin/env python3
"""
Cricket Dual-Sensor Calibration Logger v2

Reads BOTH Arduino and RuuviTag data simultaneously from Cricket's UserDefaults
and logs them for calibration analysis.

Requires: Cricket code changes to write both sensors to unique UserDefaults keys.

Usage:
    python3 sensor_logger_v2.py

Setup with launchd to run 4x daily (6am, noon, 6pm, midnight).
"""

import subprocess
import json
from datetime import datetime
import os
import sys

# Paths
LOG_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(LOG_DIR, "calibration_data.jsonl")
CSV_FILE = os.path.join(LOG_DIR, "calibration_log.csv")

def read_user_defaults(domain, key):
    """Read a value from UserDefaults"""
    try:
        result = subprocess.run(
            ["defaults", "read", domain, key],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None

def parse_temp_celsius(temp_string):
    """Parse temperature string like '20.9 °C' to float"""
    if not temp_string or temp_string == "--":
        return None
    try:
        # Extract numeric part before ' °C'
        return float(temp_string.split()[0])
    except (ValueError, IndexError):
        return None

def parse_humidity(hum_string):
    """Parse humidity string like '28.4 %' to float"""
    if not hum_string or hum_string == "--":
        return None
    try:
        # Extract numeric part before ' %'
        return float(hum_string.split()[0])
    except (ValueError, IndexError):
        return None

def collect_readings():
    """Collect current readings from both sensors"""
    domain = "wm6h.Cricket-mac"

    # Read Arduino data
    arduino_temp = read_user_defaults(domain, "arduino_temperature")
    arduino_hum = read_user_defaults(domain, "arduino_humidity")
    arduino_status = read_user_defaults(domain, "arduino_status")

    # Read RuuviTag data
    ruuvi_temp = read_user_defaults(domain, "ruuvi_temperature")
    ruuvi_hum = read_user_defaults(domain, "ruuvi_humidity")
    ruuvi_status = read_user_defaults(domain, "ruuvi_status")

    # Parse values
    data = {
        "timestamp": datetime.now().isoformat(),
        "arduino": {
            "temperature_c": parse_temp_celsius(arduino_temp),
            "humidity_percent": parse_humidity(arduino_hum),
            "status": arduino_status,
            "raw_temp": arduino_temp,
            "raw_humidity": arduino_hum
        },
        "ruuvi": {
            "temperature_c": parse_temp_celsius(ruuvi_temp),
            "humidity_percent": parse_humidity(ruuvi_hum),
            "status": ruuvi_status,
            "raw_temp": ruuvi_temp,
            "raw_humidity": ruuvi_hum
        }
    }

    return data

def save_jsonl(data):
    """Append data to JSONL log file"""
    with open(LOG_FILE, 'a') as f:
        json.dump(data, f)
        f.write('\n')

def save_csv(data):
    """Append data to CSV log file"""
    import csv
    import os

    # Check if file exists to determine if we need to write header
    file_exists = os.path.exists(CSV_FILE)

    with open(CSV_FILE, 'a', newline='') as f:
        writer = csv.writer(f)

        # Write header if new file
        if not file_exists:
            writer.writerow([
                'timestamp',
                'arduino_temp_c',
                'arduino_humidity',
                'ruuvi_temp_c',
                'ruuvi_humidity',
                'temp_diff',
                'hum_diff',
                'notes'
            ])

        # Calculate differences
        arduino_temp = data['arduino']['temperature_c']
        ruuvi_temp = data['ruuvi']['temperature_c']
        arduino_hum = data['arduino']['humidity_percent']
        ruuvi_hum = data['ruuvi']['humidity_percent']

        temp_diff = None
        hum_diff = None

        if arduino_temp and ruuvi_temp:
            temp_diff = ruuvi_temp - arduino_temp

        if arduino_hum and ruuvi_hum:
            hum_diff = ruuvi_hum - arduino_hum

        # Write row
        writer.writerow([
            data['timestamp'],
            arduino_temp if arduino_temp else '',
            arduino_hum if arduino_hum else '',
            ruuvi_temp if ruuvi_temp else '',
            ruuvi_hum if ruuvi_hum else '',
            f'{temp_diff:+.2f}' if temp_diff else '',
            f'{hum_diff:+.2f}' if hum_diff else '',
            'Auto-logged'
        ])

def main():
    print("=" * 60)
    print("Cricket Dual-Sensor Calibration Logger v2")
    print("=" * 60)
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # Collect readings
    print("\nReading sensor data from UserDefaults...")
    data = collect_readings()

    # Display readings
    arduino = data['arduino']
    ruuvi = data['ruuvi']

    print(f"\nArduino:")
    print(f"  Temperature: {arduino['raw_temp']}")
    print(f"  Humidity:    {arduino['raw_humidity']}")
    print(f"  Status:      {arduino['status']}")

    print(f"\nRuuviTag:")
    print(f"  Temperature: {ruuvi['raw_temp']}")
    print(f"  Humidity:    {ruuvi['raw_humidity']}")
    print(f"  Status:      {ruuvi['status']}")

    # Check if we have valid data from both sensors
    has_arduino_temp = arduino['temperature_c'] is not None
    has_ruuvi_temp = ruuvi['temperature_c'] is not None

    if not has_arduino_temp or not has_ruuvi_temp:
        print("\n⚠️  WARNING: Missing data from one or both sensors!")
        if not has_arduino_temp:
            print("  - Arduino temperature not available")
        if not has_ruuvi_temp:
            print("  - RuuviTag temperature not available")
        print("\nMake sure both Cricket instances are running and connected.")
        sys.exit(1)

    # Calculate differences
    temp_diff = ruuvi['temperature_c'] - arduino['temperature_c']
    hum_diff = None
    if arduino['humidity_percent'] and ruuvi['humidity_percent']:
        hum_diff = ruuvi['humidity_percent'] - arduino['humidity_percent']

    print(f"\nDifferences (RuuviTag - Arduino):")
    print(f"  Temperature: {temp_diff:+.2f}°C")
    if hum_diff:
        print(f"  Humidity:    {hum_diff:+.2f}%")

    # Save to logs
    print(f"\nSaving data...")
    save_jsonl(data)
    print(f"  ✅ Saved to: {LOG_FILE}")

    save_csv(data)
    print(f"  ✅ Saved to: {CSV_FILE}")

    print(f"\n✅ Data collection complete!")

    # Count total samples
    try:
        with open(LOG_FILE, 'r') as f:
            total_samples = sum(1 for _ in f)
        print(f"\nTotal samples collected: {total_samples}")

        if total_samples >= 28:
            print("✅ Excellent! You have enough data for reliable calibration.")
            print("   Run: python3 analyze_calibration.py")
        elif total_samples >= 10:
            print("⚠️  Good progress. Collect a few more samples for better accuracy.")
        else:
            print(f"⏳ Keep collecting. Need {28 - total_samples} more for 7-day dataset.")
    except FileNotFoundError:
        pass

    print("=" * 60)

if __name__ == "__main__":
    main()
