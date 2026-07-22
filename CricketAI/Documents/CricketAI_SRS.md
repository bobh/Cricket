# CricketAI — System Requirements Specification (SRS)

**Document status:** Draft v0.1
**Date:** 2026-07-12
**Author:** Bob H. (with Claude Code)
**Applies to:** CricketAI, a new iOS 27 / WWDC26 application derived from CricketIOS

---

## 0. Document Control

| Field | Value |
|---|---|
| Product | CricketAI |
| Platform | iOS 27 (iPhone) only — **no macOS, no widgets** in v1 |
| Language / toolchain | Swift 6.2+, Xcode 27, strict concurrency (`-strict-concurrency=complete`) |
| Coding standard | `~/Desktop/Projects/Cricket/Agents.md` (authoritative) |
| Predecessor | CricketIOS (`~/Desktop/Projects/Cricket/CricketIOS/`) — iOS 26 / WWDC25 |
| SDK availability note | This spec targets APIs announced at **WWDC26**. The machine currently has the **iOS 26.5 SDK**; iOS 27 SDK (Xcode 27) is required to build Phases 3–4 and is pending **public beta** installation. |

### 0.1 Verification legend
Throughout this document, API-dependent requirements carry a confidence tag:

- **[SHIPPING]** — confirmed present in the installed iOS 26.5 SDK; buildable today.
- **[WWDC26]** — announced at WWDC26 (verified against Apple session pages 241 / 319 / 339); requires iOS 27 SDK; **exact identifier spelling to be re-confirmed against the installed SDK before coding.**
- **[TBD]** — design decision not yet made; tracked in §12 Open Issues.

---

## 1. Introduction

### 1.1 Purpose
CricketAI provides an on-device AI agent that can reason about **hyperlocal** environmental conditions — temperature and humidity measured by a user's own Arduino/RuuviTag sensor over Bluetooth Low Energy — rather than relying on distant weather-service estimates surfaced by the operating system. The agent combines the model's general domain knowledge (e.g., soldering ventilation, finish curing, fermentation) with the user's *current, local* sensor reading to answer practical questions such as "Can I varnish my deck this afternoon?" or "Is it safe to solder in here right now?".

### 1.2 Scope
CricketAI is a single-purpose iOS app that:
1. Polls a BLE environmental sensor and maintains the latest reading with an explicit freshness/age model.
2. Exposes those readings to Apple Intelligence / Siri via **App Intents** (system-level discovery surface).
3. Exposes those readings to an in-app **Foundation Models** reasoning loop via a **Tool**-conforming type, enabling free-form conversational queries.
4. Optionally escalates hard queries from the on-device model to a Private Cloud Compute model using the same session API.
5. Is validated by an automated **Evaluations** suite that verifies the agent grounds its answers in real, fresh sensor data.

**Out of scope for v1:** macOS app, WidgetKit widgets, third-party cloud LLMs (Claude/Gemini), MCP, App Intent schema domains for which no environmental domain exists.

### 1.3 Definitions
| Term | Meaning |
|---|---|
| Reading | A `(temperature, humidity, timestamp, source)` tuple from the sensor |
| Freshness / age | Wall-clock elapsed time since a reading was captured |
| Stale | A reading older than the configured freshness threshold (see DR-4) |
| Tool | A type conforming to `FoundationModels.Tool` that the model may call during reasoning |
| Escalation | Routing a query from the on-device model to a Private Cloud Compute model |
| Grounding | The property that an answer is derived from an actual tool-returned reading, not fabricated |

### 1.4 References
- WWDC26 — "What's new in the Foundation Models framework" (session 241)
- WWDC26 — "Bring an LLM provider to the Foundation Models framework" (session 339)
- WWDC26 — "Build with the new Apple Foundation Model on Private Cloud Compute" (session 319)
- `Agents.md` — Cricket coding standard
- CricketIOS source — `BluetoothViewModel.swift`, `CricketAppIntents.swift`, `RuuviTagViewModel.swift`

---

## 2. Overall Description

