# CLOCs Real-Time iOS App

This is a real-time iOS application that runs on iPhone 16 (iOS 26+) and displays the current environment represented with NURBS (Non-Uniform Rational B-Splines) that are generated in real time.

## Features

- **Real-time LiDAR Capture**: Uses ARKit and the iPhone's LiDAR scanner to capture depth information
- **NURBS Surface Generation**: Generates NURBS surfaces in real-time from captured point cloud data
- **Live Visualization**: Displays NURBS surfaces overlaid on the camera view using RealityKit
- **Performance Monitoring**: Shows FPS, point count, and number of NURBS surfaces in real-time
- **iOS 26 Enhancements**: Leverages latest ARKit and RealityKit improvements (see [iOS_26_ENHANCEMENTS.md](iOS_26_ENHANCEMENTS.md))

## Requirements

- iPhone 12 Pro or later (with LiDAR scanner)
- iOS 26.0 or later
- Xcode 15.0 or later for development

## iOS 26 Enhancements

This app takes full advantage of iOS 26's ARKit and RealityKit improvements:

- **Enhanced Scene Reconstruction**: Higher-fidelity 3D meshes from LiDAR data
- **Smoothed Scene Depth**: Temporally-smoothed depth for stable NURBS surfaces
- **Physically-Based Materials**: More realistic surface rendering with PBR
- **Improved Image-Based Lighting**: Better environmental reflections
- **Advanced Shadow Rendering**: Realistic shadows with improved depth bias
- **Concurrent Processing**: Better multi-core utilization for faster processing
- **Person Segmentation**: Natural occlusion with people in the scene

See [iOS_26_ENHANCEMENTS.md](iOS_26_ENHANCEMENTS.md) for complete details.

## Technical Details

### Architecture

1. **ARViewContainer**: SwiftUI view that wraps ARView and handles AR session management
2. **LiDARProcessor**: Processes depth data from LiDAR and mesh anchors, converts to point clouds
3. **NURBSGenerator**: Generates NURBS surfaces from point cloud data using control point grids
4. **ContentView**: Main UI with info overlay showing performance metrics

### NURBS Implementation

- Uses cubic NURBS (degree 3)
- Creates control point grids from clustered point cloud data
- Evaluates NURBS surfaces using bilinear interpolation
- Generates triangle mesh for real-time rendering with RealityKit

### Real-time Processing

- Processes depth data and mesh anchors on background queue
- Updates visualization at camera frame rate (typically 30-60 FPS)
- Automatically clusters points into spatial regions for separate NURBS surfaces
- Limits surface count for performance (max 5 surfaces by default)

## Building and Running

1. Open `CLOCsRealTime.xcodeproj` in Xcode
2. Select a physical iPhone device with LiDAR (simulator won't work)
3. Build and run the app
4. Grant camera and AR permissions when prompted
5. Point the camera at surfaces to see NURBS generation

## Permissions

The app requires:
- Camera access for AR
- Location access for world tracking (optional)

## Performance

- Targets 30+ FPS on iPhone 12 Pro and later
- Samples depth data at reduced resolution for performance
- Uses spatial clustering to limit number of NURBS surfaces
- Asynchronous processing to avoid blocking the main thread

## Notes

- Targets iOS 26.0 as specified in requirements
- Best results with well-lit environments and distinct surfaces
- NURBS surfaces update continuously as the device moves
- Color scheme: Semi-transparent blue surfaces for visibility

## Future Enhancements

- Advanced NURBS basis function evaluation
- Texture mapping on NURBS surfaces
- Surface smoothing and refinement
- Export of NURBS models
- Multi-resolution adaptive tessellation
