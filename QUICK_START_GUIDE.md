# Quick Start Guide - CLOCs Real-Time iOS App

## What You'll Need

- **iPhone 12 Pro or later** with LiDAR scanner
- **macOS** computer with Xcode 15.0+
- **USB cable** to connect iPhone to Mac
- **Apple Developer account** (free tier is sufficient)

## Installation Steps

### 1. Setup Xcode
```bash
# Install Xcode from Mac App Store (if not already installed)
# Launch Xcode and agree to license terms
```

### 2. Open the Project
```bash
# Navigate to the project
cd iOSApp

# Open in Xcode
open CLOCsRealTime.xcodeproj
```

### 3. Configure Signing
1. In Xcode, select the project in the navigator
2. Select "CLOCsRealTime" target
3. Go to "Signing & Capabilities" tab
4. Select your development team from dropdown
5. Xcode will automatically create a provisioning profile

### 4. Connect Your iPhone
1. Connect iPhone to Mac via USB cable
2. Trust the computer on your iPhone when prompted
3. Select your iPhone from the device menu in Xcode

### 5. Build and Run
1. Click the ▶️ Play button in Xcode (or press ⌘+R)
2. Wait for the build to complete
3. App will install and launch on your iPhone
4. Grant camera permissions when prompted

## First Use

### When the App Launches
1. **Camera Permission**: Tap "Allow" when asked for camera access
2. **AR Session**: The app will start scanning your environment
3. **Point at Surfaces**: Aim your camera at walls, floors, or objects
4. **Watch NURBS Generate**: Blue semi-transparent surfaces will appear

### Understanding the Display

**Info Panel (top-left):**
- **FPS**: Current frame rate (target: 30+ fps)
- **Points**: Number of LiDAR points captured
- **NURBS Surfaces**: Number of surfaces currently rendered

**Toggle Button (bottom-right):**
- Tap the ⓘ icon to show/hide the info panel

## Tips for Best Results

### Environment
- ✅ Use in well-lit areas
- ✅ Point at textured surfaces (walls, furniture)
- ✅ Keep distance 0.5-3 meters from surfaces
- ❌ Avoid mirrors or reflective surfaces
- ❌ Avoid transparent glass
- ❌ Don't move too quickly

### Performance
- Close other apps for maximum FPS
- Use on newer iPhone models for best performance
- Restart app if performance degrades
- Keep iPhone cool (processing is intensive)

## Troubleshooting

### "ARKit Not Available"
- **Cause**: Running on simulator
- **Fix**: Must use physical iPhone device

### "LiDAR Not Found"
- **Cause**: Device doesn't have LiDAR scanner
- **Fix**: Requires iPhone 12 Pro, 13 Pro, 14 Pro, or 15 Pro

### Build Errors
- **Cause**: Xcode or iOS version too old
- **Fix**: Update Xcode to 15.0+ and iOS to 18.0+

### No NURBS Surfaces Appearing
- **Cause**: Not enough valid depth data
- **Fix**: Point at closer, more textured surfaces

### Low Frame Rate
- **Cause**: Too many points being processed
- **Fix**: Move farther from surfaces, point at simpler scenes

### Signing Errors
- **Cause**: No development team selected
- **Fix**: Add Apple ID in Xcode Preferences > Accounts

## Understanding the Output

### NURBS Surfaces
The blue semi-transparent surfaces represent the environment as NURBS:
- Each surface is a mathematical representation (not just a mesh)
- Surfaces are fitted to clusters of LiDAR points
- Control points define the surface shape
- Real-time updates as you move the device

### Color Scheme
- **Blue surfaces**: NURBS representations
- **Semi-transparent**: So you can see the real environment
- Future versions may color-code by distance or type

## Advanced Usage

### Recording Sessions
Currently, the app runs in real-time only. Future versions may include:
- Session recording
- NURBS export
- Screenshot/video capture

### Adjusting Parameters
To modify NURBS generation (requires code changes):
- Edit `NURBSGenerator.swift`
- Change `gridSize` for control point density
- Change `resolution` for tessellation quality
- Change `maxClusters` for number of surfaces

### Performance Tuning
In `LiDARProcessor.swift`:
- Change `sampleStep` to adjust point sampling (higher = faster, lower quality)
- Modify depth range filters (currently 0.1-10.0 meters)

## What's Happening Under the Hood

1. **Capture**: iPhone's LiDAR scanner captures depth at 60 Hz
2. **Process**: Depth maps converted to 3D point clouds
3. **Cluster**: Points grouped into spatial regions
4. **Fit**: NURBS control points fitted to each cluster
5. **Evaluate**: Surface sampled at high-resolution
6. **Render**: Triangle mesh displayed with RealityKit

## Next Steps

After you're comfortable with the basics:
1. Try different environments (indoor/outdoor)
2. Observe how surface quality changes with distance
3. Notice performance variations with scene complexity
4. Read [iOS_APP_DOCUMENTATION.md](../iOS_APP_DOCUMENTATION.md) for technical details

## Support

For issues or questions:
1. Check [iOS_APP_DOCUMENTATION.md](../iOS_APP_DOCUMENTATION.md)
2. Review [iOSApp/README.md](README.md)
3. Check Apple's ARKit documentation
4. File an issue in the GitHub repository

## Demo Video (How It Should Look)

When working correctly:
1. Launch app → Camera view appears
2. Point at wall → Blue NURBS surface appears within 1-2 seconds
3. Move phone → Surfaces update in real-time
4. Info panel shows: ~30-60 FPS, 1000-5000 points, 1-5 surfaces
5. Smooth, responsive AR experience

Enjoy mapping your environment with NURBS! 🎉
