# Cricket MCP Server Interface Specification

Derived from:
- [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino)
- [README.md](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket_Calibration/README.md)
- [CALIBRATION_PLAN.md](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket_Calibration/CALIBRATION_PLAN.md)
- [analyze_calibration.py](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket_Calibration/analyze_calibration.py)
- [sensor_logger_v2.py](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket_Calibration/sensor_logger_v2.py)

## Purpose

No formal interface requirements document exists for the Cricket Arduino peripheral. This document captures the device behavior that is already implemented and turns it into a practical contract for a future MCP server.

This is not a wish list. It is a derived specification based on the current Arduino and calibration code as of 2026-05-04.

## Executive Summary

The Cricket device is currently a BLE peripheral running on an Arduino Nano 33 BLE Sense Rev 2. It exposes one custom BLE service with two readable/notifiable float characteristics:
- temperature in degrees Celsius
- relative humidity in percent

The device samples once per second, keeps a 5-sample moving average, and only publishes updates when either:
- this is the first reading after connection, or
- temperature changes by at least 0.5 C, or
- humidity changes by at least 0.5 %RH

The future MCP server should act as a BLE central on macOS, connect to this peripheral, subscribe to notifications, maintain the latest values, and expose a small read-oriented MCP interface. The MCP server should not invent device capabilities that do not exist in the BLE firmware.

## Source-Derived Device Contract

### Hardware and Sensor Stack

- Board: Arduino Nano 33 BLE Sense Rev 2
- BLE library: `ArduinoBLE`
- Sensor library: `Arduino_HS300x`
- Environmental sensor: HS300x temperature and humidity sensor

Relevant code:
- BLE service and characteristic definitions: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:8)
- sampling and thresholds: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:16)
- calibration constants: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:49)

### BLE Identity

- Local device name: `Nano33BLE_Sensor`
- Advertised custom service UUID: `5971e8f1-bc4d-4a5f-a6fd-3591131a98c6`

Characteristic UUIDs:
- Temperature: `78b20af1-e597-40c1-a69c-304205b7e099`
- Humidity: `0ba15aa1-a805-4205-bc82-af2e4a9364c5`

Characteristic properties:
- `BLERead`
- `BLENotify`

There are no write characteristics and no BLE control channel implemented in the current firmware.

Relevant code:
- [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:8)
- [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:124)

### Measurement Semantics

The values exposed over BLE are not raw sensor values. They are processed values:

1. A raw HS300x reading is taken every 1000 ms.
2. Calibration offsets are applied.
3. Invalid values are rejected.
4. Valid readings are stored in a 5-sample ring buffer.
5. A moving average is calculated from the currently accumulated samples.
6. Temperature average is rounded to one decimal place before transmission.
7. Humidity average is not explicitly rounded before transmission.
8. BLE notifications are emitted only when thresholds are crossed or on first reading after connection.

Relevant code:
- sample interval: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:17)
- averaging window: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:18)
- threshold logic: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:19)
- acquisition and averaging: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:251)
- transmit path: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:295)

### Calibration Semantics

Current firmware calibration constants:
- `tempCalibration = -1.0`
- `humidityCalibration = 2.0`

However, the collected calibration analysis currently recommends:
- temperature offset: `+0.00 C`
- humidity offset: `+2.00 %`

This means the humidity offset in the sketch aligns with the collected data, but the temperature offset in the sketch appears stale relative to the calibration dataset.

Relevant code and analysis:
- current constants: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:51)
- analyzer median-based recommendation: [analyze_calibration.py](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket_Calibration/analyze_calibration.py:97)

Observed analysis result from `calibration_log.csv`:
- 32 temperature samples
- mean temperature delta: `-0.03 C`
- median temperature delta: `+0.00 C`
- 31 humidity samples
- median humidity delta: `+2.00 %`

## Error and Edge Behavior

### Sensor Initialization Failure

If the HS300x sensor fails to initialize:
- BLE still starts
- the service and characteristics are still advertised
- the initial characteristic values remain `0.0`
- no valid readings are accumulated

