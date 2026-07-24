# Cricket MCP Server Python Design

Based on:
- [Cricket_MCP_Server_Interface.md](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket_MCP_Server_Interface.md)
- [Cricket_MCP_Server_Swift_Design.md](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket_MCP_Server_Swift_Design.md)
- [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino)

## Goal

Design a minimal Python MCP server for macOS that:
- runs as a local process
- communicates with the MCP client over `stdio`
- acts as a BLE central
- connects to the Cricket Arduino peripheral
- exposes the exact same tool names and JSON schemas already defined in the interface spec

This is a design document, not a full implementation.

## Version 1 Scope

Version 1 supports:
- device discovery
- explicit connect
- cached reading retrieval
- status retrieval
- explicit disconnect

Version 1 does not support:
- multiple simultaneous Cricket connections
- host-side recalibration
- firmware writes
- BLE writes of any kind
- historical device log retrieval

## Recommended Python Stack

- Python 3.10+
- `mcp` Python SDK
- `bleak`
- `asyncio`
- `dataclasses`
- `typing`

Suggested installs:

```bash
pip install mcp bleak
```

## Design Decisions

### MCP Transport

Use the Python MCP SDK over `stdio`.

Reason:
- this matches the MCP tutorial path you are already using
- local MCP clients commonly expect subprocess + `stdio`
- it avoids inventing a custom server transport

### BLE Library

Use `bleak` as the BLE client layer.

Reason:
- it is the standard cross-platform Python BLE choice
- it is suitable for scan/connect/read/notify workflows
- it avoids writing macOS BLE bindings directly

### Connection Model

Support exactly one active Cricket connection in v1.

Reason:
- the Arduino firmware behaves like a single-central peripheral
- it keeps the state machine simple
- it matches the current interface assumptions

### Read Semantics

`get_cricket_reading` returns the latest cached values immediately.

It does not wait for a fresh BLE notification because:
- device notifications are threshold-driven
- tool calls should remain responsive
- no guarantee exists that a new update will arrive soon

### Staleness Policy

Use:
- `180` seconds as warning threshold
- disconnected state as hard failure

The threshold should be a server constant in v1.

## Runtime Architecture

### Process Layout

```text
MCP client
  ↕ JSON-RPC over stdio
Python Cricket MCP Server
  ↕ tool layer
CricketBLEManager
  ↕ bleak
Arduino Nano 33 BLE Sense Rev 2
```

### Suggested Project Layout

```text
cricket_mcp_server/
  pyproject.toml
  README.md
  cricket_mcp_server/
    __init__.py
    main.py
    server.py
    ble_manager.py
    models.py
    tool_schemas.py
    tools.py
    constants.py
```

### Core Components

`server.py`
- creates the MCP server
- registers tools
- binds tool handlers
- starts the `stdio` server loop

`ble_manager.py`
- owns scan/connect/disconnect behavior
- owns notification handlers
- caches latest readings
- computes staleness and status snapshots

`models.py`
- dataclasses for device summaries, readings, status, and tool results

`constants.py`
- BLE UUIDs
- device name
- firmware metadata constants
- stale threshold

## BLE Constants

These constants must match the current firmware:

```python
DEVICE_NAME = "Nano33BLE_Sensor"
SERVICE_UUID = "5971e8f1-bc4d-4a5f-a6fd-3591131a98c6"
TEMPERATURE_UUID = "78b20af1-e597-40c1-a69c-304205b7e099"
HUMIDITY_UUID = "0ba15aa1-a805-4205-bc82-af2e4a9364c5"

SAMPLE_INTERVAL_MS = 1000
AVERAGE_WINDOW_SAMPLES = 5
TEMPERATURE_THRESHOLD_C = 0.5
HUMIDITY_THRESHOLD_PERCENT = 0.5
TEMPERATURE_IS_ROUNDED_TO_0_1_C = True
STALE_THRESHOLD_SECONDS = 180
```

## State Model

### Connection State

```python
from enum import Enum

class ConnectionState(str, Enum):
    IDLE = "idle"
    SCANNING = "scanning"
    CONNECTING = "connecting"
    CONNECTED = "connected"
    DISCONNECTING = "disconnecting"
    FAILED = "failed"
```

### Reading Snapshot