### 2.1 Product perspective
CricketAI is the terminal stage of the long-standing Cricket pipeline. The prior architecture routed sensor data out through App Groups → Shortcuts → an external skill → a cloud model. CricketAI collapses that into a single app: the reasoning happens **inside** the app, against the **on-device** model, with optional PCC escalation. The external, system-level surface (Siri/Shortcuts) is retained via App Intents so the app remains useful when not foregrounded.

```
Arduino Nano 33 BLE Sense Rev 2 / RuuviTag
        │  BLE (custom service + std ESS)
        ▼
CricketAI  ── CricketCore (reading store + freshness)
        ├── App Intents  ──► Siri / Shortcuts / Apple Intelligence   (system surface)
        └── Foundation Models
                ├── Tool: ReadEnvironmentalConditions
                ├── LanguageModelSession (on-device SystemLanguageModel)
                └── escalation ──► PrivateCloudComputeLanguageModel
```

### 2.2 User classes
- **Primary user:** the device owner (maker/hobbyist) asking environmental questions via Siri or the in-app chat.
- **Siri / Apple Intelligence:** an automated consumer of App Intents.
- **The on-device / PCC model:** an automated consumer of the `ReadEnvironmentalConditions` Tool.

### 2.3 Operating environment
- iPhone running iOS 27, Apple Intelligence enabled.
- A reachable BLE sensor (Arduino Nano 33 BLE Sense Rev 2 as connected peripheral, and/or RuuviTag as advertisement-only source).

### 2.4 Constraints
- **C-1** All new code MUST follow `Agents.md`: `@Observable @MainActor`, structured concurrency only (no GCD, no `Timer`, no `Thread.sleep`), Swift Testing for tests, no force-unwraps.
- **C-2** CoreBluetooth delegate callbacks MUST be `nonisolated`; Sendable values extracted before hopping to `@MainActor`.
- **C-3** No API keys or secrets in the repository; Keychain for any credentials.
- **C-4** No third-party frameworks without explicit approval. Apple's **Foundation Models framework utilities** package (for the `Skill` API) is permitted for Phase 4 subject to sign-off.
- **C-5** No widgets and no macOS target in v1.

### 2.5 Assumptions & dependencies
- **A-1** iOS 27 SDK / Xcode 27 will be available via public beta before Phases 3–4 begin.
- **A-2** PCC free-tier access requires enrollment in the **App Store Small Business Program** with < 2M lifetime downloads. CricketAI is assumed eligible. **[WWDC26]**
- **A-3** The BLE data formats and UUIDs from CricketIOS carry forward unchanged unless a new field (e.g., pressure) is added per §12.

---

## 3. System Architecture

### 3.1 Modules
| Module | Responsibility |
|---|---|
| `CricketCore` | Single source of truth for the latest reading + freshness. Owns BLE acquisition, staleness policy, and the read API consumed by both App Intents and Tools. **This module does not exist in CricketIOS and MUST be created (§12 O-2).** |
| `BluetoothService` | CoreBluetooth central; connects/reconnects, parses characteristics, feeds `CricketCore`. Ported from `BluetoothViewModel`. |
| `RuuviService` | Advertisement-only RuuviTag parsing. Ported from `RuuviTagViewModel`. |
| `AppIntentsSurface` | AppEntity/AppEnum + AppIntent definitions. Migrated from `CricketAppIntents.swift`. |
| `AgentSurface` | `ReadEnvironmentalConditions` Tool, `LanguageModelSession` management, escalation policy, profiles. |
| `EvalSuite` | `Evaluations`-framework test target validating grounding & freshness behavior. |
| `ChatUI` | Minimal conversational SwiftUI view (text field + response area). |

### 3.2 Data-source authority (resolves a CricketIOS inconsistency)
In CricketIOS, App Intents read `UserDefaults.standard` while the widget read a shared App Group whose suite name was the **placeholder** `group.com.yourcompany.CricketIOS`. CricketAI MUST have exactly one authoritative in-process reading source:

- **DR-0** `CricketCore` (an `@MainActor @Observable` type) is the single source of truth for the live reading. App Intents and Tools both read from it in-process. No `UserDefaults` round-trip is used for live data.
- **DR-0.1** If any cross-process persistence is retained, its App Group MUST use the real team identifier form `group.wm6h.CricketAI` (no trailing spaces) — never the `com.yourcompany` placeholder.

---

## 4. Functional Requirements

### 4.1 Sensor acquisition
- **FR-1** The system SHALL connect to the Arduino peripheral by targeted UUID scan, persist the peripheral UUID, and restore/reconnect on relaunch. **[SHIPPING]**
- **FR-2** The system SHALL parse temperature and humidity from the custom BLE service (IEEE-754 float32, little-endian) and/or standard ESS characteristics, and from RuuviTag RAWv1 advertisements.
- **FR-3** The system SHALL treat sensor sentinel values (temp `-32768`, humidity `65535`) as errors and NOT surface them as readings.
- **FR-4** Every accepted reading SHALL be stamped with a capture timestamp and a `source` (`.arduino` / `.ruuvi`).

### 4.2 Freshness contract (the core reliability requirement)
- **FR-5** `CricketCore` SHALL expose the latest reading together with its **age** and a computed **staleness** state.
- **FR-6** The read API SHALL return a discriminated result, not a bare value:
  `fresh(Reading)` | `stale(Reading, age:)` | `unavailable(reason:)`.
- **FR-7** When no sensor is connected and no cached reading exists, the read API SHALL return `unavailable` — never a fabricated or zero value.
- **FR-8** **[RESOLVED]** Background acquisition is **in scope for v1**: the app uses CoreBluetooth state preservation/restoration with the `bluetooth-central` background mode so readings continue while backgrounded. The "last-known reading + age" model (FR-6) still applies as the fallback whenever a live read is not currently available (e.g., sensor out of range).

### 4.3 App Intents surface (Phase 1)
- **FR-9** The system SHALL provide App Intents equivalent to CricketIOS's `GetLocalTemperatureIntent`, `GetLocalHumidityIntent`, `GetWorkshopConditionsIntent`, `GetSensorStatusIntent`, returning AppEntity values with `ProvidesDialog`.
- **FR-10** AppEntity queries SHALL use `EntityStringQuery` (live readings are not pre-indexable); the CricketIOS pattern of `entities(for:)` returning `[]` MUST be corrected so entities resolve for contextual reference.
- **FR-11** Where a matching assistant schema/domain exists, entities SHOULD adopt `@AssistantEntity(schema:)` / `@AssistantIntent(schema:)`. No environmental domain is known to exist; absent one, generic conformance is used. **[TBD confirm domains]**
- **FR-12** Intent dialogs SHALL disclose reading age when the underlying reading is `stale`.

### 4.4 In-app agent surface (Phase 2)
- **FR-13** The system SHALL define one `Tool`-conforming type, `ReadEnvironmentalConditions`, whose `call` returns the current reading (temperature °C/°F, relative humidity %, source, timestamp, **age**, staleness). **[SHIPPING]**
- **FR-14** The Tool's `description` and argument schema SHALL be written for model discoverability (purpose, when to invoke, units returned).
- **FR-15** The system SHALL create a `LanguageModelSession(model: SystemLanguageModel.default, tools: [ReadEnvironmentalConditions()])` and drive a reasoning loop from a minimal chat UI. **[SHIPPING]**
- **FR-16** The agent SHALL be instructed (via `Instructions`) that any environmental claim MUST come from the Tool, and that stale/unavailable readings MUST be disclosed to the user rather than smoothed over.

### 4.5 Escalation ladder (Phase 3)
- **FR-17** The system SHALL support running the same session against `PrivateCloudComputeLanguageModel` for queries classified as advice-oriented / high-stakes, using the same Tool and structured-output API. **[WWDC26]**
- **FR-18** Routing signal SHALL be query complexity, expressed via `ContextOptions.reasoningLevel` (`.light` on-device vs `.deep`/PCC). Exact routing heuristic is **[TBD]** (§12 O-4). **[WWDC26]**
- **FR-19** Escalation SHALL degrade gracefully to the on-device model if PCC is unavailable, and SHALL never block a simple factual query on network.

