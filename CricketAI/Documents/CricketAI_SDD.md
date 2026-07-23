# CricketAI Software Design Document (SDD)

**Document status:** Draft v0.2 — SDK-verified  
**Date:** 2026-07-13; revised 2026-07-16  
**Product:** CricketAI  
**Platform:** iOS 27, iPhone only  
**Toolchain:** Xcode 27.0 beta 3 (build 27A5218g), iOS 27.0 SDK, Swift 6.4  
**Source document:** CricketAI SRS draft v0.1, dated 2026-07-12  
**Design thesis:** local sensor data + local model reasoning = better answers for questions where immediate hyperlocal conditions matter  
**v0.2 note:** All "confirm against SDK" items resolved against the installed iOS 27.0 SDK on 2026-07-16. See `CricketAI_SDD_Review.md` for the verification record. Changed sections: §8.2, §8.5, §11, §13, §17, §19. Added §8.6 (Spotlight & System Indexing) on 2026-07-23.

---

## 1. Purpose

CricketAI is an iOS application that reads current hyperlocal temperature and humidity from a local Arduino/Ruuvi BLE sensor and makes that reading available to Apple Intelligence, Siri, Shortcuts, and an in-app Foundation Models reasoning loop.

CricketAI is not a weather app. It is a local environmental truth source for model reasoning. When the user asks a question whose answer depends on immediate room conditions, the system should use CricketAI's local BLE-backed reading rather than distant airport weather, OS weather, web data, or a permission-gated external service.

The canonical acid test is:

> Is it safe to work on CMOS devices right now?

Success means the model uses its built-in ESD/CMOS domain knowledge, calls CricketAI's local reading tool for current temperature and humidity, discloses freshness, and answers without asking for weather, location, web, or external environmental access.

---

## 2. Design Goals

1. Provide a single authoritative current environmental reading.
2. Preserve reading freshness and staleness as first-class data.
3. Expose CricketAI readings to Apple Intelligence and Siri through App Intents, Entities, and schemas where available.
4. Expose the same readings to an in-app Foundation Models `Tool`.
5. Ensure the model never fabricates temperature or humidity values.
6. Ensure environmental reasoning prompts use local CricketAI readings before any external environmental source.
7. Validate tool use, grounding, freshness disclosure, and Siri/App Intents routing through automated tests and evaluation suites.
8. Adopt relevant WWDC26/iOS 27 concepts intentionally, rather than merely porting the original CricketIOS app.

---

## 3. Non-Goals

- No macOS target in v1.
- No WidgetKit widgets in v1.
- No third-party cloud LLMs in v1.
- No MCP integration in v1.
- No external weather lookup as a substitute for CricketAI's current local reading.
- No agent *features* built on pressure/motion in v1 — these are optional, disclosed data-model fields only (see §6.1, SDD-3), not part of the ⭐acid test. Pressure-*trend* reasoning is a candidate for a later version.

---

## 4. System Context

```text
Arduino Nano 33 BLE Sense Rev 2 / RuuviTag
        |
        | BLE
        v
BluetoothService / RuuviService
        |
        v
CricketCore
  - latest accepted reading
  - age and freshness classification
  - unavailable reasons
  - App Group last-known persistence
        |
        +--> AppIntentsSurface
        |      - App Intents
        |      - App Entities
        |      - schemas where available
        |      - Siri / Shortcuts / Apple Intelligence
        |
        +--> AgentSurface
               - ReadEnvironmentalConditions Tool
               - LanguageModelSession
               - on-device model
               - optional PCC escalation
```

The Arduino/Ruuvi sensor is the local data source. The Foundation Models `Tool` is not the sensor itself; it is the app-defined adapter that reads from `CricketCore`.

---

## 5. Architectural Design

### 5.1 Modules

| Module | Responsibility |
|---|---|
| `CricketCore` | Single source of truth for latest reading, freshness, staleness, and unavailability. |
| `BluetoothService` | Connects to Arduino, restores peripheral, parses BLE characteristics, feeds `CricketCore`. |
| `RuuviService` | Parses RuuviTag advertisements and feeds `CricketCore`. |
| `ReadingPersistence` | Stores last-known reading for cold start and out-of-process App Intent execution. |
| `AppIntentsSurface` | Defines App Intents, App Entities, queries, dialogs, schemas, and view annotations. |
| `AgentSurface` | Defines `ReadEnvironmentalConditions`, model instructions, session lifecycle, and routing. |
| `ChatUI` | Minimal in-app conversational surface backed by `AgentSurface`. |
| `EvalSuite` | Verifies grounding, freshness disclosure, unavailable handling, and routing behavior. |

