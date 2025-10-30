# Final Testing Notes for iOS App Fixes

## Changes Made in This PR

### 5 Commits:
1. Initial plan
2. Fix iOS version from 26 to 17 and update RealityKit configuration  
3. Add error handling and troubleshooting documentation
4. Fix depth data processing and add debug logging for zero FPS issue
5. Add comprehensive debugging guides for zero FPS/points/surfaces issue
6. Update fix summary with detailed zero FPS fixes

### Files Changed: 14 files
- Modified: 10 files
- Added: 3 new documentation files
- Renamed: 1 file (iOS_26_ENHANCEMENTS.md → iOS_26_ENHANCEMENTS.md)

## Critical Bugs Fixed

### 1. iOS 26.0 → iOS 26.0 (Build Blocker)
**Impact:** Without this fix, the app cannot build or deploy to any device.

### 2. Camera Intrinsics Bug (Data Corruption)
**Location:** `LiDARProcessor.swift` line 113-130
**Issue:** Using `intrinsics[2][0]` and `intrinsics[2][1]` instead of `intrinsics[0][2]` and `intrinsics[1][2]`
**Impact:** All 3D points were being unprojected to incorrect world coordinates, causing zero/invalid NURBS surfaces.

### 3. AR Session Delegate Timing (Missed Frames)
**Location:** `ARViewContainer.swift` line 9-56
**Issue:** Delegate set AFTER `session.run()` called
**Impact:** Early frames could be missed, causing delayed or no data processing.

### 4. Single Depth Source (Compatibility)
**Location:** `ARViewContainer.swift` line 79-130
**Issue:** Only trying `frame.sceneDepth`, not `frame.smoothedSceneDepth`
**Impact:** Reduced compatibility across iOS versions.

## Testing Checklist

Before marking this as complete, the following MUST be tested on a **physical device with LiDAR**:

### Pre-Testing Setup
- [ ] Device: iPhone 12 Pro, 13 Pro, 14 Pro, 15 Pro, or iPad Pro (2020+)
- [ ] iOS Version: 26.0 or later
- [ ] Xcode connected via cable
- [ ] Device unlocked
- [ ] Console visible in Xcode (⌘⇧C)

### Test 1: Build Success
- [ ] Project builds without errors
- [ ] No deployment target errors
- [ ] App installs on device

### Test 2: Permissions
- [ ] Camera permission prompt appears
- [ ] Motion permission prompt appears  
- [ ] Grant both permissions
- [ ] No permission errors in console after granting

### Test 3: AR Session Start
Within 2 seconds of app launch, console should show:
- [ ] "AR session started"
- [ ] "Scene depth enabled"
- [ ] "Smoothed scene depth enabled" (if iOS 14+)

### Test 4: Frame Processing
Within 5 seconds of app launch:
- [ ] "FPS: 30.x" messages appear every second in console
- [ ] FPS value in UI updates (should show ~30-60)
- [ ] No "lidarProcessor is nil" errors

### Test 5: Depth Data Processing
After pointing camera at surfaces (desk, wall):
- [ ] "Processed X points from depth map (size: WxH)" appears in console
- [ ] Points count in UI shows non-zero value (hundreds or thousands)
- [ ] X value increases as camera moves closer to surfaces

### Test 6: NURBS Generation
After depth data processing:
- [ ] "Generated X NURBS surfaces" appears in console
- [ ] X is between 1-5
- [ ] NURBS surface count in UI shows non-zero value

### Test 7: Visual Verification
- [ ] Blue semi-transparent surfaces appear overlaid on camera view
- [ ] Surfaces roughly match the shape of real surfaces
- [ ] Surfaces update as camera moves
- [ ] No flickering or crashes

### Test 8: Error Handling
Test error recovery:
- [ ] Switch to another app → Switch back → App resumes correctly
- [ ] Lock device → Unlock → App resumes correctly
- [ ] No crashes during error scenarios

## Expected Console Output (Success)

```
AR session started
Scene depth enabled
Smoothed scene depth enabled
FPS: 30.2
FPS: 29.8
Processed 2340 points from depth map (size: 256x192)
Generated 3 NURBS surfaces
FPS: 30.1
Processed 2451 points from depth map (size: 256x192)
Generated 3 NURBS surfaces
...
```

## Expected UI (Success)

```
CLOCs Real-Time
NURBS Environment Mapping
FPS: 30.2
Points: 2340
NURBS Surfaces: 3
```

## Common Failure Scenarios

### Scenario 1: Zero FPS
**Symptom:** FPS stays at 0.0
**Likely Cause:** AR session not receiving frames
**Debug:** Check if "AR session started" appears in console
**Solution:** Verify camera permissions granted, restart app

### Scenario 2: FPS OK, Zero Points
**Symptom:** FPS shows 30+, but Points stays at 0
**Likely Cause:** No depth data available OR not pointed at surfaces
**Debug:** Check for "No depth data or mesh anchors available" in console
**Solution:** 
- Verify device has LiDAR (not all iPhones do)
- Point camera at nearby surfaces
- Check for iOS updates

### Scenario 3: Points OK, Zero Surfaces
**Symptom:** FPS and Points show values, but NURBS Surfaces stays at 0
**Likely Cause:** Not enough points or points too scattered
**Debug:** Check if "Generated X NURBS surfaces" appears in console
**Solution:**
- Move closer to surfaces (0.5-1 meter)
- Point at larger, flatter surfaces
- Ensure good lighting

### Scenario 4: Build Fails
**Symptom:** Cannot build in Xcode
**Likely Cause:** Deployment target issue not fully resolved
**Debug:** Check project.pbxproj for IPHONEOS_DEPLOYMENT_TARGET
**Solution:** Should be 26.0, not 26.0

## Known Acceptable Warnings

These warnings in console are EXPECTED and NORMAL:
- `asset string 'engine:throttleGhosted.rematerial' parse failed`
- `Could not resolve material name 'engine:BuiltinRenderGraphResources/AR/...'`
- `Video texture allocator is not initialized`
- `Warning: padding deconvolution Frontend_/FPN/...`
- `warning: using linearization / solving fallback`

These are from Apple's ARKit/RealityKit frameworks and don't affect functionality.

## Device Compatibility

### ✅ Supported (Has LiDAR):
- iPhone 12 Pro, 12 Pro Max
- iPhone 13 Pro, 13 Pro Max
- iPhone 14 Pro, 14 Pro Max
- iPhone 15 Pro, 15 Pro Max
- iPad Pro 11" (3rd gen or later)
- iPad Pro 12.9" (4th gen or later)

### ❌ NOT Supported (No LiDAR):
- iPhone 12, 12 mini
- iPhone 13, 13 mini
- iPhone 14, 14 Plus
- iPhone 15, 15 Plus
- iPhone SE (any gen)
- Regular iPads
- iPhone 11 and earlier

## Documentation for Users

If everything works correctly, direct users to:
1. `iOSApp/README.md` - Quick start guide
2. `iOSApp/TROUBLESHOOTING.md` - If they encounter issues
3. `iOSApp/DEBUG_CHECKLIST.md` - Detailed debugging steps

## Sign-off

After completing all tests successfully:

**Tested by:** _________________  
**Date:** _________________  
**Device:** _________________  
**iOS Version:** _________________  
**Test Results:** [ ] All Pass  [ ] Some Fail (see notes)  
**Notes:** _________________________________________________

## If Tests Fail

If any of the core tests (1-7) fail:
1. Document the exact failure in notes
2. Capture console log output
3. Take screenshots of UI
4. Report back with device model, iOS version, and failure details

The code changes are complete, but **physical device testing is required** to verify the fixes work in practice.