This matters for the MCP server because a successful BLE connection does not guarantee valid environmental data.

Relevant code:
- sensor init retry and failure path: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:96)
- initial values written to BLE characteristics: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:130)

### Reading Validation

The firmware rejects readings if:
- temperature or humidity is `NaN`
- temperature or humidity is infinite
- temperature is outside `-40.0` to `120.0` C
- humidity is outside `0.0` to `100.0` %

When a reading is rejected, the last valid rolling buffer is retained. The peripheral does not publish a separate explicit error state over BLE.

Relevant code:
- [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:261)

### Connection Model

The firmware stops advertising when connected and resumes advertising on disconnect.

Implication:
- the design appears intended for one central connection at a time
- the MCP server should assume exclusive access to the peripheral while connected

Relevant code:
- connect handling: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:168)
- disconnect handling: [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino:176)

## BLE-to-MCP Translation Requirements

The future MCP server should expose the BLE peripheral as a stable software interface, not as raw CoreBluetooth events.

### Core Responsibilities

The MCP server should:
- scan for a peripheral advertising service `5971e8f1-bc4d-4a5f-a6fd-3591131a98c6`
- prefer the device with local name `Nano33BLE_Sensor`
- connect as BLE central
- discover the service and both characteristics
- read initial characteristic values after connection
- subscribe to notifications on both characteristics
- cache the latest known values and timestamps
- surface connection state and staleness to MCP clients

### Values the MCP Layer Must Preserve

The MCP server should preserve these semantics from the device:
- values are already calibrated by firmware
- values are already smoothed by a 5-sample moving average
- updates are event-driven by threshold crossing, not guaranteed every second

The MCP server should not:
- apply a second calibration layer by default
- infer that lack of notifications means failure
- claim values are raw sensor measurements

## Proposed MCP Interface

The current firmware is read-only from the BLE side, so the first MCP server should also be read-only except for connection management.

### Tool 1: `discover_cricket_devices`

Purpose:
- scan for compatible Cricket peripherals

Inputs:
- `timeout_seconds` optional, default `5`

Output:
- array of discovered devices with:
  - `device_id`
  - `name`
  - `rssi`
  - `service_uuids`
  - `is_connectable`
  - `last_seen_at`

Notes:
- `device_id` should be the stable identifier used internally by CoreBluetooth if available

### Tool 2: `connect_cricket_device`

Purpose:
- connect the MCP server to one discovered Cricket peripheral and begin monitoring

Inputs:
- `device_id` required

Output:
- `connected`
- `device_id`
- `name`
- `service_uuid`
- `temperature_characteristic_uuid`
- `humidity_characteristic_uuid`
- `subscribed`
- `connected_at`

Notes:
- this tool should fail clearly if the service or expected characteristics are missing

### Tool 3: `get_cricket_reading`

Purpose:
- return the latest known environmental reading and metadata

Inputs:
- none, or optional `device_id` if multi-device support is added later

Output:
```json
{
  "device_id": "string",
  "name": "Nano33BLE_Sensor",
  "connected": true,
  "reading": {
    "temperature_c": 18.4,
    "humidity_percent": 29.3,
    "observed_at": "2026-05-04T14:12:10-05:00",
    "age_seconds": 12.4,
    "source": "ble_notification"
  },
  "metadata": {
    "service_uuid": "5971e8f1-bc4d-4a5f-a6fd-3591131a98c6",
    "temperature_characteristic_uuid": "78b20af1-e597-40c1-a69c-304205b7e099",
    "humidity_characteristic_uuid": "0ba15aa1-a805-4205-bc82-af2e4a9364c5",
    "units": {
      "temperature": "C",
      "humidity": "percent_rh"
    },
    "firmware_processing": {
      "sample_interval_ms": 1000,
      "average_window_samples": 5,
      "temperature_threshold_c": 0.5,
      "humidity_threshold_percent": 0.5,
      "temperature_is_rounded_to_0_1_c": true
    }
  }
}
```