```python
from dataclasses import dataclass
from datetime import datetime

@dataclass
class CricketReadingSnapshot:
    device_id: str
    name: str
    connected: bool
    temperature_c: float | None
    humidity_percent: float | None
    observed_at: datetime | None
    source: str | None
```

### Status Snapshot

```python
@dataclass
class CricketStatusSnapshot:
    connected: bool
    scanning: bool
    subscribed: bool
    last_temperature_update_at: datetime | None
    last_humidity_update_at: datetime | None
    temperature_age_seconds: float | None
    humidity_age_seconds: float | None
    stale: bool
    stale_threshold_seconds: int
    last_error: str | None
```

## Exact Tool Definitions

These tools intentionally keep the same names and schemas as the interface spec.

### Tool 1: `discover_cricket_devices`

Description:
- Scan for BLE peripherals advertising the Cricket service UUID and return matching devices.

Input schema:

```json
{
  "type": "object",
  "properties": {
    "timeout_seconds": {
      "type": "integer",
      "minimum": 1,
      "maximum": 30,
      "default": 5
    }
  },
  "additionalProperties": false
}
```

Output schema:

```json
{
  "type": "object",
  "properties": {
    "devices": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "device_id": { "type": "string" },
          "name": { "type": ["string", "null"] },
          "rssi": { "type": ["integer", "null"] },
          "service_uuids": {
            "type": "array",
            "items": { "type": "string" }
          },
          "is_connectable": { "type": ["boolean", "null"] },
          "last_seen_at": { "type": "string", "format": "date-time" }
        },
        "required": [
          "device_id",
          "name",
          "rssi",
          "service_uuids",
          "is_connectable",
          "last_seen_at"
        ],
        "additionalProperties": false
      }
    }
  },
  "required": ["devices"],
  "additionalProperties": false
}
```

Python args model:

```python
from dataclasses import dataclass

@dataclass
class DiscoverCricketDevicesArgs:
    timeout_seconds: int | None = None
```

### Tool 2: `connect_cricket_device`

Description:
- Connect to a discovered Cricket device and begin characteristic monitoring.

Input schema:

```json
{
  "type": "object",
  "properties": {
    "device_id": { "type": "string" }
  },
  "required": ["device_id"],
  "additionalProperties": false
}
```

Output schema:

```json
{
  "type": "object",
  "properties": {
    "connected": { "type": "boolean" },
    "device_id": { "type": "string" },
    "name": { "type": ["string", "null"] },
    "service_uuid": { "type": "string" },
    "temperature_characteristic_uuid": { "type": "string" },
    "humidity_characteristic_uuid": { "type": "string" },
    "subscribed": { "type": "boolean" },
    "connected_at": { "type": "string", "format": "date-time" }
  },
  "required": [
    "connected",
    "device_id",
    "name",
    "service_uuid",
    "temperature_characteristic_uuid",
    "humidity_characteristic_uuid",
    "subscribed",
    "connected_at"
  ],
  "additionalProperties": false
}
```

Python args model:

```python
@dataclass
class ConnectCricketDeviceArgs:
    device_id: str
```

### Tool 3: `get_cricket_reading`

Description:
- Return the latest cached environmental reading and firmware-processing metadata.

Input schema:

```json
{
  "type": "object",
  "properties": {},
  "additionalProperties": false
}
```

Output schema:

```json
{
  "type": "object",
  "properties": {
    "device_id": { "type": "string" },
    "name": { "type": "string" },
    "connected": { "type": "boolean" },
    "reading": {
      "type": "object",
      "properties": {
        "temperature_c": { "type": ["number", "null"] },
        "humidity_percent": { "type": ["number", "null"] },
        "observed_at": { "type": ["string", "null"], "format": "date-time" },
        "age_seconds": { "type": ["number", "null"] },
        "source": { "type": ["string", "null"] }
      },
      "required": [
        "temperature_c",
        "humidity_percent",
        "observed_at",
        "age_seconds",
        "source"
      ],
      "additionalProperties": false
    },
    "metadata": {
      "type": "object",
      "properties": {
        "service_uuid": { "type": "string" },
        "temperature_characteristic_uuid": { "type": "string" },
        "humidity_characteristic_uuid": { "type": "string" },
        "units": {
          "type": "object",
          "properties": {
            "temperature": { "type": "string" },
            "humidity": { "type": "string" }
          },
          "required": ["temperature", "humidity"],
          "additionalProperties": false
        },
        "firmware_processing": {
          "type": "object",
          "properties": {
            "sample_interval_ms": { "type": "integer" },
            "average_window_samples": { "type": "integer" },
            "temperature_threshold_c": { "type": "number" },
            "humidity_threshold_percent": { "type": "number" },
            "temperature_is_rounded_to_0_1_c": { "type": "boolean" }
          },
          "required": [
            "sample_interval_ms",
            "average_window_samples",
            "temperature_threshold_c",
            "humidity_threshold_percent",
            "temperature_is_rounded_to_0_1_c"
          ],
          "additionalProperties": false
        }
      },
      "required": [
        "service_uuid",
        "temperature_characteristic_uuid",
        "humidity_characteristic_uuid",
        "units",
        "firmware_processing"
      ],
      "additionalProperties": false
    }
  },
  "required": ["device_id", "name", "connected", "reading", "metadata"],
  "additionalProperties": false
}
```

