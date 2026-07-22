# Cricket Widget Implementation Guide

Complete step-by-step guide to add Widgets to your Cricket iOS app.

## Overview

This guide will help you add three widget sizes:
- **Small**: Shows temperature only with cricket icon
- **Medium**: Shows both temperature and humidity side-by-side
- **Large**: Full details with status and timestamp

## Step 1: Add Widget Extension Target

1. Open `CricketIOS.xcodeproj` in Xcode
2. **File** → **New** → **Target**
3. Select **Widget Extension**
4. Configure:
   - Product Name: `CricketWidget`
   - Team: (Your development team)
   - Language: **Swift**
   - Include Configuration Intent: **NO** (uncheck)
5. Click **Finish**
6. When prompted "Activate CricketWidget scheme?", click **Activate**

## Step 2: Configure App Groups

The widget needs access to the same data as the main app via App Groups.

### For CricketWidget Target:
1. Select **CricketWidget** target in project navigator
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability** button
4. Search for and add **App Groups**
5. Check the box: `group.com.yourcompany.CricketIOS`
6. Make sure your development team is selected in **Signing**

### Verify Main App Also Has App Group:
1. Select **CricketIOS** target
2. Verify **App Groups** capability exists
3. Verify `group.com.yourcompany.CricketIOS` is checked

## Step 3: Replace Widget Code

1. In Xcode Project Navigator, find **CricketWidget** folder
2. Delete the default `CricketWidget.swift` file (Move to Trash)
3. **Right-click** on **CricketWidget** folder → **Add Files to "CricketIOS"**
4. Navigate to `/Users/bobh/Desktop/Cricket/CricketIOS/`
5. Select `CricketWidget_Code.swift`
6. **IMPORTANT**: Make sure "Target Membership" shows **CricketWidget** checked
7. Rename it in Xcode to `CricketWidget.swift` (optional, for clarity)

## Step 4: Update Info.plist (If Needed)

The widget should automatically have the correct Info.plist. Verify:

1. Select **CricketWidget** folder
2. Open `Info.plist`
3. Verify these keys exist:
   - `NSExtension` → `NSExtensionPointIdentifier` = `com.apple.widgetkit-extension`

## Step 5: Build and Test

### Build the Widget:
1. Select **CricketWidget** scheme in Xcode toolbar
2. Select your iPhone 15 device as destination
3. **Product** → **Build** (⌘B)
4. Fix any errors (should build cleanly)

### Test on Device:
1. **Product** → **Run** (⌘R) with CricketWidget scheme
2. This will install the widget on your device
3. The app will launch but widgets won't show yet

### Add Widget to Home Screen:
1. Long-press on iPhone home screen
2. Tap **+** button (top left)
3. Search for **"Cricket"**
4. Select **Cricket Sensor**
5. Choose widget size (Small, Medium, or Large)
6. Tap **Add Widget**
7. Tap **Done**

### Verify Data Appears:
1. Open main Cricket app
2. Ensure sensor is connected and showing data
3. Go back to home screen
4. Widget should display current temperature/humidity
5. Wait 5 minutes for automatic update, or:
   - Remove and re-add widget to force refresh

## Step 6: Build Main App with Widget

Once widget is working:

1. Switch scheme back to **CricketIOS** (not CricketWidget)
2. Select your iPhone 15 device
3. **Product** → **Clean Build Folder** (⇧⌘K)
4. **Product** → **Build** (⌘B)
5. Verify no errors or warnings

## Step 7: Archive for App Store

When ready to submit:

1. Select **CricketIOS** scheme
2. Select **Any iOS Device (arm64)** as destination
3. **Product** → **Archive**
4. Wait for archive to complete
5. Organizer window opens → Click **Distribute App**
6. Follow App Store submission process

## Troubleshooting

### Widget Shows "-- --" or No Data

**Solution:**
- Ensure main app has written data to UserDefaults
- Verify App Group name matches exactly in both targets
- Try removing and re-adding the widget
- Check that `group.com.yourcompany.CricketIOS` capability is enabled on both targets

### Widget Not Appearing in Widget Gallery

**Solution:**
- Ensure you built and ran the **CricketWidget** scheme at least once
- Restart iPhone
- Rebuild main app with widget included

### Build Errors

**Common Issues:**
1. **Missing App Group**: Add capability to both targets
2. **Wrong Target Membership**: Ensure `CricketWidget.swift` is only in CricketWidget target
3. **Duplicate Symbols**: Make sure you deleted the default widget file

### Widget Not Updating

**Solution:**
- Widgets update every 5 minutes by default
- Force update: Remove widget and add it again
- Check that main app is saving to UserDefaults with `synchronize()`

## Widget Features

### What the Widgets Show:

**Small Widget (2x2):**
- Cricket sensor icon
- Current temperature
- Sensor name (Arduino/RuuviTag)

**Medium Widget (4x2):**
- Temperature with thermometer icon
- Humidity with drop icon
- Divider between metrics
- Sensor badge in corner

**Large Widget (4x4):**
- Full header with app branding
- Temperature card with large display
- Humidity card with large display
- Sensor name and last update time
- Color-coded icons (orange for temp, blue for humidity)

### Automatic Updates:

- Widgets refresh every **5 minutes**
- Uses same UserDefaults data as main app
- Shows "-- --" when no sensor data available
- Works with both Arduino BLE and RuuviTag sensors

## Testing Checklist

Before submitting to App Store:

- [ ] Widget builds without errors/warnings
- [ ] All three sizes display correctly (Small, Medium, Large)
- [ ] Temperature data updates in widget
- [ ] Humidity data updates in widget
- [ ] Sensor name shows correctly (Arduino or RuuviTag)
- [ ] Widget updates when sensor data changes
- [ ] Widget shows placeholder when no data
- [ ] Colors and styling look good
- [ ] App Groups capability enabled on both targets
- [ ] Main app builds with widget included
- [ ] No debug/NSLog statements in production code

## App Store Screenshots

For App Store submission, take screenshots showing:

1. **Main App + Small Widget** - Side by side on home screen
2. **Medium Widget** - Shows both metrics clearly
3. **Large Widget** - Full details visible
4. **Widget Gallery** - Showing Cricket in the widget picker
5. **Multiple Sizes** - All three widgets on same screen

## Next Steps

Once widgets are working:

1. Test thoroughly with real sensor data
2. Take App Store screenshots
3. Build archive for submission
4. Submit to App Store Connect
5. Share demo with RuuviTag forum!

---

## Quick Reference: File Locations

- Main app: `/Users/bobh/Desktop/Cricket/CricketIOS/CricketIOS/`
- Widget code: `CricketWidget_Code.swift` (rename to `CricketWidget.swift` in Xcode)
- Project file: `CricketIOS.xcodeproj`
- App Group: `group.com.yourcompany.CricketIOS`

## Questions?

Common issues:
- **Data not showing**: Verify App Group name matches in both targets
- **Widget not found**: Build and run CricketWidget scheme once
- **Build errors**: Check target memberships for files

The widget is designed to work seamlessly with your existing Cricket app infrastructure!
