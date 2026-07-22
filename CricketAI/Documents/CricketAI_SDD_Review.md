# CricketAI SDD — SDK Verification Review

| | |
|---|---|
| **Reviews** | `CricketAI_SDD.md` (Draft v0.1, 2026-07-13) |
| **Status** | ✅ COMPLETE — verified against iOS 27.0 SDK (Xcode 27.0 beta 3) on 2026-07-16 |
| **Baseline SDK** | iOS 26.5 (Xcode 26.6); confirmed against iOS 27.0 SDK — full public type surfaces enumerated, not keyword-grepped |
| **Created** | 2026-07-15; iOS 27 pass 2026-07-16 |
| **Constraint** | Document-only. No implementation until user directs (SRS/SDD preliminary). |

---

## ⭐ Acid Test (project essence — evaluate every decision against this)

> **Is it safe to work on CMOS devices right now?**

Success = model uses built-in ESD/CMOS knowledge, **calls CricketAI's local reading tool** for temp/humidity, **discloses freshness**, and answers **without** asking for weather/location/web/external access. (SDD §1, §10.3.)

---

## Verdict
Architecture and CricketAI-owned design carry no SDK risk. Of ~15 flagged SDK unknowns, most are already resolved against 26.5; the baseline surfaced three design assumptions that look incorrect and must be confirmed on iOS 27 before building Phase 2–5.

## A. Resolved against 26.5 (SDD over-hedged; can specify now)
| SDD ref | 26.5 reality |
|---|---|
| §9.1 Tool "spelling TBD" | `protocol Tool<Arguments, Output>: Sendable`; `ToolOutput`, `ToolCall`, `ToolDefinition` |
| §8.2 macro names (line 216) | `@AssistantEntity(schema:)` / `@AssistantIntent(schema:)`; domains via `AssistantSchemas.Entity` |
| §8.3 entity query | `EntityStringQuery` exists (also `EntityQuery`, `EnumerableEntityQuery`) |
| §9.3 structured output | `@Generable` + `GeneratedContent` + `GenerationSchema` / `DynamicGenerationSchema` |
| §10.2 instructions | `Instructions` + `@InstructionsBuilder` |
| §11 session | `LanguageModelSession(model:tools:instructions:)`, `SystemLanguageModel.default`, `.availability` |

## B. Design concerns — resolved against iOS 27
| # | SDD ref | Baseline (26.5) concern | iOS 27 verdict |
|---|---|---|---|
| B1 | §11.2, §11.3, SDD-5, Phase 5 | PCC escalation may not be a public API (26.5: on-device only) | ✅ **RESOLVED — PCC is public in iOS 27.** `PrivateCloudComputeLanguageModel` exists. §11 escalation is buildable. **New constraint:** it carries `availability`, `quotaUsage`, `RateLimited`, `QuotaLimitReached`, `ServiceUnavailable`, `NetworkFailure` — routing/error handling (§11.3, §14) must handle quota + network failure and fall back to on-device. |
| B2 | §13.3, §19 | No "evaluation suite" API | ⚠️ **STANDS.** iOS 27 still ships only `LanguageModelFeedback`. Agent evals are DIY Swift Testing. Reword §13.3/§19. |
| B3 | §8.1, §13.2 | No dedicated App Intents test framework | Stands — test intents via `perform()`. Reword. |
| B4 | §19 | "Dynamic profile/instructions" ill-defined | ✅ **RESOLVED — real in iOS 27.** `DynamicInstructions`, `DynamicProfile`, `DynamicProfileModifier`, `Profile`, `@DynamicInstructionsBuilder`. §19/Phase 5 dynamic profiles are supported. |