Python args model:

```python
@dataclass
class GetCricketReadingArgs:
    pass
```

### Tool 4: `get_cricket_status`

Description:
- Return current connection and freshness state for the active Cricket session.

Input schema:

```json
{
  "type": "object",
  "properties": {},
  "additionalProperties": false
}
```

Output schema:

```json
{
  "type": "object",
  "properties": {
    "connected": { "type": "boolean" },
    "scanning": { "type": "boolean" },
    "subscribed": { "type": "boolean" },
    "last_temperature_update_at": {
      "type": ["string", "null"],
      "format": "date-time"
    },
    "last_humidity_update_at": {
      "type": ["string", "null"],
      "format": "date-time"
    },
    "temperature_age_seconds": { "type": ["number", "null"] },
    "humidity_age_seconds": { "type": ["number", "null"] },
    "stale": { "type": "boolean" },
    "stale_threshold_seconds": { "type": "integer" },
    "last_error": { "type": ["string", "null"] }
  },
  "required": [
    "connected",
    "scanning",
    "subscribed",
    "last_temperature_update_at",
    "last_humidity_update_at",
    "temperature_age_seconds",
    "humidity_age_seconds",
    "stale",
    "stale_threshold_seconds",
    "last_error"
  ],
  "additionalProperties": false
}
```

Python args model:

```python
@dataclass
class GetCricketStatusArgs:
    pass
```

### Tool 5: `disconnect_cricket_device`

Description:
- Disconnect from the active Cricket device and stop notifications.

Input schema:

```json
{
  "type": "object",
  "properties": {
    "device_id": { "type": "string" }
  },
  "additionalProperties": false
}
```

Output schema:

```json
{
  "type": "object",
  "properties": {
    "disconnected": { "type": "boolean" },
    "device_id": { "type": "string" },
    "disconnected_at": { "type": "string", "format": "date-time" }
  },
  "required": ["disconnected", "device_id", "disconnected_at"],
  "additionalProperties": false
}
```

Python args model:

```python
@dataclass
class DisconnectCricketDeviceArgs:
    device_id: str | None = None
```

## Suggested Data Models

```python
from dataclasses import dataclass
from datetime import datetime

@dataclass
class CricketDeviceSummary:
    device_id: str
    name: str | None
    rssi: int | None
    service_uuids: list[str]
    is_connectable: bool | None
    last_seen_at: datetime

@dataclass
class ConnectCricketDeviceResult:
    connected: bool
    device_id: str
    name: str | None
    service_uuid: str
    temperature_characteristic_uuid: str
    humidity_characteristic_uuid: str
    subscribed: bool
    connected_at: datetime

@dataclass
class ReadingPayload:
    temperature_c: float | None
    humidity_percent: float | None
    observed_at: datetime | None
    age_seconds: float | None
    source: str | None

@dataclass
class FirmwareProcessingPayload:
    sample_interval_ms: int
    average_window_samples: int
    temperature_threshold_c: float
    humidity_threshold_percent: float
    temperature_is_rounded_to_0_1_c: bool

@dataclass
class MetadataPayload:
    service_uuid: str
    temperature_characteristic_uuid: str
    humidity_characteristic_uuid: str
    units: dict[str, str]
    firmware_processing: FirmwareProcessingPayload

@dataclass
class GetCricketReadingResult:
    device_id: str
    name: str
    connected: bool
    reading: ReadingPayload
    metadata: MetadataPayload
```