### 4.6 Dynamic profiles (Phase 4)
- **FR-20** The system MAY define named profiles (e.g., *quick reading*, *environmental advice*, *trend analysis*) using `DynamicProfile`/`Profile`, each supplying profile-specific `Instructions` and tool sets. **[WWDC26]**
- **FR-21** Procedural domain context (e.g., finish-curing rules) MAY be loaded via the `Skill` API from the Foundation Models framework utilities package. **[WWDC26]** Subject to C-4 sign-off.

---

## 5. AI / Agent Behavior Requirements

- **AB-1** The agent is a **dynamic-reasoning** agent: it decides at runtime whether to call the Tool, in what order to combine information, and how to phrase the recommendation. The tool-call sequence is NOT hard-coded.
- **AB-2** The agent MUST NOT fabricate a sensor value. If the Tool was not called, an environmental figure MUST NOT appear in the answer.
- **AB-3** For safety-adjacent questions (soldering, finishing, curing), the agent supplies domain knowledge from the model and grounds the *conditions* in the Tool reading. The model's domain knowledge is trusted; the sensor number is authoritative for current conditions.
- **AB-4** When the reading is `stale` or `unavailable`, the agent MUST state that explicitly and qualify or withhold its recommendation accordingly.

---

## 6. Data Requirements

- **DR-1** Reading model: `Reading { celsius: Double, fahrenheit: Double, relativeHumidity: Double, timestamp: Date, source: SensorSource }`.
- **DR-2** BLE (carried forward from CricketIOS / memory):
  - Custom service `5971E8F1-BC4D-4A5F-A6FD-3591131A98C6`
  - Temperature char `78B20AF1-E597-40C1-A69C-304205B7E099`
  - Humidity char `0BA15AA1-A805-4205-BC82-AF2E4A9364C5`
  - Format: IEEE-754 float32, 4 bytes, little-endian
  - Standard ESS fallbacks: temp `2A6E` (sint16×100), humidity `2A6F` (uint16×100)
  - RuuviTag manufacturer ID `0x0499`; RAWv1 when `data[2] == 0x03`
- **DR-3** **[RESOLVED]** **Pressure is excluded from v1 permanently.** It is not exposed by the sensor firmware, and CricketAI's purpose is *current hyperlocal conditions*, not weather-change forecasting — barometric pressure adds no value to the use cases (soldering, finishing, curing, comfort).
- **DR-4** Default freshness threshold: **[TBD]**, proposed 5 minutes for `fresh`, beyond which readings are `stale`. Configurable constant, not magic number.

---

## 7. External Interface Requirements

- **EI-1 (BLE):** CoreBluetooth central, `nonisolated` delegates, write flow-control and heartbeat keepalive as in CricketIOS.
- **EI-2 (Siri/Shortcuts):** App Intents is the sole system integration surface; app must expose intents to remain visible to the new Siri.
- **EI-3 (Foundation Models):** `SystemLanguageModel` **[SHIPPING]**; `PrivateCloudComputeLanguageModel` **[WWDC26]**; both via `LanguageModelSession`.

---

## 8. Non-Functional Requirements

- **NFR-1 (Privacy):** All default reasoning is on-device; PCC is privacy-preserving and requires no API key. No third-party network calls in v1.
- **NFR-2 (Performance):** A simple factual query ("what's the humidity?") MUST resolve on-device without network latency.
- **NFR-3 (Reliability):** BLE reconnect and reading acquisition MUST survive app relaunch (peripheral UUID persistence).
- **NFR-4 (Concurrency correctness):** Compiles clean under complete strict concurrency; no data races across the CB delegate / `@MainActor` boundary.
- **NFR-5 (Testability):** Core logic (parsing, freshness classification, routing) MUST be unit-testable with Swift Testing independent of live hardware.

---

## 9. Verification & Evaluation

> Distinction: the **model** supplies domain knowledge (it already "knows" soldering safety); the **Evaluations suite** verifies that CricketAI *wires the live sensor into that knowledge correctly*. It tests the app, not the model's general knowledge.

