# Cricket MCP Server Swift Design

Based on:
- [Cricket_MCP_Server_Interface.md](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket_MCP_Server_Interface.md)
- [Cricket.ino](/Users/bobh/Desktop/Projects/Cricket_Arduino/Cricket/Cricket.ino)

## Goal

Design a minimal Swift MCP server for macOS that:
- runs as a local process
- communicates with the MCP client over `stdio`
- uses `CoreBluetooth` as a BLE central
- connects to the Cricket Arduino peripheral
- exposes the exact tools defined in the interface spec

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

## Design Decisions

### Connection Model

Support exactly one active Cricket connection in v1.

Reason:
- the Arduino firmware appears single-central oriented
- it keeps the MCP tool semantics simple
- it avoids premature complexity in the state model

### Staleness Policy

Use:
- `180` seconds as warning threshold
- disconnected state as hard failure

The threshold should be a server constant in v1, not a tool parameter.

### Read Semantics

`get_cricket_reading` returns the latest cached values immediately.

It does not block waiting for a fresh notification because:
- BLE updates are threshold-driven
- long-blocking MCP tool calls are a poor fit for interactive use

## Runtime Architecture

### Process Layout

```text
MCP client
  ↕ JSON-RPC over stdio
Cricket MCP Server (Swift executable)
  ↕ tool layer
CricketBLEManager
  ↕ CoreBluetooth
Arduino Nano 33 BLE Sense Rev 2
```

### Modules

Suggested package layout:

```text
CricketMCPServer/
  Package.swift
  Sources/
    CricketMCPServer/
      main.swift
      MCP/
        MCPServer.swift
        MCPMessage.swift
        MCPToolRegistry.swift
      BLE/
        CricketBLEManager.swift
        CricketPeripheral.swift
        CricketUUIDs.swift
      Model/
        CricketReading.swift
        CricketStatus.swift
        ToolSchemas.swift
      Tools/
        DiscoverCricketDevicesTool.swift
        ConnectCricketDeviceTool.swift
        GetCricketReadingTool.swift
        GetCricketStatusTool.swift
        DisconnectCricketDeviceTool.swift
```

### Core Components

`MCPServer`
- reads JSON-RPC messages from `stdin`
- writes JSON-RPC responses to `stdout`
- handles MCP initialization and tool registration
- dispatches tool calls to the tool registry

`MCPToolRegistry`
- owns the tool definitions
- validates tool names
- decodes arguments
- invokes the corresponding Swift handler

`CricketBLEManager`
- owns `CBCentralManager`
- scans for Cricket peripherals
- connects and disconnects
- discovers service and characteristics
- subscribes to notifications
- caches latest values and timestamps
- exposes synchronous snapshots of current state to the tool layer

## Required macOS Frameworks

- `Foundation`
- `CoreBluetooth`

Optional later:
- `OSLog`

## BLE Constants

These constants must match the current firmware:

```swift
enum CricketUUIDs {
    static let localName = "Nano33BLE_Sensor"
    static let service = CBUUID(string: "5971e8f1-bc4d-4a5f-a6fd-3591131a98c6")
    static let temperature = CBUUID(string: "78b20af1-e597-40c1-a69c-304205b7e099")
    static let humidity = CBUUID(string: "0ba15aa1-a805-4205-bc82-af2e4a9364c5")
}
```

## State Model

### BLE Manager State

```swift
enum ConnectionState {
    case idle
    case scanning
    case connecting(deviceID: String)
    case connected(deviceID: String)
    case disconnecting(deviceID: String)
    case failed(message: String)
}
```

### Reading Cache

```swift
struct CricketReadingSnapshot: Codable {
    let deviceID: String
    let name: String
    let connected: Bool
    let temperatureC: Float?
    let humidityPercent: Float?
    let observedAt: Date?
    let source: String?
}
```

### Status Cache

```swift
struct CricketStatusSnapshot: Codable {
    let connected: Bool
    let scanning: Bool
    let subscribed: Bool
    let lastTemperatureUpdateAt: Date?
    let lastHumidityUpdateAt: Date?
    let temperatureAgeSeconds: Double?
    let humidityAgeSeconds: Double?
    let stale: Bool
    let staleThresholdSeconds: Int
    let lastError: String?
}
```

## Tool Definitions

These tool names and schemas are intentionally aligned with the interface spec.

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

Swift request model:

```swift
struct DiscoverCricketDevicesArgs: Codable {
    let timeoutSeconds: Int?
}
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

Swift request model:

```swift
struct ConnectCricketDeviceArgs: Codable {
    let deviceID: String
}
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

Swift request model:

```swift
struct GetCricketReadingArgs: Codable {}
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

Swift request model:

```swift
struct GetCricketStatusArgs: Codable {}
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

Swift request model:

```swift
struct DisconnectCricketDeviceArgs: Codable {
    let deviceID: String?
}
```

## MCP Tool Registration

The server should expose these tools during MCP initialization:

```json
[
  {
    "name": "discover_cricket_devices",
    "description": "Scan for BLE peripherals advertising the Cricket environmental service UUID.",
    "inputSchema": { "...": "see schema above" }
  },
  {
    "name": "connect_cricket_device",
    "description": "Connect to a discovered Cricket device and subscribe to its temperature and humidity characteristics.",
    "inputSchema": { "...": "see schema above" }
  },
  {
    "name": "get_cricket_reading",
    "description": "Return the latest cached temperature and humidity reading from the connected Cricket device.",
    "inputSchema": { "...": "see schema above" }
  },
  {
    "name": "get_cricket_status",
    "description": "Return connection, subscription, freshness, and error state for the current Cricket session.",
    "inputSchema": { "...": "see schema above" }
  },
  {
    "name": "disconnect_cricket_device",
    "description": "Disconnect from the active Cricket BLE device and stop monitoring.",
    "inputSchema": { "...": "see schema above" }
  }
]
```

## Suggested Swift Type Definitions

```swift
struct CricketDeviceSummary: Codable {
    let deviceID: String
    let name: String?
    let rssi: Int?
    let serviceUUIDs: [String]
    let isConnectable: Bool?
    let lastSeenAt: Date
}

struct ConnectCricketDeviceResult: Codable {
    let connected: Bool
    let deviceID: String
    let name: String?
    let serviceUUID: String
    let temperatureCharacteristicUUID: String
    let humidityCharacteristicUUID: String
    let subscribed: Bool
    let connectedAt: Date
}

struct GetCricketReadingResult: Codable {
    let deviceID: String
    let name: String
    let connected: Bool
    let reading: ReadingPayload
    let metadata: MetadataPayload
}

struct ReadingPayload: Codable {
    let temperatureC: Float?
    let humidityPercent: Float?
    let observedAt: Date?
    let ageSeconds: Double?
    let source: String?
}

struct MetadataPayload: Codable {
    let serviceUUID: String
    let temperatureCharacteristicUUID: String
    let humidityCharacteristicUUID: String
    let units: UnitsPayload
    let firmwareProcessing: FirmwareProcessingPayload
}

struct UnitsPayload: Codable {
    let temperature: String
    let humidity: String
}

struct FirmwareProcessingPayload: Codable {
    let sampleIntervalMS: Int
    let averageWindowSamples: Int
    let temperatureThresholdC: Double
    let humidityThresholdPercent: Double
    let temperatureIsRoundedTo0_1C: Bool
}
```

## BLE Manager Behavior

### Discovery

`discover_cricket_devices` should:
- start scanning with the Cricket service UUID filter
- collect matching advertisements for `timeout_seconds`
- deduplicate devices by CoreBluetooth identifier
- prefer the advertised local name but not require it if service UUID matches
- stop scanning before returning

### Connect

`connect_cricket_device` should:
- reject if another device is already connected
- connect to the chosen peripheral
- discover the Cricket service
- discover both characteristics
- issue an initial read for both characteristics
- enable notifications for both characteristics
- mark `subscribed = true` only when both notifications are enabled

### Notification Handling

On notification for temperature:
- decode the characteristic payload as `Float`
- store `temperatureC`
- set `lastTemperatureUpdateAt`
- refresh `observedAt`
- set source to `ble_notification`

On notification for humidity:
- decode the characteristic payload as `Float`
- store `humidityPercent`
- set `lastHumidityUpdateAt`
- refresh `observedAt`
- set source to `ble_notification`

If the initial value comes from a read rather than a notify event:
- source should be `ble_read`

### Status Calculation

`stale` should be computed from the newest missing or aged required reading:
- if disconnected, `stale = true`
- if either characteristic has never been observed after connection, `stale = true`
- if either age exceeds `180`, `stale = true`
- otherwise `stale = false`

## MCP Transport Notes

The server process should:
- print nothing except MCP protocol output to `stdout`
- send logs and diagnostics to `stderr`
- keep running until the MCP client closes the session

Minimal server lifecycle:

1. Process starts.
2. MCP client sends initialize request.
3. Server responds with capabilities including tool support.
4. MCP client calls tools over JSON-RPC.
5. Server remains event-driven while CoreBluetooth callbacks update state.

## Error Model

Tool calls should fail with actionable errors.

Recommended cases:
- `bluetooth_unavailable`
- `scan_timeout`
- `device_not_found`
- `already_connected`
- `not_connected`
- `service_not_found`
- `characteristic_not_found`
- `notification_subscription_failed`
- `stale_reading`

The server should prefer structured tool error messages over silent nulls when the overall operation failed.

Example error payload:

```json
{
  "code": "not_connected",
  "message": "No Cricket device is currently connected."
}
```

## Minimal Implementation Sequence

1. Build a Swift executable that can speak MCP over `stdio` and register the five tools.
2. Implement a BLE manager that can scan and discover Cricket devices.
3. Implement connect, service discovery, characteristic discovery, and notification subscription.
4. Add the state cache and make `get_cricket_reading` and `get_cricket_status` return snapshots.
5. Add disconnection and error handling.
6. Verify tool responses match the schemas in this document exactly.

## Acceptance Criteria

The design is implemented correctly when:
- the server registers the five specified tools
- all tool inputs validate against the schemas above
- all successful outputs conform to the schemas above
- the server can discover and connect to `Nano33BLE_Sensor`
- the server returns cached calibrated temperature and humidity values
- the server reports stale or disconnected state clearly