Notes:
- `observed_at` must represent when the MCP server received or refreshed the value, not when the sensor physically sampled the air
- `age_seconds` is important because the firmware is threshold-driven and may legitimately stay silent

### Tool 4: `get_cricket_status`

Purpose:
- expose transport and data-health details that are not part of the environmental reading itself

Output:
- `connected`
- `scanning`
- `subscribed`
- `last_temperature_update_at`
- `last_humidity_update_at`
- `temperature_age_seconds`
- `humidity_age_seconds`
- `stale`
- `stale_threshold_seconds`
- `last_error`

Recommended stale policy:
- warning if no update for more than 180 seconds
- error if disconnected

The 180-second recommendation matches the calibration logger freshness check currently used for application-side monitoring.

Relevant code:
- freshness concept in logger: [sensor_logger_v2.py](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket_Calibration/sensor_logger_v2.py:86)

### Tool 5: `disconnect_cricket_device`

Purpose:
- disconnect cleanly and stop notifications

Inputs:
- `device_id` optional if only one connection is supported

Output:
- `disconnected`
- `device_id`
- `disconnected_at`

## Explicit Non-Requirements for Version 1

The current Arduino implementation does not support these features, so the first MCP server should not pretend to offer them:
- changing calibration constants over BLE
- changing sample interval over BLE
- requesting raw unsmoothed readings
- retrieving firmware version
- retrieving battery level
- pushing historical logs from device memory
- commanding LEDs or device state

If these are needed later, they should be added to the Arduino BLE interface first, then reflected in the MCP layer.

## Recommended MCP Response Model

For a server meant to support local automation and LLM use, each successful reading response should include:
- numeric values, not display strings
- explicit units
- timestamps
- connection state
- staleness
- enough metadata to explain why updates are not continuous

Avoid returning only human-formatted strings like:
- `18.4 C`
- `29.3 %`

Those are fine for UI but weaker for automation.

## Swift/macOS Implementation Guidance

Given the stated preference for Swift and macOS frameworks, the natural stack is:
- `Foundation`
- `CoreBluetooth`

Recommended internal architecture:
- one BLE manager responsible for scan/connect/discovery/subscription
- one cached `CricketReading` model
- one MCP transport layer responsible for `stdin`/`stdout`
- a thin tool layer mapping MCP tool calls onto the BLE manager

Suggested internal model:

```swift
struct CricketReading: Codable {
    let deviceID: String
    let name: String
    let temperatureC: Float?
    let humidityPercent: Float?
    let observedAt: Date?
    let connected: Bool
    let stale: Bool
    let lastError: String?
}
```

Important implementation note:
- CoreBluetooth is asynchronous and event-driven
- MCP tool calls are request/response oriented

The server therefore needs a small state machine and cache. `get_cricket_reading` should usually return the latest cached value rather than block indefinitely waiting for a fresh notification.

## Open Questions

These questions are unresolved by the current codebase and should be decided before writing the production MCP server:

1. Should the MCP server support exactly one Cricket peripheral or multiple?
2. What staleness threshold should count as unacceptable for automation: 180 seconds, 600 seconds, or user-configurable?
3. Should connection happen explicitly via a tool, or implicitly on first read?
4. Should the MCP server expose only the calibrated BLE values, or also optionally compute a host-side diagnostic layer?
5. Should the Arduino firmware be updated to correct `tempCalibration` from `-1.0` to `0.0` before the MCP server is treated as authoritative?

## Minimum Acceptance Criteria for MCP Server v1

The MCP server is acceptable for first use when it can:
- discover the Cricket peripheral by service UUID
- connect reliably on macOS
- read both characteristics
- subscribe to notifications
- return the latest temperature and humidity with timestamps
- report stale or disconnected state clearly
- avoid inventing unsupported device controls

## Change Control

This document should be updated whenever any of the following change:
- BLE UUIDs
- device name
- calibration ownership model
- sampling interval
- averaging window
- threshold behavior
- additional BLE characteristics
- MCP tool names or response schemas