### 5.2 Core Design Decision

`CricketCore` should be an `@MainActor @Observable` object for v1, with an injectable clock and optional persistence. This matches the existing sketch and keeps SwiftUI, App Intents, and the Foundation Models tool reading from one in-process authority.

An actor-backed internal store is deferred unless implementation shows real contention or out-of-main-actor mutation pressure. CoreBluetooth delegate callbacks remain `nonisolated`; they extract `Sendable` values and hop to the main actor before calling `CricketCore`.

---

## 6. Data Design

### 6.1 Reading

```swift
struct Reading: Sendable, Equatable, Identifiable, Codable {
    let id: UUID
    let celsius: Double
    let relativeHumidity: Double
    let timestamp: Date
    let source: SensorSource

    // Optional, source-capability-aware metrics (DR-3, revised 2026-07-23). NOT part of
    // the acid test. nil when the source/firmware build doesn't supply the metric — nil
    // is authoritative and drives "unavailable from this source" disclosure copy.
    let pressureHPa: Double?     // RuuviTag RAWv2 (free); Rev-2 Arduino via onboard LPS22HB if firmware exposes a char
    let movementCount: Int?      // RuuviTag RAWv2 native; Rev-2 Arduino synthesizable from BMI270 any-motion interrupt

    var fahrenheit: Double { celsius * 9.0 / 5.0 + 32.0 }
    var hasPressure: Bool { pressureHPa != nil }
    var hasMotion: Bool { movementCount != nil }
}
```

`Reading` contains accepted, sentinel-filtered data only. Invalid sensor values are never stored as readings. **Pressure/motion (DR-3, revised 2026-07-23):** modeled as `Optional` so temperature+humidity (the acid-test core) stay mandatory while optional metrics are added without a schema break. Both the Nano 33 BLE Sense Rev 2 (onboard LPS22HB pressure + BMI270 IMU — **no external sensor required**) and the new RuuviTag model can supply them; RuuviTag's arrive for free in the advertisement. v1 stores and discloses them but builds no agent features on them.

### 6.2 Reading Result

```swift
enum ReadingResult: Sendable, Equatable {
    case fresh(Reading)
    case stale(Reading, age: Duration)
    case unavailable(UnavailableReason)
}
```

No consumer receives a bare humidity or temperature value. App Intents, tool calls, dialogs, and UI all receive the freshness state with the reading.

### 6.3 Unavailable Reasons

Unavailable reasons should distinguish at least:

- never connected
- disconnected
- Bluetooth off
- Bluetooth unauthorized
- Bluetooth unsupported
- sensor error

This lets Siri, the chat UI, and the model explain the failure without inventing a value.

### 6.4 Freshness

The default freshness threshold is five minutes for draft v0.1. Readings at or under the threshold are fresh. Older readings are stale and must be disclosed.

This is a product constant, not a scattered magic number. It should be tuned with field use and evaluations.

---

## 7. Sensor Acquisition Design

### 7.1 Arduino BLE

`BluetoothService` connects to the Arduino peripheral using the CricketIOS UUIDs and parsing rules:

- Custom service: `5971E8F1-BC4D-4A5F-A6FD-3591131A98C6`
- Temperature characteristic: `78B20AF1-E597-40C1-A69C-304205B7E099`
- Humidity characteristic: `0BA15AA1-A805-4205-BC82-AF2E4A9364C5`
- Format: IEEE-754 float32, little-endian
- Standard ESS fallback temperature: `2A6E`
- Standard ESS fallback humidity: `2A6F`

Sentinel values such as temperature `-32768` and humidity `65535` are sensor errors and must not be surfaced.

### 7.2 Background Acquisition

Background BLE acquisition is in v1 scope. `BluetoothService` uses CoreBluetooth state preservation/restoration and the `bluetooth-central` background mode. The last-known reading remains available with explicit age whenever live acquisition is not possible.

### 7.3 Persistence

CricketAI may persist the last-known reading for cold launch and App Intent execution. If App Group persistence is used, the identifier must be `group.wm6h.CricketAI`; the old `com.yourcompany` placeholder must not appear.

