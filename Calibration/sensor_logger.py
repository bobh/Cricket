#!/usr/bin/env python3
"""
Cricket Sensor Calibration Logger

Reads values from both Arduino and RuuviTag sensors via Cricket's UserDefaults
and logs them for calibration analysis.

Run 4 times daily via launchd to collect calibration data over time.
"""

import subprocess
import json
from datetime import datetime
import os
import sys

# Paths
LOG_DIR = os.path.expanduser("~/Desktop/Projects/Cricket/Calibration")
LOG_FILE = os.path.join(LOG_DIR, "calibration_data.jsonl")

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

    # Note: Cricket stores values in standard UserDefaults
    # when the sensor is active (isActiveSource = true)

    # Read current values (these come from whichever sensor is active)
    temp = read_user_defaults("wm6h.Cricket-mac", "currentTemperature")
    humidity = read_user_defaults("wm6h.Cricket-mac", "currentHumidity")
    status = read_user_defaults("wm6h.Cricket-mac", "connectionStatus")

    # Parse values
    temp_c = parse_temp_celsius(temp)
    hum = parse_humidity(humidity)

    # Determine which sensor is active by status message
    sensor_type = None
    if status and "Arduino" in status:
        sensor_type = "Arduino"
    elif status and "Ruuvi" in status:
        sensor_type = "RuuviTag"

    return {
        "timestamp": datetime.now().isoformat(),
        "sensor_type": sensor_type,
        "temperature_c": temp_c,
        "humidity_percent": hum,
        "status": status,
        "raw_temp": temp,
        "raw_humidity": humidity
    }

def main():
    print("=== Cricket Sensor Calibration Logger ===")
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # Ensure log directory exists
    os.makedirs(LOG_DIR, exist_ok=True)

    # Note: User must run two instances of Cricket
    # One connected to Arduino, one to RuuviTag
    # This script needs to be modified to read from both

    print("\nERROR: This script needs access to BOTH sensor readings simultaneously.")
    print("Cricket currently only exposes one active sensor at a time in UserDefaults.")
    print("\nSolution: We need a different approach.")
    print("See: sensor_logger_v2.py for the correct implementation.")

    sys.exit(1)

if __name__ == "__main__":
    main()
