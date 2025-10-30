# Troubleshooting Guide for CLOCs Real-Time iOS App

This guide addresses common warnings and errors you may encounter when running the CLOCs Real-Time app on iPhone.

## Common Warnings (Expected Behavior)

The following warnings are expected and do not indicate problems with the app:

### 1. RealityKit Material Warnings

```
asset string 'engine:throttleGhosted.rematerial' parse failed: Invalid asset path
Could not resolve material name 'engine:BuiltinRenderGraphResources/AR/...'
```

**What this means:** These are internal RealityKit shader warnings from Apple's ARKit framework. They occur when ARKit attempts to load built-in AR rendering resources.

**Impact:** None. These are informational warnings from the system and do not affect app functionality.

**Action required:** None. These warnings can be safely ignored.

### 2. Video Texture Warnings

```
Video texture allocator is not initialized.
[VideoLightSpillGenerator] Failed to create input texture with MTLPixelFormat
```

**What this means:** These warnings appear when certain AR video processing features are not available on the device or are not yet initialized.

**Impact:** Minimal. The app's core NURBS generation functionality works normally.

**Action required:** None. These warnings are informational.

### 3. Core Motion Permission Warning

```
Error reading file "/private/var/Managed Preferences/mobile/com.apple.CoreMotion.plist"
```

**What this means:** The system is attempting to read managed preferences for Core Motion but doesn't have permission.

**Impact:** None. The app includes the NSMotionUsageDescription permission in Info.plist.

**Action required:** Ensure you've granted motion permissions when prompted. If you didn't see the prompt:
1. Go to Settings > Privacy & Security > Motion & Fitness
2. Enable access for CLOCs Real-Time

### 4. Machine Learning Model Warnings

```
Warning: padding deconvolution Frontend_/FPN/... in SAME mode will not be pad-invariant for all resolutions
```

**What this means:** These warnings come from ARKit's internal machine learning models used for depth estimation and scene understanding. They indicate potential numerical precision variations at different image resolutions.

**Impact:** Minimal. ARKit's depth estimation continues to work correctly.

**Action required:** None. These are internal framework warnings.

### 5. Linearization/Solving Fallback Warning

```
warning: using linearization / solving fallback.
```

**What this means:** ARKit is using a fallback algorithm for scene reconstruction or tracking.

**Impact:** Slightly reduced accuracy in some edge cases.

**Action required:** None. This is normal behavior in certain lighting or texture conditions.

## Actual Errors to Address

### FPS, Points, and Surfaces Staying at Zero

**Symptom:** The info overlay shows FPS: 0.0, Points: 0, NURBS Surfaces: 0 and nothing updates

**Possible Causes:**
1. Device doesn't have LiDAR scanner
2. AR session not properly initialized
3. Camera permissions not granted
4. Depth data feature not supported on device/OS version

**Solutions:**

1. **Check Device Compatibility:**
   - Ensure you're using iPhone 12 Pro or later, OR iPad Pro (2020+)
   - Simulator does NOT work - must be physical device
   - Check Settings > General > About - confirm LiDAR scanner presence

2. **Verify Permissions:**
   - Go to Settings > Privacy & Security > Camera
   - Ensure "CLOCs Real-Time" has camera access enabled
   - Restart app after granting permissions

3. **Check Console Logs** (in Xcode):
   - Connect device to Xcode
   - Run app and open Console (⌘⇧C)
   - Look for these diagnostic messages:
     - "AR session started" - confirms session initialization
     - "Scene depth enabled" - confirms LiDAR feature is available
     - "FPS: [number]" - should appear every second if frames are being received
     - "Processed X points from depth map" - confirms depth data is being processed
   - If you see "Warning: No depth data or mesh anchors available" - LiDAR may not be supported

4. **Force Restart AR Session:**
   - Kill and restart the app
   - If that doesn't work, restart the device

5. **Check iOS Version:**
   - Requires iOS 17.0 or later
   - Some features work better on iOS 18+
   - Update to latest iOS if possible

6. **Environmental Factors:**
   - LiDAR requires objects/surfaces in view to generate depth data
   - Point camera at walls, furniture, or other surfaces (not empty sky)
   - Ensure adequate lighting (not pitch black)
   - Start with camera pointed at a nearby surface (0.5-2 meters)

**Debug Steps:**
If issues persist, check Xcode console for these specific messages:
- "lidarProcessor is nil" → App initialization issue, restart app
- "Could not get base address of depth map" → Device/OS incompatibility
- No FPS messages at all → AR session delegate not receiving callbacks

### LiDAR Not Available

**Error:** App crashes or shows "LiDAR not supported"

**Cause:** Device doesn't have LiDAR scanner

**Solution:** Use iPhone 12 Pro or later, or iPad Pro (2020 or later) with LiDAR

### AR Session Fails

**Error:** Black screen or "AR Session failed"

**Cause:** Camera permissions not granted or ARKit unavailable

**Solution:** 
1. Check Settings > Privacy > Camera - ensure CLOCs Real-Time has access
2. Restart the app
3. Restart the device if problem persists

### Low Frame Rate

**Symptom:** FPS consistently below 15

**Cause:** Device overheating or too many apps running

**Solution:**
1. Close other apps
2. Let device cool down
3. Reduce the maximum number of NURBS surfaces (requires code modification)

## Performance Tips

1. **Lighting:** Use well-lit environments for best results
2. **Surfaces:** Point at surfaces with texture/features for better tracking
3. **Movement:** Move slowly for better AR tracking stability
4. **Distance:** Keep 0.5-3 meters from surfaces for optimal depth data
5. **Clean lens:** Ensure camera and LiDAR sensor are clean

## Getting Help

If you encounter issues not covered here:

1. Check the [README.md](README.md) for system requirements
2. Review [iOS_17_ENHANCEMENTS.md](iOS_17_ENHANCEMENTS.md) for feature details
3. File an issue on the GitHub repository with:
   - Device model and iOS version
   - Steps to reproduce the problem
   - Screenshots or console logs

## Technical Notes

### About the Warnings

Most warnings you see are from Apple's ARKit and RealityKit frameworks, not from the CLOCs app itself. These frameworks are complex systems that:

- Load numerous internal resources and shaders
- Perform machine learning inference for scene understanding
- Handle video processing in real-time
- Manage complex rendering pipelines

The warnings indicate the framework is working through various fallback paths and initialization steps, which is normal behavior.

### Suppressing Console Warnings

If you're developing and want to reduce console noise, you can filter logs in Xcode:

1. In Xcode, go to the console (⌘⇧C)
2. Click the filter icon
3. Add filters to exclude:
   - "engine:BuiltinRenderGraphResources"
   - "rematerial"
   - "VideoLightSpillGenerator"

This only hides the warnings in Xcode; they don't affect the app's behavior.

## Version Information

- **Current iOS target:** 17.0
- **Tested on:** iOS 17.x, 18.x
- **Required device:** iPhone 12 Pro or later with LiDAR
- **Framework versions:** ARKit 6.0+, RealityKit 2.0+