Persistence does not make stale data fresh. All persisted readings are reclassified by age when read.

---

## 8. App Intents, Entities, and Schemas

### 8.1 Design Principle

App Intents with schemas are a first-class CricketAI surface. This is how Apple Intelligence, Siri, and Shortcuts discover and reason about CricketAI's hyperlocal environmental readings when the app is not foregrounded.

CricketAI should not merely migrate the original CricketIOS App Intents. It should use WWDC26/iOS 27 concepts where they improve system understanding:

- App Intents for actions and queries
- App Entities for semantic references to readings, sensors, and status
- schemas where an Apple-provided schema is semantically correct
- view annotations so Siri can resolve contextual references such as "this reading"
- App Intents testing for routing and dialog verification

### 8.2 Schema Strategy

**Decision (verified against iOS 27.0 SDK, 2026-07-16): CricketAI uses generic `AppEntity` / `AppIntent` conformance.**

The iOS 27 assistant-schema catalog was enumerated in full (~25 domains: Books, Browser, Calendar, Camera, Clock, Files, Journal, Mail, Maps, Messages, Notes, Phone, Photos, Presentation, Reader, Reminders, Spreadsheet, System, VisualIntelligence, Whiteboard, WordProcessor, plus audio/video/workout families). **There is no environmental, weather, current-conditions, measurement, or sensor assistant-schema domain.** Forcing CricketAI's hyperlocal reading into an unrelated schema would be semantically wrong. Therefore CricketAI conforms to generic `AppEntity`/`AppIntent` and carries strongly structured data in its own entities and dialogs.

The schema macros exist and are confirmed spelled `@AssistantEntity(schema:)` / `@AssistantIntent(schema:)` (domains under `AssistantSchemas.Entity`), but CricketAI does not adopt them in v1 because no matching domain exists.

| Surface | v1 design (confirmed) |
|---|---|
| Current environmental reading entity | Generic `AppEntity` (`EnvironmentalReadingEntity`) |
| Get temperature intent | Generic `AppIntent` with structured result |
| Get humidity intent | Generic `AppIntent` with structured result |
| Workshop conditions intent | Generic `AppIntent` returning a reading entity and dialog |
| Sensor status intent | Generic `AppIntent` returning a status entity |

**Re-verify trigger:** if a future iOS/SDK adds an environmental/current-conditions assistant-schema domain, revisit this decision and adopt it where semantically correct.

### 8.3 Entities

CricketAI should define semantic entities rather than passing raw strings:

- `EnvironmentalReadingEntity`
- `SensorStatusEntity`
- `SensorSourceEntity` or `SensorSourceAppEnum`
- `FreshnessStateAppEnum`

`EnvironmentalReadingEntity` should include:

- temperature in Celsius
- temperature in Fahrenheit
- relative humidity
- timestamp
- age
- freshness state
- source

Live readings are not pre-indexable content. Entity queries use `EntityStringQuery` (confirmed present in iOS 27; `EntityQuery` / `EnumerableEntityQuery` also available), and contextual resolution should not return an empty list for known references.

### 8.4 App Intents

Initial intents:

- `GetLocalTemperatureIntent`
- `GetLocalHumidityIntent`
- `GetWorkshopConditionsIntent`
- `GetSensorStatusIntent`

Every intent reads from `CricketCore` through the same `ReadingResult` contract. Every dialog discloses stale or unavailable readings.

Example dialog behavior:

- Fresh: "The workshop is 70 F with 42% relative humidity from CricketAI."
- Stale: "The last CricketAI reading was 70 F and 42% relative humidity, captured about 12 minutes ago."
- Unavailable: "CricketAI does not currently have a sensor reading because Bluetooth is off."

### 8.5 On-Screen Entity Association

(Formerly "view annotations." APIs confirmed present in iOS 27.0 SDK, 2026-07-16.)

The main reading view associates its `EnvironmentalReadingEntity` with the on-screen context so Siri and Apple Intelligence can resolve references such as "this reading," "the workshop humidity," or "the CricketAI sensor." Use:

- `associateAppEntity(_:priority:)` — bind the currently displayed reading entity to the view context.
- `SnippetIntent` / `ShowsSnippetView` — present the reading entity as a snippet in Siri / Spotlight results.
- SwiftUI `.userActivity(...)` — advertise the current reading as the active user activity where appropriate.

