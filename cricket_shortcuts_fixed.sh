#!/bin/sh
# Read temperature and humidity from UserDefaults
temp_field=$(defaults read wm6h.Cricket-mac currentTemperature 2>/dev/null || echo "-- °C")
hum_field=$(defaults read wm6h.Cricket-mac currentHumidity 2>/dev/null || echo "-- %")

# Extract numeric Celsius value (handles negatives and decimals)
# Remove any degree symbols and 'C' first, then extract number
temp_c=$(printf '%s' "$temp_field" | sed 's/\\260//g' | sed 's/°//g' | awk 'match($0,/[-+]?[0-9]+(\.[0-9]+)?/){print substr($0,RSTART,RLENGTH)}')

if [ -n "$temp_c" ]; then
  # Convert Celsius to Fahrenheit and round to nearest integer
  temp_f=$(echo "$temp_c" | awk '{ printf "%.0f", ($1 * 9 / 5) + 32 }')

  # Clean up Celsius text for natural reading
  temp_pretty=$(printf '%s' "$temp_field" \
    | sed -e 's/°/ degrees /' \
          -e 's/\\260/ degrees /' \
          -e 's/ C/ Celsius/')

  echo "Your hyper local temperature is $temp_pretty (${temp_f}F) and humidity is $hum_field"
else
  echo "Your local temperature is unavailable and humidity is $hum_field"
fi