- **EV-1** An `Evaluations`-framework suite SHALL exercise the agent with a fixed battery of prompts and grade outputs. **[WWDC26]**
- **EV-2 (Grounding):** For any prompt containing an environmental figure in the answer, the grader SHALL assert the `ReadEnvironmentalConditions` Tool was actually invoked (no hallucinated numbers).
- **EV-3 (Freshness disclosure):** Given an injected **stale** reading, the grader SHALL assert the answer discloses staleness and qualifies/withholds the recommendation. This is the highest-value eval — a confident answer from a stale sensor is the primary user-harm case.
- **EV-4 (Unavailable handling):** Given `unavailable`, the answer SHALL not invent a value.
- **EV-5 (Phrasing robustness):** Semantically equivalent prompts ("is it safe to solder?", "can I solder in here now?", "solder ok?") SHALL all trigger the Tool and yield consistent recommendations.
- **EV-6 (Routing):** Simple factual queries SHALL stay on-device; advice queries SHALL be eligible for escalation (Phase 3+).
- **EV-7 (App Intents routing):** `AppIntentsTesting` (**[TBD]** confirm framework name/availability) SHALL validate Siri routing to each intent before ship.

---

## 10. Migration from CricketIOS

The WWDC25 App Intents work is a **foundation, not throwaway**. Migration is additive:
1. Port `BluetoothViewModel`/`RuuviTagViewModel` into `BluetoothService`/`RuuviService` feeding `CricketCore`.
2. Extract `CricketCore` as the single reading authority (new work).
3. Fix `EntityQuery.entities(for:)` to resolve entities (was `[]`).
4. Replace `UserDefaults.standard` reads in intents with `CricketCore` reads.
5. Correct the App Group identifier if any persistence is retained.
6. Drop widgets and the macOS `#if os(macOS)` branches.

---

## 11. Phased Roadmap (requirement mapping)

| Phase | Goal | Requirements | Buildable when |
|---|---|---|---|
| **Phase 0** | Data & freshness contract | FR-4–FR-8, DR-0–DR-4, `CricketCore` | **Now** (26.5 SDK) |
| **Phase 1** | App Intents migration | FR-9–FR-12, EV-7 | **Now** |
| **Phase 2** | On-device Tool loop | FR-13–FR-16, EV-1–EV-5 | **Now** (26.5 SDK) |
| **Phase 3** | PCC escalation ladder | FR-17–FR-19, EV-6 | iOS 27 SDK (public beta) |
| **Phase 4** | Dynamic profiles / Skills | FR-20–FR-21 | iOS 27 SDK + utilities pkg |

Ordering rationale: Phase 0 de-risks the one problem no API solves (freshness). Phases 1–2 ship on today's SDK. Phases 3–4 gate on the public beta.

---

## 12. Open Issues

| ID | Issue | Owner decision needed |
|---|---|---|
| ~~O-1~~ | **RESOLVED** — background BLE via CB state restoration is in scope (FR-8) | ✅ Decided 2026-07-12 |
| **O-2** | `CricketCore` shape: standalone `@Observable` vs. actor-backed store | Design — see `CricketCore_sketch.swift` |
| ~~O-3~~ | **RESOLVED** — pressure excluded from v1 permanently (DR-3) | ✅ Decided 2026-07-12 |
| **O-4** | Escalation routing heuristic — what classifies "advice" vs "factual" (FR-18) | Design + eval-driven tuning |
| **O-5** | Exact iOS 27 identifier spellings (`Skill`, `DynamicProfile`, `PrivateCloudComputeLanguageModel`, `ContextOptions`) | Re-confirm against installed SDK when public beta lands |
| **O-6** | `AppIntentsTesting` framework name/availability (EV-7) | Confirm on beta |
| **O-7** | Freshness thresholds (DR-4) | Product tuning |

---

*End of SRS v0.1. API items tagged **[WWDC26]** are verified against Apple session announcements but MUST be re-confirmed against the installed iOS 27 SDK before implementation; items tagged **[SHIPPING]** are buildable against the current iOS 26.5 SDK.*