`IndexedEntity` conformance supports association priority. This capability is confirmed available and in scope for v1.

### 8.6 Spotlight & System Indexing (Optional Exposure)

While primary model interactions occur within `LanguageModelSession` via tool invocations (`Tool<Arguments, Output>`), high-value entity states MAY be surfaced to the system search index to enable proactive system UI integration (e.g., Spotlight, Siri Suggestions).

#### 8.6.1 Semantic Indexing Strategy

To avoid stale sensor data persisting in system search indices, entity indexing MUST decouple the lookup handle from volatile state.

- **Handle-Indexed (`IndexedEntity` / `AppEntity`):** Static sensor metadata and logical identities (e.g., node UUID, `LocationLabel`, `DeviceName`) are indexed via Spotlight (`CSUserQuery` / CoreSpotlight) for fast retrieval. Only the stable handle is pushed to the index — the entity `id` is the node UUID with no timestamp.
- **Value-Live Evaluation:** Live environmental values (`temperature`, `humidity`, `pressureHPa`, freshness) MUST NOT be indexed as static search-string properties. Selecting or querying an indexed entity instead resolves values dynamically at invocation time by fetching the current reading from `CricketCore` (§8.3), always emitting freshness disclosure — never returning a cached value as if fresh.

```swift
// Handle-Indexed / Value-Live. Only the stable node handle is indexed;
// live values are resolved on demand and never stored on the entity.
struct SensorNodeEntity: AppEntity, IndexedEntity {
    var id: String                               // node UUID — stable handle, no timestamp

    @Property(title: "Sensor Name")
    var name: String

    // Computed statics — a stored mutable static trips Swift 6.2 strict concurrency.
    // (TypeDisplayRepresentation has no systemImage: init; string literal only.)
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Cricket Sensor" }
    static var defaultQuery: SensorNodeQuery { SensorNodeQuery() }

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

    // IndexedEntity: only the stable handle is pushed to Spotlight — never live values.
    // Note: @Property here carries NO indexingKey:/customIndexingKey: — those variants push
    // a value into the index and must stay OFF for temp/humidity/pressure/freshness fields.
    var attributeSet: CSSearchableItemAttributeSet {
        // init(contentType: UTType) — requires `import UniformTypeIdentifiers`.
        let set = CSSearchableItemAttributeSet(contentType: .item)
        set.displayName = name
        return set
    }
}

// EntityStringQuery supports natural-language matching (e.g. "garden pressure").
struct SensorNodeQuery: EntityStringQuery {
    func entities(for ids: [String]) async throws -> [SensorNodeEntity] { /* ... */ }
    func entities(matching string: String) async throws -> [SensorNodeEntity] { /* NL match */ }
}
```

Live values are resolved separately at invocation time by the reading intent/tool (§8.4) from `CricketCore`, returned with §8.3 freshness disclosure — they are never members of, or indexed by, this entity.

#### 8.6.2 Freshness & Privacy Constraints

1. **No Background Pollution:** Sensor readings must never be pushed to Spotlight background indices without explicit user action or an active connection event.
2. **Freshness Disclosure:** Any Spotlight-triggered intent action that outputs sensor metrics MUST pass through the standard §8.3 freshness evaluation pipeline before presenting safety conclusions to the user.

#### 8.6.3 SDK Verification Status

The AppIntents surface used here (`IndexedEntity` + `attributeSet`/`hideInSpotlight`, `@Property` variants, `EntityStringQuery`, computed `typeDisplayRepresentation`/`defaultQuery`) is verified against the iOS 27.0 AppIntents `.swiftinterface` (Xcode 27 beta 4, 2026-07-22). The CoreSpotlight initializer is verified against the iOS 27.0 CoreSpotlight headers (2026-07-23): use `CSSearchableItemAttributeSet(contentType: UTType)` (`import UniformTypeIdentifiers`); the older `init(itemContentType: String)` is deprecated. No open SDK-verification items remain for §8.6.

---

## 9. Foundation Models Tool Design

### 9.1 Tool

The in-app agent uses one primary tool:

```swift
// Confirmed against iOS 27.0 SDK: protocol Tool<Arguments, Output>: Sendable
struct ReadEnvironmentalConditions: Tool {
    let name = "readEnvironmentalConditions"
    let description = "…"           // see §9.2
    // associated types: Arguments (@Generable input), Output (@Generable/ToolOutput)
    // func call(arguments: Arguments) async throws -> Output
}
```

