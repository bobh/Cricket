# CricketAI — Stage 4 Device Test Checklist

**Scope:** the live-hardware verification of the BLE → `CricketCore` → UI/App-Intents path
(Phase 1, Stage 4). The on-device Foundation Models work and the ⭐acid test are **NOT** in
scope here — that's Phase 3+. Primary observation surface is the app's **status card**
(source label, freshness note, LED), since the `CricketBLE` services don't emit logs.

**Hardware:** iPhone 15 Pro Max (iOS 27 developer beta 3), the Arduino (Nano 33 BLE Sense
Rev 2), and the **current** RuuviTag. The new pressure-capable RuuviTag is en route; re-run
sections A/B with it once it arrives to validate the optional pressure/motion fields.

---

## 0. Pre-flight
- [ ] In Xcode: select the **iPhone 15 Pro Max** as destination; let it finish "preparing device for development."
- [ ] Target signing = **Automatic**, team **wm6h (68U33HS2JC)**; confirm the **App Group `group.wm6h.CricketAI`** capability is present and the profile builds.
- [ ] Build & run to device with real signing (not the `CODE_SIGNING_ALLOWED=NO` compile flag). First launch: **grant the Bluetooth permission** prompt.
- [ ] Power the **Arduino** (advertising) and the **current RuuviTag**. Have a reference thermometer/hygrometer (or the Ruuvi Station app) handy for B1.

## A. Basic acquisition
- [ ] **A1 — Arduino only:** power only the Arduino → app connects; status shows **source = "Arduino Nano 33 Sense Rev 2"**, live temp + humidity, LED **green / "Live reading."**
- [ ] **A2 — RuuviTag only:** power only the Ruuvi → within a few seconds shows **source = "RuuviTag"**, live values, LED green.
- [ ] **A3 — Both powered:** source resolves to **RuuviTag** (arbitration prefers Ruuvi).

## B. Data correctness (validates parsing on real hardware)
- [ ] **B1 — Accuracy:** app temp/humidity match your reference within tolerance (~±0.5 °C / ±a few %RH). Real-hardware confirmation of the float32 decode + the RAWv2 offset/overflow fix.
- [ ] **B2 — No boot placeholder:** on Arduino connect, it should **never flash `0.0 °C / 0.0 %`** before real data (the assembler drops the exact-(0,0) startup value).
- [ ] **B3 — Optional metrics absent (expected):** with the **current** Ruuvi + current Arduino firmware, the **pressure/motion row should NOT appear** (both nil). Correct for now; the new pressure RuuviTag will light it up.

## C. Freshness (5-minute threshold, DR-4)
- [ ] **C1 — Fresh:** active reading → status "Live reading", note **"current"**, LED green.
- [ ] **C2 — Stale:** power off / move all sensors out of range, **wait > 5 min** → status "Stale reading", note **"last updated about N minutes ago"**, LED **amber, blinking**.
- [ ] **C3 — Recover:** re-power → returns to fresh.

## D. Unavailable reasons — ⚠️ test on a fresh state
> Once *any* reading has been received, the app shows the **last-known reading aging to
> stale** (the intended fallback), **not** an "unavailable" message. Unavailable reasons only
> surface when there's **no cached reading**. To test D1–D2, delete/reinstall the app first
> (clears the App Group store) or test before the first reading arrives.
- [ ] **D1 — Never connected:** fresh install, sensors off → **"Waiting for first reading…"**, LED red.
- [ ] **D2 — Bluetooth off:** fresh install, turn Bluetooth off in Settings → **"Bluetooth is off"**, LED red.

## E. Persistence & reconnect (NFR-3)
- [ ] **E1 — Warm start:** with a good reading showing, force-quit the app, relaunch → the **last reading appears immediately** on launch (from the App Group), with correct freshness, *before* a new packet arrives.
- [ ] **E2 — Targeted reconnect:** after force-quit + relaunch with the Arduino on, it **reconnects via the persisted peripheral UUID** (noticeably faster than a cold scan).

## F. Background (FR-8)
- [ ] **F1 — Continuity:** with a live reading, send the app to the background (home / app-switcher, don't kill), wait ~1 min, reopen → the reading **timestamp is recent** (it kept receiving in the background).
- [ ] **F2 — Restoration (best-effort):** true relaunch-after-termination restoration is hard to force manually — note it if observed, don't block on it.

## G. Siri / App Intents (FR-9, FR-12, AB-4)
- [ ] **G1 — Value + freshness:** Shortcuts → run **"Get Local Temperature"** (or Siri "what's my temperature in Cricket") → speaks the value.
- [ ] **G2 — Stale disclosure:** with a stale reading (C2), ask again → hears **"…though that reading was last updated about N minutes ago."**
- [ ] **G3 — Unavailable:** fresh state / BT off with no cached reading → intent speaks the **unavailable reason** (never a fabricated number).
- [ ] **G4 — Status:** **"Get Sensor Status"** → speaks connection + freshness.
- [ ] **G5 — Combined:** **"Get Workshop Conditions"** → temp + humidity + source + freshness in one reply.

## H. Arbitration edge (slow — budget ~5 min)
- [ ] **H1 — Ruuvi wins:** both live → source = RuuviTag.
- [ ] **H2 — Fallback:** with both live, stop the Ruuvi (remove battery / take it far away), keep the Arduino on. For up to 5 min the app keeps showing the **aging Ruuvi** reading; once that reading passes the 5-min staleness threshold, the next **Arduino** reading takes over (source → Arduino). This delay is by design.

---

## If something fails — quick suspects
- No connection at all → Bluetooth permission not granted, or Arduino not advertising the service UUID `5971E8F1-…`.
- Intent says "no data" while the app shows a reading → App Group mismatch (`group.wm6h.CricketAI`) between the app and the intent's provisioning profile.
- Won't install → signing/team, or deployment target (must be ≤ the device's iOS 27 beta 3).

## Notes / anomalies
_(record observations here during the run)_
