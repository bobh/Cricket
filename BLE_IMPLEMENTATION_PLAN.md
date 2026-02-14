# Core Bluetooth Improvements - Implementation Plan

**Project**: Cricket macOS/iOS Environmental Monitoring
**Date**: February 12, 2026
**Executor**: Claude Sonnet 4.5
**Duration**: Estimated 1-2 sessions
**User Activity**: WWDC research and planning (not blocked)

---

## Overview

Implementing Core Bluetooth improvements identified in:
- `BLE_CRITICAL_FIXES.md` (Priority 1 fixes)
- `BLE_ADVANCED_CONSIDERATIONS.md` (Advanced features)

**Goals**:
1. ✅ More reliable BLE connections
2. ✅ Better user experience (clear error messages)
3. ✅ Development efficiency (cache management)
4. ✅ Future-ready (write flow control, background support)
5. ✅ Ambient intelligence preparation (background execution)

---

## Task Breakdown

### Task 1: Apply Priority 1 BLE Critical Fixes (macOS) ⚡
**Priority**: CRITICAL
**Duration**: 30-45 minutes
**Blocks**: None

**Changes**:
1. **Service Filtering** (Lines 105, 129)
   - Change: `withServices: nil` → `withServices: [environmentalSensingServiceUUID]`
   - Impact: Power efficiency, faster discovery

2. **Complete State Handling** (Lines 102-109)
   - Replace simple if/else with comprehensive switch statement
   - Handle all 7 CBManagerState cases
   - Impact: Better UX, actionable error messages

3. **Characteristic Storage** (Add properties + update lines 162-167)
   - Add: `temperatureCharacteristic` and `humidityCharacteristic` properties
   - Store references during discovery
   - Impact: Code efficiency, no repeated UUID searches

**Files**: `CricketMac/CricketMac/BluetoothViewModel.swift`

**Testing**: Build, verify Arduino connection works

---

### Task 2: Implement Manual BLE Cache Clear 🗄️
**Priority**: HIGH
**Duration**: 30 minutes
**Blocks**: None
**Dependencies**: Task 1 complete

**Changes**:
1. Add `clearBLECache()` method to BluetoothViewModel
2. Add UI control (button in Settings or debug menu)
3. Clear UserDefaults cached peripheral data
4. Restart scanning after clear

**Files**:
- `CricketMac/CricketMac/BluetoothViewModel.swift`
- `CricketMac/CricketMac/SettingsView.swift` (or ContentView)

**Benefits**: Eliminates stale data during Arduino firmware development

**Testing**: Click button, verify disconnect and rescan

---

### Task 3: Implement Write Flow Control 📝
**Priority**: MEDIUM
**Duration**: 45 minutes
**Blocks**: None
**Dependencies**: Task 1 complete

**Changes**:
1. Add write queue: `private var writeQueue: [Data] = []`
2. Add ready flag: `private var isReadyToWrite: Bool = true`
3. Implement `writeValue(_:withResponse:)` with flow control
4. Implement `peripheralIsReady(toSendWriteWithoutResponse:)` delegate
5. Add example `setLEDColor(_:)` method

**Files**: `CricketMac/CricketMac/BluetoothViewModel.swift`

**Benefits**: Ready for LED control and configuration writes

**Testing**: Code review (no writes currently in use)

---

### Task 4: Implement Background Execution Support 🔄
**Priority**: HIGH (for ambient intelligence)
**Duration**: 1-1.5 hours
**Blocks**: None
**Dependencies**: Task 1 complete

**Changes**:
1. Add `preservePeripheralState()` - save peripheral UUID
2. Add `restorePeripheralConnection()` - restore on launch
3. Add background/foreground transition handlers
4. Adjust heartbeat interval based on app state
5. Verify Info.plist keys (already present)

**Files**:
- `CricketMac/CricketMac/BluetoothViewModel.swift`
- `CricketMac/CricketMac/CricketMac.swift` (app lifecycle)

**Benefits**: Enables widgets, menu bar operation, continuous monitoring

**Testing**:
- Close window, verify connection maintained
- Relaunch app, verify reconnection
- Background heartbeat interval changes

---

### Task 5: Apply Same Improvements to iOS Version 📱
**Priority**: MEDIUM
**Duration**: 1-1.5 hours
**Blocks**: None
**Dependencies**: Tasks 1-4 complete (macOS verified)

**Changes**: Apply all improvements to iOS version:
1. Priority 1 critical fixes
2. Manual cache clear
3. Write flow control
4. Background execution (with iOS-specific UIApplication hooks)

**Files**: `IOS--BLE Central/BLE_Central/BluetoothViewModel.swift`

**Benefits**: Feature parity across platforms

**Testing**: Build iOS app, verify improvements

---

### Task 6: Test and Verify All Improvements 🧪
**Priority**: CRITICAL
**Duration**: 30-45 minutes
**Blocks**: None
**Dependencies**: Tasks 1-5 complete

**Test Scenarios**:
1. ✅ Bluetooth off → clear error message
2. ✅ Bluetooth on → successful scan
3. ✅ Arduino connection → temperature/humidity updates
4. ✅ Manual cache clear → disconnect and rescan
5. ✅ Background operation → connection maintained
6. ✅ Reconnection after disconnect → automatic
7. ✅ Service filtering → only discovers Arduino

**Checklist**: From BLE_CRITICAL_FIXES.md and BLE_ADVANCED_CONSIDERATIONS.md

**Success**: All scenarios pass, no regressions

---

### Task 7: Update Documentation 📚
**Priority**: MEDIUM
**Duration**: 20-30 minutes
**Blocks**: None
**Dependencies**: Task 6 complete

**Updates**:
1. CONTEXT_RESTORE.md - Add section on BLE improvements completed
2. PROJECT_STATUS.md - Update BLE implementation status
3. Create IMPLEMENTATION_LOG.md - Detailed change log