The Foundation Models framework, `Tool`, `LanguageModelSession`, `Instructions`/`@InstructionsBuilder`, `@Generable`/`GeneratedContent`, and `GenerationSchema` are all confirmed present in the iOS 27.0 SDK (Swift 6.4).

The tool calls `CricketCore.currentConditions()` and returns a structured payload containing:

- result state: fresh, stale, unavailable
- celsius
- fahrenheit
- relative humidity
- source
- timestamp
- age
- freshness note
- unavailable reason, if any

### 9.2 Tool Description

The tool description must make discoverability obvious to the model:

> Reads CricketAI's current local BLE sensor conditions for the user's immediate environment. Use this whenever a user asks about activities affected by room temperature or humidity, including electronics/ESD handling, soldering, curing, finishing, comfort, storage, or workshop conditions. This tool returns local sensor data, not external weather.

The description should explicitly say:

- when to call it
- what units are returned
- that stale/unavailable readings must be disclosed
- that external weather is not a substitute for this tool

### 9.3 Tool Output Schema

The Foundation Models tool output should be structured, not prose-only. The exact generated schema syntax is SDK-dependent, but the logical schema is:

```json
{
  "state": "fresh | stale | unavailable",
  "temperatureCelsius": 21.1,
  "temperatureFahrenheit": 70.0,
  "relativeHumidityPercent": 42.0,
  "source": "arduino | ruuvi",
  "timestamp": "2026-07-13T10:15:00Z",
  "ageSeconds": 90,
  "freshnessNote": "current",
  "unavailableReason": null
}
```

This schema is separate from App Intent schemas, but both represent the same domain object: CricketAI's local environmental reading.

---

## 10. Agent Behavior Design

### 10.1 Domain Knowledge vs Current Conditions

The model supplies general domain knowledge. CricketAI supplies current room truth.

For CMOS/ESD handling, the model should already understand that very dry air increases static discharge risk and that ESD precautions are still required even when humidity is acceptable. The model must not ask an external source for that knowledge.

For current local conditions, the model must call `ReadEnvironmentalConditions`.

### 10.2 Instructions

The session instructions should include these rules:

1. Any claim about the user's current local temperature or humidity must come from `ReadEnvironmentalConditions`.
2. If a prompt concerns an activity affected by current temperature or humidity, call `ReadEnvironmentalConditions`.
3. Disclose stale or unavailable readings.
4. Do not ask for weather, location, web, or airport data to answer current local-condition questions.
5. Use general model knowledge for domain reasoning, but ground current conditions in CricketAI data.
6. If the local reading is unavailable, say so and provide only general guidance.

### 10.3 Acid-Test Behavior

Prompt:

> Is it safe to work on CMOS devices right now?

Required behavior:

1. Call `ReadEnvironmentalConditions`.
2. Interpret humidity and temperature using ESD/CMOS handling knowledge.
3. Mention freshness.
4. Recommend normal ESD precautions.
5. Avoid requesting external weather/location/network access.

Failure modes:

- asks for location permission
- asks to access weather
- answers with current humidity without tool invocation
- gives generic ESD advice without checking CricketAI
- hides stale/unavailable state

---

## 11. Model Session and Escalation

### 11.1 On-Device Default

The default in-app chat session uses the on-device system model with `ReadEnvironmentalConditions` attached. Simple factual queries such as "what is the humidity?" must resolve on-device without network latency.

### 11.2 PCC Escalation

**Confirmed against iOS 27.0 SDK (2026-07-16): Private Cloud Compute is a public API** — `PrivateCloudComputeLanguageModel` (a `LanguageModel`), exposing `availability`, `quotaUsage`, and failure types `RateLimited`, `QuotaLimitReached`, `ServiceUnavailable`, `NetworkFailure`. Escalation is therefore buildable.

Escalation is optional and used only for advice-oriented or complex questions, and it must use the same `ReadEnvironmentalConditions` local reading tool contract. Escalation must not convert a local environmental query into an external weather lookup.

**Required handling (new in v0.2):**

1. Check `PrivateCloudComputeLanguageModel.availability` before routing to PCC.
2. Handle `RateLimited`, `QuotaLimitReached`, `ServiceUnavailable`, and `NetworkFailure` explicitly.
3. On any of the above, **fall back to the on-device `SystemLanguageModel`** with the same tool and instructions — never degrade to an external weather source.
4. The user-visible answer must not depend on PCC availability for current-condition facts; those always come from the local tool regardless of which model is used.