## BLE Manager Responsibilities

### Discovery

`discover_cricket_devices` should:
- call `BleakScanner.discover()` or equivalent async scan flow
- filter by Cricket service UUID
- prefer the local name `Nano33BLE_Sensor` but not require it if service UUID matches
- deduplicate devices by BLE identifier
- capture:
  - `device_id`
  - `name`
  - `rssi`
  - `service_uuids`
  - `is_connectable`
  - `last_seen_at`

### Connect

`connect_cricket_device` should:
- reject if another device is already connected
- create a `BleakClient` for the requested `device_id`
- connect
- verify the Cricket service is present
- verify both characteristics are present
- perform initial reads for both characteristics
- subscribe to notifications for both characteristics
- set `subscribed = True` only after both notification registrations succeed

### Notification Handling

On temperature update:
- decode BLE payload as little-endian IEEE 754 float
- update cached `temperature_c`
- set `last_temperature_update_at`
- set `observed_at`
- set source to `ble_notification`

On humidity update:
- decode BLE payload as little-endian IEEE 754 float
- update cached `humidity_percent`
- set `last_humidity_update_at`
- set `observed_at`
- set source to `ble_notification`

For initial read values:
- source should be `ble_read`

Suggested helper:

```python
import struct

def decode_ble_float(data: bytearray) -> float:
    return struct.unpack("<f", bytes(data))[0]
```

### Disconnect

`disconnect_cricket_device` should:
- stop notifications if active
- disconnect the `BleakClient`
- clear connection-specific state
- preserve the last error string if disconnect was error-driven

## Reading and Status Semantics

### Observed Time

`observed_at` should mean:
- when the host process last refreshed the cached reading

It should not claim:
- the exact instant the Arduino sensor captured the air sample

### Age Calculation

`age_seconds` should be derived from:
- current host time minus `observed_at`

### Stale Calculation

`stale` should be `True` when:
- no device is connected
- either characteristic has never been observed after connection
- either characteristic age exceeds `STALE_THRESHOLD_SECONDS`

Otherwise:
- `stale` is `False`

## Suggested MCP Server Shape

Example high-level pattern:

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Cricket MCP Server")
manager = CricketBLEManager()

@mcp.tool()
async def discover_cricket_devices(timeout_seconds: int = 5) -> dict:
    ...

@mcp.tool()
async def connect_cricket_device(device_id: str) -> dict:
    ...

@mcp.tool()
async def get_cricket_reading() -> dict:
    ...

@mcp.tool()
async def get_cricket_status() -> dict:
    ...

@mcp.tool()
async def disconnect_cricket_device(device_id: str | None = None) -> dict:
    ...
```

Important:
- the tool docstrings should be explicit and operational
- return plain Python dicts matching the schemas exactly
- do not print to `stdout`
- debug logging should go to `stderr`

## Error Model

Tool calls should fail with explicit, actionable errors.

Recommended error codes:
- `bluetooth_unavailable`
- `scan_timeout`
- `device_not_found`
- `already_connected`
- `not_connected`
- `service_not_found`
- `characteristic_not_found`
- `notification_subscription_failed`
- `stale_reading`

Suggested structure:

```json
{
  "code": "not_connected",
  "message": "No Cricket device is currently connected."
}
```

## macOS-Specific Notes

On macOS, BLE behavior can be affected by:
- Bluetooth permission prompts
- background privacy restrictions
- machine sleep

Operational implications:
- the first run may require Bluetooth permission approval
- stale readings may happen if the Mac sleeps
- the server should surface disconnect and stale state clearly rather than silently hiding them

## Minimal Implementation Sequence

1. Create a Python project with `mcp` and `bleak`.
2. Implement constants and dataclasses.
3. Implement `CricketBLEManager` discovery logic.
4. Implement connect, initial read, and notifications.
5. Implement cached snapshot methods for reading and status.
6. Register the five MCP tools with the exact schemas already defined.
7. Validate that each tool returns JSON matching the interface spec exactly.

## Acceptance Criteria

The design is implemented correctly when:
- the server exposes the five specified tools
- all tool inputs and outputs match the existing schemas exactly
- the server discovers Cricket devices by service UUID
- the server connects and subscribes successfully
- `get_cricket_reading` returns cached calibrated values and timestamps
- `get_cricket_status` reports freshness, subscription, and disconnect state accurately