**Benefits**: Future developers understand changes, context restoration accurate

---

## Implementation Order

### Session 1 (Core Improvements)
```
1. Task 1: Priority 1 Fixes (macOS)      [30-45 min] ⚡
2. Task 2: Cache Clear                   [30 min]    🗄️
3. Build & Quick Test                    [10 min]    ✅
4. Task 3: Write Flow Control            [45 min]    📝
5. Build & Verify                        [10 min]    ✅

Total: ~2-2.5 hours
```

### Session 2 (Advanced Features)
```
6. Task 4: Background Execution          [1-1.5 hrs] 🔄
7. Build & Test Background               [15 min]    ✅
8. Task 5: iOS Version                   [1-1.5 hrs] 📱
9. Build iOS                             [10 min]    ✅

Total: ~2.5-3 hours
```

### Session 3 (Testing & Documentation)
```
10. Task 6: Comprehensive Testing        [30-45 min] 🧪
11. Task 7: Documentation Updates        [20-30 min] 📚
12. Final Verification                   [15 min]    ✅

Total: ~1-1.5 hours
```

**Total Time**: 6-7 hours across 3 sessions

---

## Git Commit Strategy

Each task gets its own commit:

```bash
git commit -m "BLE: Apply Priority 1 critical fixes to macOS

- Use service filtering in all scan calls
- Complete state handling with switch statement
- Store characteristic references after discovery

Improves power efficiency and user experience.
Ref: BLE_CRITICAL_FIXES.md"

git commit -m "BLE: Add manual cache clear functionality

Allows clearing stale BLE cache during development.
Accessible from Settings menu.

Ref: BLE_ADVANCED_CONSIDERATIONS.md Section 3"

# ... etc
```

**Benefits**:
- Clean git history
- Easy to review changes
- Easy to revert if needed
- Clear documentation in commits

---

## Testing Strategy

### Automated Testing
- ✅ Build succeeds on both platforms
- ✅ Zero compiler warnings
- ✅ No SwiftLint errors (if configured)

### Manual Testing (Requires Arduino)
- ✅ Arduino discovery works
- ✅ Connection established
- ✅ Temperature/humidity updates
- ✅ Cache clear functions
- ✅ Background operation (window closed)
- ✅ State restoration (relaunch)

### Manual Testing (No Arduino Needed)
- ✅ Bluetooth off → error message
- ✅ Code compiles and runs
- ✅ UI elements accessible

**Note**: Some tests require physical Arduino. Will test what's possible without hardware and document remaining tests for user verification.

---

## Risk Mitigation

### Before Starting
✅ Git repository up to date
✅ Current code builds successfully
✅ Backup in git (can revert anytime)

### During Implementation
✅ Each task independent (can pause between tasks)
✅ Incremental commits (easy rollback)
✅ Build after each major change

### If Issues Arise
- Revert last commit if breaking change
- Document issue for user review
- Continue with other independent tasks

---

## Success Criteria

### Technical
- ✅ All tasks completed
- ✅ Both platforms build with zero warnings
- ✅ No regressions in existing functionality
- ✅ Code follows patterns from CORE_BLUETOOTH_BEST_PRACTICES.md

### Strategic
- ✅ Ready for widget implementation
- ✅ Ready for WWDC 26 demonstrations
- ✅ Ambient intelligence foundation solid
- ✅ Development efficiency improved

### Documentation
- ✅ All changes documented
- ✅ CONTEXT_RESTORE.md updated
- ✅ Implementation log created
- ✅ Future developers can understand changes

---

## Communication Plan

### After Each Session
Report to user:
- ✅ Tasks completed
- ✅ Commits pushed
- ✅ Any issues encountered
- ✅ What's ready for testing

### Final Report
- ✅ Summary of all changes
- ✅ Testing recommendations
- ✅ What to verify with Arduino hardware
- ✅ Next steps (if any)

---

## User Action Required

### During Implementation
❌ **NONE** - Focus on WWDC research!

### After Implementation Complete
✅ **Optional**: Test with physical Arduino when convenient
✅ **Optional**: Verify improvements work as expected

### If Issues Found
✅ Report to Claude for fixes
✅ All changes in git (easy to revert/modify)

---

## Implementation Environment

**Platform**: M4 MacBook Air, macOS 26.1
**Xcode**: 17C52 (will use standard xcodebuild)
**Projects**:
- macOS: `/Users/bobh/Desktop/Projects/Cricket/CricketMac`
- iOS: `/Users/bobh/Desktop/Projects/Cricket/IOS--BLE Central`

**Build Commands**:
```bash
# macOS
xcodebuild -project "CricketMac/CricketMac.xcodeproj" \
  -scheme Cricket_mac -destination 'platform=macOS' build

# iOS
xcodebuild -project "IOS--BLE Central/BLE_Central.xcodeproj" \
  -target BLE_Central -sdk iphonesimulator26.2 build
```

---

## Timeline

**Start**: When user approves plan
**Sessions**: 3 sessions (can be done across multiple days)
**Total Time**: 6-7 hours
**Completion**: All improvements implemented, tested, documented

**User can continue WWDC research uninterrupted!** 🎓

---

## Approval

Ready to begin implementation when approved.

**User**: Review and approve this plan
**Claude**: Execute tasks 1-7 in order
**Result**: Cricket has production-ready Core Bluetooth implementation

---

**Document**: `/Users/bobh/Desktop/Projects/Cricket/BLE_IMPLEMENTATION_PLAN.md`
**Tasks**: Created in task system (use `/tasks` to view progress)
**Status**: ⏳ Awaiting approval to begin

---

*This implementation will not block your WWDC research and planning activities.* ✅