## C. iOS 27 diff — COMPLETE (verified 2026-07-16 vs iPhoneOS27.0.sdk)
| # | SDD ref | Result |
|---|---|---|
| C1 | §8.2, SDD-2, §18.5 | ✅ **No environmental/measurement/weather/sensor assistant-schema domain in iOS 27.** Catalog expanded ~14→~25 domains (adds Calendar, Clock, Maps, Messages, Notes, Phone, Reminders, workouts/dive, video, audio) but nothing hyperlocal-environmental. `Temperature`/`UnitTemperature`/`Measurement` = Foundation `Measurement<UnitTemperature>` *parameter* support, NOT a schema. → **§8.2 = generic `AppEntity`/`AppIntent` conformance, confirmed.** |
| C2 | §8.5, SDD-6 | ✅ **Supported.** Use `associateAppEntity(_:priority:)` (associate on-screen entity so Siri resolves "this reading") + `SnippetIntent` / `ShowsSnippetView` (entity snippet presentation) + SwiftUI `.userActivity`. Also `IndexedEntity`. SDD should name these instead of "view annotations." |
| C3 | §19 | ✅ `Tool<Arguments, Output>: Sendable` unchanged. `LanguageModelSession(model:tools:instructions:)` unchanged (+ new `transcript:` init). New in 27: `ReasoningLevel`, image `Attachment`s, general `LanguageModel`/`LanguageModelExecutor` protocols. `@Generable`/`GeneratedContent`/`GenerationSchema` unchanged. |
| C4 | B1 | ✅ PCC public API present — see B1. |

**iOS 27 SDK path used:** `…/Xcode-beta 2.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/{AppIntents,FoundationModels}.framework/Modules/*.swiftmodule/*.swiftinterface`

## D. No SDK risk (fine as written)
BLE UUIDs/parsing (§7.1, app-owned); App Group `group.wm6h.CricketAI` (§7.3, fixed & matches); `CricketCore` `@MainActor @Observable` + `nonisolated` CB delegates (§5.2, matches Agents.md); `Reading`/`ReadingResult`/`Duration` (§6); Phases 0–1 buildable now (§16).

## Recommended SDD edits (document-only, ready to apply on user's go)
1. **§8.2:** replace "candidate / if available" with firm decision — **generic `AppEntity`/`AppIntent` conformance** — plus dated note "verified against iOS 27.0 SDK: no environmental assistant-schema domain." Delete the "Preferred design" column.
2. **§11.2 / SDD-5 / Phase 5 (PCC):** keep the escalation design — it's real (`PrivateCloudComputeLanguageModel`) — but add handling for `quotaUsage` / `RateLimited` / `ServiceUnavailable` / `NetworkFailure` and an explicit on-device fallback. Update §11.3 routing and §14 accordingly.
3. **§8.5 / SDD-6:** rename "view annotations" → the actual APIs: `associateAppEntity(_:priority:)` + `SnippetIntent`/`ShowsSnippetView` + `.userActivity`.
4. **§13.3 / §8.1 / §19:** reword "evaluation suite" / "App Intents testing" → DIY Swift Testing + intent `perform()` (no Apple framework).
5. **§19 / Phase 5:** confirm "dynamic profile/instructions" against real types (`DynamicProfile`, `DynamicInstructions`, `DynamicProfileModifier`).
6. **Header/§17:** reconcile — the iOS 27 SDK is now installed (Xcode 27.0 beta 3); resolve SDD-1/SDD-2/SDD-6 as verified.

## Non-SDK housekeeping noticed during this pass
- **Xcode 27 beta lives at `~/Desktop/Xcode-beta 2.app`** (the " 2" suffix implies a duplicate expansion) — not in `/Applications`, so `xcrun`/`xcodebuild` still default to 26.6. Move it to `/Applications` (and optionally `xcode-select`) for normal use.
- **Stray `~/Desktop/CricketAI/CricketIOS.xcodeproj` exists** — unexpected; the real project is `~/Desktop/Projects/Cricket/CricketAI/CricketAI.xcodeproj`. Needs identification (old extract / accidental copy?) before it causes confusion.