### 11.3 Routing Heuristic

Draft routing:

- Factual current-condition query: on-device, light reasoning.
- Safety-adjacent but common guidance query: on-device first, with local tool call.
- Complex advisory query with broader reasoning: eligible for PCC, still grounded in local tool data.

The final heuristic should be tuned through evaluations.

---

## 12. UI Design

### 12.1 Main Reading View

The main screen should show:

- current temperature
- current relative humidity
- freshness/age
- source
- link status
- unavailable reason, if applicable

This view is not merely decorative; it is the visible representation of the same entity exposed to App Intents and the model.

### 12.2 Chat UI

The v1 chat UI is intentionally minimal:

- prompt input
- response area
- visible indication when local conditions were used
- stale/unavailable disclosure when applicable

The chat UI should not expose external weather as an alternative source in v1.

---

## 13. Evaluation and Testing Design

### 13.1 Unit Tests

Swift Testing unit tests cover:

- BLE parsing
- sentinel rejection
- freshness classification
- unavailable reasons
- persistence reload
- App Intent result shaping
- routing heuristic

### 13.2 App Intents Tests

There is no dedicated Apple "App Intents testing" framework (confirmed against iOS 27.0 SDK). Intents are tested with Swift Testing by constructing the intent and invoking `perform()` directly (injecting a stubbed `CricketCore`), asserting on the returned result/dialog. Tests verify:

- each intent performs and returns the expected result type
- entities resolve (query returns the current reading for known references)
- dialogs include values and freshness
- stale dialogs disclose age
- unavailable dialogs do not fabricate values

### 13.3 Agent Evaluations

There is no Apple "evaluation suite" framework (confirmed against iOS 27.0 SDK; Foundation Models exposes only `LanguageModelFeedback`/`logFeedbackAttachment` for Feedback Assistant). CricketAI's evaluations are implemented as an in-repo harness of Swift Testing cases that drive a `LanguageModelSession` and assert on tool-use and disclosure behavior. `LanguageModelFeedback` may optionally be used to capture attachments for triage.

Evaluation prompts should include:

- "What is the humidity?"
- "Should I open the windows?"
- "Is it safe to solder in here?"
- "Is it safe to work on CMOS devices right now?"
- "Can I varnish my deck this afternoon?"
- "Is this room okay for my guitar?"

Each evaluation should check:

- `ReadEnvironmentalConditions` was called when current conditions matter
- no current environmental number appears unless tool data supplied it
- stale readings are disclosed
- unavailable readings are not replaced with guessed values
- no external weather/location/web permission is requested for current local conditions
- semantically similar prompts produce consistent tool-use behavior

---

## 14. Privacy and Permission Design

CricketAI's default reasoning is on-device. The app should need Bluetooth permission for the sensor and should not need location permission for its core value proposition.

The app must not request weather, location, web, or network permissions to answer current local environmental prompts. A permission prompt for external weather during the CMOS/ESD acid test is a product failure.

PCC escalation, if used, must be explicit in design and must preserve the same local reading contract.

---

## 15. Migration Design

Migration from CricketIOS is additive:

1. Port BLE acquisition from `BluetoothViewModel` into `BluetoothService`.
2. Port Ruuvi parsing from `RuuviTagViewModel` into `RuuviService`.
3. Create `CricketCore`.
4. Replace live `UserDefaults.standard` reads with `CricketCore`.
5. Add App Group persistence only for last-known out-of-process access.
6. Migrate App Intents and add schema adoption where appropriate.
7. Add entities, view annotations, and App Intents tests.
8. Add Foundation Models tool and in-app chat.
9. Add evaluations.
10. Remove widgets and macOS branches.

---

## 16. Phased Implementation

| Phase | Design work | SDK status |
|---|---|---|
| 0 | `CricketCore`, data model, freshness, persistence, tests | Buildable now |
| 1 | BLE/Ruuvi services feeding `CricketCore` | Buildable now |
| 2 | App Intents, Entities, on-screen entity association, App Intents tests | ✅ Confirmed (iOS 27.0 SDK) — generic conformance, no schema adoption |
| 3 | Foundation Models `ReadEnvironmentalConditions` tool and chat UI | ✅ Confirmed (iOS 27.0 SDK) — `Tool`, `LanguageModelSession`, `@Generable` |
| 4 | Evaluation harness for grounding/freshness/tool use | ✅ Confirmed — DIY Swift Testing (no Apple eval framework) |
| 5 | PCC escalation and dynamic profiles | ✅ Confirmed (iOS 27.0 SDK) — `PrivateCloudComputeLanguageModel`, `DynamicProfile` |

