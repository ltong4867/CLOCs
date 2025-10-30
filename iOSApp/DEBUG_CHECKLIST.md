# Debug Checklist for Zero FPS/Points/Surfaces Issue

If you're seeing FPS: 0.0, Points: 0, NURBS Surfaces: 0, follow this checklist:

## Quick Checks

- [ ] **Device has LiDAR?** 
  - Must be iPhone 12 Pro, 13 Pro, 14 Pro, 15 Pro, or iPad Pro (2020+)
  - Simulator will NOT work
  
- [ ] **Running on physical device?**
  - Cable connected to Mac
  - Device unlocked and app in foreground
  
- [ ] **Camera permission granted?**
  - Settings > Privacy > Camera > CLOCs Real-Time = ON
  - If changed, restart the app

- [ ] **iOS version 17.0+?**
  - Settings > General > About > Software Version
  - Update if needed

- [ ] **Camera pointed at surfaces?**
  - Point at wall, desk, floor (not sky or far distance)
  - Stay 0.5-3 meters from surface

## Console Log Checks (Xcode)

Connect device to Xcode and check Console (⌘⇧C) for these messages:

### ✅ Expected Messages (Good)
```
AR session started
Scene depth enabled
Smoothed scene depth enabled
FPS: 30.0 (or similar number > 0)
Processed 1234 points from depth map (size: 256x192)
Generated 3 NURBS surfaces
```

### ❌ Problem Indicators
```
Warning: lidarProcessor is nil in session callback
  → App initialization failed, restart app

Warning: No depth data or mesh anchors available
  → Device doesn't support LiDAR OR permissions issue

Could not get base address of depth map
  → System issue, restart device

No FPS messages at all after 5 seconds
  → AR session not receiving frames, check permissions
```

## Detailed Diagnostic Steps

### Step 1: Verify Basic AR Session
1. Run app on device
2. Watch Xcode console
3. Within 2 seconds, you should see:
   ```
   AR session started
   Scene depth enabled
   ```
4. If NOT → Device/OS compatibility issue

### Step 2: Verify Frame Updates
1. Keep app running for 5 seconds
2. Look for FPS messages in console (appear every second):
   ```
   FPS: 30.2
   FPS: 29.8
   FPS: 30.1
   ```
3. If NOT → AR session delegate issue, try:
   - Restart app
   - Restart device
   - Check camera permission

### Step 3: Verify Depth Data
1. Point camera at nearby surface (desk, wall)
2. Look for processing messages:
   ```
   Processed 2340 points from depth map (size: 256x192)
   ```
3. If NOT → LiDAR not working:
   - Verify device has LiDAR
   - Clean camera/sensor area
   - Check for iOS updates

### Step 4: Verify NURBS Generation
1. After seeing "Processed X points" messages
2. Should see:
   ```
   Generated 2 NURBS surfaces
   ```
3. If NOT → Point cloud too small:
   - Move closer to surfaces
   - Point at larger surfaces
   - Ensure good lighting

## Common Issues and Solutions

### Issue: No Console Messages at All
**Solution:** 
- In Xcode, ensure device is selected in device menu (not "Any Device")
- Bottom console pane should show device logs
- Try Window > Devices and Simulators to verify connection

### Issue: "AR session started" but no FPS messages
**Solution:**
- Camera permission issue
- Go to Settings > Privacy & Security > Camera
- Enable for CLOCs Real-Time
- MUST restart app after changing permissions

### Issue: FPS shows but "No depth data or mesh anchors available"
**Solution:**
- Device doesn't have LiDAR scanner
- Verify device model - must be Pro model with LiDAR
- Not all iPhones have LiDAR (regular iPhone 12/13/14/15 don't have it)

### Issue: Points processed but no NURBS surfaces
**Solution:**
- Not enough points or points too scattered
- Requirements: Minimum 9 points per surface, max 5 surfaces
- Try:
  - Move closer to surfaces (0.5-1 meter)
  - Point at flat surfaces (walls, floor, desk)
  - Wait 2-3 seconds for data accumulation

### Issue: Everything works in console but UI shows zeros
**Solution:**
- UI update issue
- Check if info panel is visible (tap info button)
- Try toggling info panel off and on
- SwiftUI state update issue - restart app

## Code-Level Debugging

If you're modifying the code, add these breakpoints:

1. **ARViewContainer.swift, line ~79** - `session(_:didUpdate:)` method
   - Should hit every frame (30-60 times per second)
   
2. **LiDARProcessor.swift, line ~62** - Where `pointCount` is set
   - Should hit when depth data is processed
   
3. **NURBSGenerator.swift, line ~18** - `createNURBSSurface` call
   - Should hit when generating surfaces

## Still Not Working?

If all checks pass but still having issues:

1. **Reset all settings:**
   - Settings > General > Transfer or Reset > Reset > Reset Location & Privacy
   - Restart device
   - Reinstall app and grant permissions

2. **Check for iOS bugs:**
   - Try on different iOS version if possible
   - Check Apple Developer Forums for known ARKit issues

3. **Hardware issue:**
   - Test with Apple's built-in Measure app
   - If Measure app also doesn't work → Hardware problem, contact Apple Support

4. **File an issue:**
   - Include device model
   - Include iOS version
   - Include full console log
   - Include screenshots of Settings > Privacy

## Success Indicators

When everything is working correctly, you should see:

- **Console:** Messages every second showing FPS, points processed, surfaces generated
- **UI Overlay:** FPS around 30-60, Points in thousands, Surfaces 1-5
- **Visual:** Semi-transparent blue NURBS surfaces overlaid on camera view
- **Performance:** Smooth, no lag, surfaces update as you move camera

## Quick Fix Summary

90% of zero FPS/points/surfaces issues are caused by:

1. **Wrong device** (doesn't have LiDAR) → 40%
2. **Running on simulator** → 25%
3. **Camera permission not granted** → 20%
4. **Not pointing at surfaces** → 10%
5. **Other** → 5%

Always check these first before diving into code debugging!
