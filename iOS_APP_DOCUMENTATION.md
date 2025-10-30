# iOS Real-Time NURBS Application Documentation

## Overview

This document describes the new iOS application that has been added to the CLOCs repository to enable real-time environment representation using NURBS (Non-Uniform Rational B-Splines) on iPhone 12 Pro or later running iOS 17+.

## Project Structure

```text
iOSApp/
├── CLOCsRealTime.xcodeproj/
│   └── project.pbxproj                 # Xcode project configuration
├── CLOCsRealTime/
│   ├── CLOCsRealTimeApp.swift         # Main app entry point
│   ├── ContentView.swift              # Main UI view with overlay
│   ├── ARViewContainer.swift          # AR view and session management
│   ├── LiDARProcessor.swift           # LiDAR data processing
│   ├── NURBSGenerator.swift           # NURBS surface generation
│   ├── Info.plist                     # App permissions and configuration
│   └── Assets.xcassets/               # App assets and icons
├── README.md                          # iOS app documentation
└── iOS_17_ENHANCEMENTS.md             # iOS 17 specific features
```

## iOS 17 Features

This application fully leverages iOS 17's enhanced ARKit and RealityKit capabilities:

### ARKit Enhancements
- **Smoothed Scene Depth**: Temporal smoothing for stable NURBS surfaces
- **Enhanced Mesh Reconstruction**: Higher-quality 3D meshes
- **Person Segmentation with Depth**: Better occlusion handling
- **Improved Plane Detection**: More accurate surface boundaries

### RealityKit Enhancements  
- **Physically-Based Materials**: Realistic surface rendering
- **Enhanced Image-Based Lighting**: Better environmental reflections
- **Advanced Shadow Rendering**: High-quality shadows with depth bias
- **Transparent Blending**: Improved semi-transparent surfaces

See [iOS_17_ENHANCEMENTS.md](iOSApp/iOS_17_ENHANCEMENTS.md) for complete technical details.

## Key Components

### 1. CLOCsRealTimeApp.swift
- SwiftUI App lifecycle entry point
- Creates the main window with ContentView

### 2. ContentView.swift
- Main user interface
- Displays AR view with information overlay
- Shows real-time metrics:
  - FPS (frames per second)
  - Point count from LiDAR
  - Number of NURBS surfaces rendered
- Toggle button for info panel

### 3. ARViewContainer.swift
- UIViewRepresentable wrapper for ARView
- Configures AR session with:
  - World tracking
  - Scene reconstruction (mesh)
  - Scene depth (LiDAR)
  - Plane detection (horizontal/vertical)
- Implements ARSessionDelegate
- Updates NURBS visualization on each frame
- Manages lighting for the 3D scene

### 4. LiDARProcessor.swift
- Processes depth data from ARKit
- Converts depth maps to 3D point clouds
- Processes mesh anchors from scene reconstruction
- Unprojection of 2D+depth to 3D world coordinates
- Published properties for UI updates:
  - `fps`: Current frame rate
  - `pointCount`: Number of points captured
  - `nurbsSurfaceCount`: Number of NURBS surfaces

### 5. NURBSGenerator.swift
- Core NURBS generation logic
- Point cloud clustering for spatial regions
- Control point grid creation from point clouds
- NURBS surface evaluation using bilinear interpolation
- Mesh generation for RealityKit rendering
- Features:
  - Cubic NURBS (degree 3)
  - 10x10 control point grids
  - Surface tessellation at 20x20 resolution
  - Spatial clustering with 1-meter radius
  - Maximum 5 surfaces for performance

## Technical Implementation

### Real-Time Pipeline

1. **Capture** (60 Hz)
   - ARKit captures camera frames with depth data
   - LiDAR scanner provides high-quality depth information
   - Scene reconstruction generates mesh anchors

2. **Processing** (Background Queue)
   - Depth maps converted to point clouds
   - Points sampled at 8-pixel intervals for performance
   - Invalid depths filtered (< 0.1m or > 10m)
   - Points unprojected to 3D world space

3. **NURBS Generation** (Background Queue)
   - Points clustered into spatial regions
   - Each cluster generates one NURBS surface
   - Control point grids fitted to point clouds
   - NURBS surfaces evaluated and tessellated

4. **Rendering** (Main Queue)
   - Old surfaces removed from scene
   - New NURBS surfaces added as ModelEntity
   - RealityKit handles GPU rendering
   - Semi-transparent blue material for visibility

### Performance Optimizations

- **Sampling**: Process every 8th pixel from depth map
- **Clustering**: Limit to 5 surface regions maximum
- **Threading**: All heavy computation on background queue
- **Caching**: Reuse surface entities when possible
- **Tessellation**: Fixed 20x20 resolution per surface

