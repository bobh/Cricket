# iOS BLE_Central Troubleshooting - FIXED

## Issue Summary
The iOS app was not requesting Bluetooth permissions and never reached `.poweredOn` state.

## Root Cause
The Xcode project had `GENERATE_INFOPLIST_FILE = NO` but was missing the `INFOPLIST_FILE` build setting, so the Info.plist with Bluetooth usage descriptions was never embedded in the app bundle.

## Fix Applied
Added `INFOPLIST_FILE = BLE_Central/Info.plist;` to both Debug and Release build configurations in `project.pbxproj`.

## Verification
Build succeeded and Info.plist is now properly embedded with:
- `NSBluetoothAlwaysUsageDescription` ✅
- `NSBluetoothPeripheralUsageDescription` ✅
- `CFBundleDisplayName: "Demetor"` ✅

## Testing on Physical Device

### Prerequisites
1. Arduino Nano 33 Sense Rev 2 running Demetor_Peripheral_1 sketch
2. Arduino powered on and advertising BLE service UUID: `5971E8F1-BC4D-4A5F-A6FD-3591131A98C6`

### Expected Behavior
1. **First Launch**: iOS should prompt "Demetor would like to use Bluetooth" → Tap **Allow**
2. **Console Output** (view with debug print statements):
   ```
   [BLE] Central state changed to: 5
   [BLE] State is poweredOn. Starting scan...
   [BLE] startScanning() called. Current state: 5
   [BLE] Scanning with services: [5971E8F1-BC4D-4A5F-A6FD-3591131A98C6]
   [BLE] Discovered peripheral: <UUID> name=<Arduino name> RSSI=<signal>
   [BLE] Connected to peripheral: <UUID>
   [BLE] Discovered services for: <UUID>
   [BLE] Discovered characteristics for service: 5971E8F1-BC4D-4A5F-A6FD-3591131A98C6
   [BLE] Updated value for characteristic: 78B20AF1-E597-40C1-A69C-304205B7E099
   [BLE] Updated value for characteristic: 0BA15AA1-A805-4205-BC82-AF2E4A9364C5
   ```
3. **UI Updates**: Temperature and humidity should display real values from Arduino

### If Bluetooth Still Doesn't Work
1. **Check System Settings**: Settings → Privacy & Security → Bluetooth → Demetor (should be listed)
2. **Reset Permissions**: Delete app, reinstall, test again
3. **Check Arduino**: Verify Arduino is advertising (use LightBlue or nRF Connect app to scan)
4. **Bluetooth State**:
   - State 0 = unknown
   - State 1 = resetting
   - State 2 = unsupported
   - State 3 = unauthorized (permission denied)
   - State 4 = poweredOff
   - State 5 = poweredOn ✅

### Common Issues
- **State 3 (unauthorized)**: Permission denied → Check Settings → Privacy → Bluetooth
- **State 4 (poweredOff)**: Turn on Bluetooth in Control Center
- **No peripheral discovered**: Arduino not advertising or wrong service UUID
- **Connected but no data**: Check characteristic UUIDs match Arduino sketch

## Console Logging
The iOS ContentView.swift has extensive debug logging enabled via `print()` statements. View output in Xcode console when running on device.

Key log prefixes:
- `[BLE]` - Bluetooth events
- All CoreBluetooth delegate methods log their calls

## Next Steps
1. Deploy to physical iPhone/iPad (Bluetooth doesn't work in simulator)
2. Verify permission prompt appears
3. Check console for `[BLE] State is poweredOn`
4. Confirm Arduino discovery and connection
5. Verify temperature/humidity data displays

## Files Modified
- `/Users/bobh/Desktop/Demetor/IOS/BLE_Central.xcodeproj/project.pbxproj` - Added INFOPLIST_FILE setting
- `/Users/bobh/Desktop/Demetor/IOS/BLE_Central/Info.plist` - Already had correct Bluetooth permissions
- `/Users/bobh/Desktop/Demetor/IOS/BLE_Central/ContentView.swift` - Already has debug logging