Phase 0 is listed first because freshness is the foundation for trust. The product emphasis remains the Phase 2/3 loop: local CricketAI readings exposed to Apple Intelligence and local model reasoning.

---

## 17. Open Issues

| ID | Issue | Position (updated 2026-07-16 vs iOS 27.0 SDK) |
|---|---|---|
| SDD-1 | Exact iOS 27 App Intent schema API names | ✅ RESOLVED — macros are `@AssistantEntity(schema:)` / `@AssistantIntent(schema:)`; not adopted in v1 (see SDD-2). |
| SDD-2 | Whether an environmental schema exists | ✅ RESOLVED — none exists in iOS 27. v1 uses generic `AppEntity`/`AppIntent` (§8.2). |
| SDD-3 | Pressure / motion | ✅ RESOLVED (reversed 2026-07-23) — added to `Reading` as **optional, source-capability-aware** fields (`pressureHPa`, `movementCount`), stored + disclosed, no agent features on them in v1 (§6.1, §3). Rev-2 needs NO external sensor (onboard LPS22HB + BMI270); RuuviTag supplies both free via advertisement. |
| SDD-4 | Freshness threshold | Draft default is five minutes; tune later. |
| SDD-5 | PCC routing heuristic | Start simple; tune with evaluations. PCC API confirmed public (§11.2); handle quota/network failure + on-device fallback. |
| SDD-6 | On-screen entity association ("view annotations") | ✅ RESOLVED — `associateAppEntity(_:priority:)` + `SnippetIntent`/`ShowsSnippetView` confirmed; in scope for v1 (§8.5). |
| SDD-7 | Background BLE scope | Included in v1 per SRS; implementation risk should be tracked. |

---

## 18. Design Invariants

These are the rules the implementation should not violate:

1. `CricketCore` is the single authority for current environmental readings.
2. No environmental value is surfaced without freshness context.
3. The model must not fabricate local temperature or humidity.
4. App Intents and Foundation Models tools read the same local source.
5. Assistant schemas are used only where semantically correct and SDK-confirmed; in v1 none apply, so CricketAI uses generic `AppEntity`/`AppIntent` (§8.2).
6. External weather is not a substitute for CricketAI's local sensor.
7. Domain knowledge comes from the model; current room truth comes from CricketAI.
8. The CMOS/ESD acid test must pass without external weather/location permission.

---

## 19. API Confirmation Record (verified 2026-07-16 vs iOS 27.0 SDK)

All checked against `iPhoneOS27.0.sdk` (Xcode 27.0 beta 3, Swift 6.4). Full record in `CricketAI_SDD_Review.md`.

| API area | Status |
|---|---|
| Assistant schema macros (`@AssistantEntity`/`@AssistantIntent(schema:)`) | ✅ Present; **not adopted** — no environmental domain (§8.2) |
| Assistant schema domain catalog | ✅ Enumerated (~25 domains); none environmental/measurement |
| Entity query APIs (`EntityStringQuery`, `EntityQuery`, `EnumerableEntityQuery`) | ✅ Present |
| On-screen entity association (`associateAppEntity`, `SnippetIntent`, `ShowsSnippetView`) | ✅ Present (§8.5) |
| Foundation Models `Tool<Arguments, Output>` | ✅ Present, stable |
| `LanguageModelSession` (model/tools/instructions/transcript inits) | ✅ Present |
| Instructions API (`Instructions`, `@InstructionsBuilder`) | ✅ Present |
| Structured output (`@Generable`, `GeneratedContent`, `GenerationSchema`) | ✅ Present |
| Private Cloud Compute model (`PrivateCloudComputeLanguageModel`) | ✅ Present (quota/availability/failure types) — §11.2 |
| Dynamic profile/instructions (`DynamicProfile`, `DynamicInstructions`, `DynamicProfileModifier`) | ✅ Present |
| Evaluation suite API | ❌ None — evals are DIY Swift Testing; only `LanguageModelFeedback` exists (§13.3) |