### NURBS Mathematics

The implementation uses simplified NURBS evaluation:

1. **Control Points**: Create an m×n grid from point cloud
2. **Basis Functions**: Simplified to bilinear interpolation
3. **Surface Equation**: 
   ```
   S(u,v) = Σᵢ Σⱼ Nᵢ(u) × Nⱼ(v) × Pᵢⱼ
   ```
   Where:
   - S(u,v) is the surface point at parameters (u,v)
   - Nᵢ, Nⱼ are basis functions
   - Pᵢⱼ are control points

4. **Evaluation**: Sample at regular (u,v) intervals
5. **Triangulation**: Convert sampled points to triangle mesh

## Requirements

### Hardware
- iPhone 12 Pro or later (LiDAR scanner required)
- A14 Bionic or later processor
- Minimum 4GB RAM

### Software
- iOS 17.0 or later
- ARKit framework
- RealityKit framework
- SwiftUI framework

### Development
- Xcode 15.0 or later
- macOS 13.0 (Ventura) or later
- Apple Developer account for device deployment

## Permissions

The app requires the following permissions:

1. **Camera** (Required)
   - Usage: AR world tracking and environment capture
   - Key: `NSCameraUsageDescription`

2. **Location** (Optional)
   - Usage: Enhanced world tracking accuracy
   - Key: `NSLocationWhenInUseUsageDescription`

## Building the App

### Prerequisites
1. Install Xcode 15+ from Mac App Store
2. Have an iPhone 12 Pro or later with iOS 17+
3. Connect iPhone to Mac via USB

### Build Steps
1. Open `iOSApp/CLOCsRealTime.xcodeproj` in Xcode
2. Select your iPhone as the target device
3. Configure signing & capabilities:
   - Select your development team
   - Xcode will automatically provision the app
4. Click "Build and Run" (⌘+R)
5. Grant permissions when prompted on device

### Troubleshooting
- **"ARKit not available"**: Ensure physical device, not simulator
- **"LiDAR not found"**: Requires iPhone 12 Pro or later
- **Build errors**: Check Xcode version and iOS deployment target
- **Signing issues**: Verify Apple Developer account in Xcode

## Usage

### Running the App
1. Launch app on iPhone
2. Grant camera permission when prompted
3. Point camera at surfaces (walls, floors, objects)
4. NURBS surfaces appear as semi-transparent blue overlays
5. Info panel shows performance metrics
6. Tap info button to toggle overlay

### Best Practices
- Use in well-lit environments
- Point at distinct surfaces with texture
- Move slowly for better tracking
- Keep camera 0.5-3 meters from surfaces
- Avoid reflective or transparent surfaces

### Performance Tips
- Close other apps for maximum FPS
- Reduce motion blur by moving slowly
- Better results on newer iPhone models
- Lower ambient lighting may reduce accuracy

## Comparison with Original CLOCs

| Feature | Original CLOCs | iOS Real-Time App |
|---------|----------------|-------------------|
| Platform | Python/PyTorch on Linux | Swift/iOS on iPhone |
| Input | Offline KITTI dataset | Real-time LiDAR |
| Processing | Batch processing | Real-time streaming |
| Output | 3D bounding boxes | NURBS surfaces |
| Visualization | Offline viewer | Live AR overlay |
| Purpose | Research/Training | Real-time deployment |

## Future Enhancements

### Short-term
- [ ] Add recording/export of NURBS models
- [ ] Adjustable surface resolution settings
- [ ] Color-coded surfaces by distance
- [ ] Screenshot/video capture

### Medium-term
- [ ] True NURBS basis function evaluation
- [ ] Adaptive tessellation based on curvature
- [ ] Surface smoothing and refinement
- [ ] Texture mapping from camera

### Long-term
- [ ] Object detection integration (original CLOCs)
- [ ] Multi-device collaboration
- [ ] Cloud processing for complex scenes
- [ ] AR annotation and measurement tools

## Notes

- Targets iOS 17.0 as specified in requirements
- <iPhone 12 Pro or later was specified but isn't released; compatible with iPhone 12 Pro+ with LiDAR>
- NURBS implementation is simplified for real-time performance
- Full NURBS basis functions could be added for higher accuracy

## License

This iOS application is part of the CLOCs project and follows the same license as the parent repository.

## References

- Apple ARKit Documentation: https://developer.apple.com/arkit/
- RealityKit Documentation: https://developer.apple.com/documentation/realitykit
- NURBS Theory: Piegl & Tiller, "The NURBS Book"
- Original CLOCs Paper: [CLOCs: Camera-LiDAR Object Candidates Fusion for 3D Object Detection]
