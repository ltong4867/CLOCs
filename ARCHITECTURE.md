# Architecture Overview - CLOCs Real-Time iOS App

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          iOS Device (iPhone 16+)                 │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                     CLOCsRealTime App                      │   │
│  │                                                            │   │
│  │  ┌────────────────────────────────────────────────────┐   │   │
│  │  │              ContentView (SwiftUI)                  │   │   │
│  │  │  - Main UI with info overlay                        │   │   │
│  │  │  - Performance metrics display                      │   │   │
│  │  │  - Toggle button for info panel                     │   │   │
│  │  └───────────────────┬────────────────────────────────┘   │   │
│  │                      │                                     │   │
│  │  ┌───────────────────▼────────────────────────────────┐   │   │
│  │  │          ARViewContainer (UIViewRepresentable)      │   │   │
│  │  │  - Wraps ARView for SwiftUI                         │   │   │
│  │  │  - Configures AR session                            │   │   │
│  │  │  - Delegates to Coordinator                         │   │   │
│  │  └───────────────────┬────────────────────────────────┘   │   │
│  │                      │                                     │   │
│  │  ┌───────────────────▼────────────────────────────────┐   │   │
│  │  │         Coordinator (ARSessionDelegate)             │   │   │
│  │  │  - Receives AR frames                               │   │   │
│  │  │  - Calculates FPS                                   │   │   │
│  │  │  - Updates NURBS visualization                      │   │   │
│  │  └───────────┬───────────────────────┬────────────────┘   │   │
│  │              │                       │                     │   │
│  │  ┌───────────▼───────────┐  ┌───────▼────────────────┐   │   │
│  │  │   LiDARProcessor       │  │    RealityKit          │   │   │
│  │  │   (ObservableObject)   │  │    - Scene management  │   │   │
│  │  │  - Process depth data  │  │    - 3D rendering      │   │   │
│  │  │  - Process mesh anchors│  │    - Lighting          │   │   │
│  │  │  - Unproject to 3D     │  │    - Materials         │   │   │
│  │  │  - Background queue    │  └────────────────────────┘   │   │
│  │  └───────────┬───────────┘                                │   │
│  │              │                                             │   │
│  │  ┌───────────▼───────────┐                                │   │
│  │  │    NURBSGenerator      │                                │   │
│  │  │  - Cluster points      │                                │   │
│  │  │  - Create control grid │                                │   │
│  │  │  - Evaluate NURBS      │                                │   │
│  │  │  - Generate mesh       │                                │   │
│  │  └────────────────────────┘                                │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                     ARKit Framework                         │   │
│  │  - World tracking                                           │   │
│  │  - Scene reconstruction                                     │   │
│  │  - Depth data (LiDAR)                                       │   │
│  │  - Plane detection                                          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                    Hardware (iPhone)                        │   │
│  │  - LiDAR Scanner                                            │   │
│  │  - Camera                                                   │   │
│  │  - GPU (Metal)                                              │   │
│  │  - IMU (Inertial Measurement Unit)                          │   │
│  └────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
Hardware Layer
    ↓
  LiDAR Scanner → Depth Map (256×192 @ 60Hz)
    ↓
  Camera → RGB Image (1920×1080 @ 60Hz)
    ↓
ARKit Processing
    ↓
  Scene Depth + Mesh Anchors → ARFrame
    ↓
Coordinator (ARSessionDelegate)
    ↓
    ├─→ FPS Calculation → @Published fps
    │
    └─→ LiDARProcessor (Background Queue)
          ↓
        Process Depth Map
          ↓
        Extract Points (every 8th pixel)
          ↓
        Filter Invalid Depths (0.1m - 10m)
          ↓
        Unproject to 3D World Space
          ↓
        Point Cloud (1000-5000 points)
          ↓
        NURBSGenerator
          ↓
        Spatial Clustering (1m radius)
          ↓
        Clusters (1-5 regions)
          ↓
        For each cluster:
          ↓
        Create Control Grid (10×10 points)
          ↓
        Evaluate NURBS Surface (20×20 samples)
          ↓
        Generate Triangle Mesh
          ↓
        Create ModelEntity
          ↓
        @Published surfaces[]
          ↓
Main Thread
    ↓
  Update RealityKit Scene
    ↓
  Remove old NURBS anchors
    ↓
  Add new NURBS anchors
    ↓
GPU Rendering (Metal)
    ↓
  Display on Screen (60 FPS)
```

## Component Responsibilities

### 1. ContentView (UI Layer)
**Purpose**: Main user interface
**Inputs**: Published properties from LiDARProcessor
**Outputs**: User interactions, view updates
**Threading**: Main thread
**Key Operations**:
- Display AR view
- Show performance metrics
- Handle info toggle

### 2. ARViewContainer (AR Integration)
**Purpose**: Bridge between SwiftUI and ARKit
**Inputs**: LiDARProcessor reference
**Outputs**: Configured ARView
**Threading**: Main thread for view, background for AR session
**Key Operations**:
- Create and configure ARView
- Setup AR session with world tracking
- Enable scene reconstruction
- Configure lighting

### 3. Coordinator (Session Management)
**Purpose**: Handle AR session events
**Inputs**: ARFrame events
**Outputs**: Processed NURBS visualization
**Threading**: ARKit thread → dispatch to processor queue
**Key Operations**:
- Receive frame updates (60 Hz)
- Calculate FPS
- Extract depth/mesh data
- Update scene visualization

### 4. LiDARProcessor (Data Processing)
**Purpose**: Convert sensor data to point clouds
**Inputs**: ARDepthData, ARMeshAnchors
**Outputs**: NURBS surfaces for rendering
**Threading**: Background serial queue
**Key Operations**:
- Lock and read depth buffer
- Sample points at intervals
- Unproject 2D+depth to 3D
- Filter invalid points
- Coordinate with NURBSGenerator

### 5. NURBSGenerator (Surface Generation)
**Purpose**: Generate NURBS from points
**Inputs**: Point clouds (arrays of SIMD3<Float>)
**Outputs**: ModelEntity array
**Threading**: Same as LiDARProcessor
**Key Operations**:
- Cluster points spatially
- Fit control point grids
- Evaluate NURBS surfaces
- Generate triangle meshes
- Create materials and entities

## Threading Model

```
┌─────────────────────────────────────────────────┐
│              Main Thread                         │
│  - UI updates                                    │
│  - SwiftUI rendering                             │
│  - RealityKit scene updates                      │
│  - Published property changes                    │
└─────────────────────────────────────────────────┘
                    ↑
                    │ @Published
                    │
┌─────────────────────────────────────────────────┐
│         com.clocs.lidar.processing               │
│  - LiDAR data processing                         │
│  - Point cloud generation                        │
│  - NURBS generation                              │
│  - Mesh creation                                 │
│  Quality: .userInteractive                       │
└─────────────────────────────────────────────────┘
                    ↑
                    │ delegate
                    │
┌─────────────────────────────────────────────────┐
│            ARKit Internal Thread                 │
│  - Frame capture                                 │
│  - Tracking computation                          │
│  - Mesh generation                               │
│  - Depth processing                              │
└─────────────────────────────────────────────────┘
                    ↑
                    │
┌─────────────────────────────────────────────────┐
│              Hardware (60 Hz)                    │
│  - LiDAR scanning                                │
│  - Camera capture                                │
│  - IMU readings                                  │
└─────────────────────────────────────────────────┘
```

## Memory Management

### Point Cloud Processing
- **Input**: 256×192 depth map = 49,152 pixels
- **Sampled**: 49,152 / 64 = ~768 points (with step=8)
- **Filtered**: ~500-1000 valid points (after depth filtering)
- **Memory**: ~12-24 KB per frame (3 floats × 4 bytes × 1000 points)

### NURBS Surfaces
- **Control Points**: 10×10 = 100 points per surface
- **Tessellation**: 20×20 = 400 vertices per surface
- **Triangles**: 2 × 19 × 19 = 722 triangles per surface
- **Surfaces**: Max 5 surfaces
- **Total Vertices**: 400 × 5 = 2,000 vertices
- **Total Triangles**: 722 × 5 = 3,610 triangles
- **Memory**: ~100 KB for all surfaces

### Frame Rate Target
- **Input**: 60 FPS (ARKit)
- **Processing**: 30-60 FPS (adaptive)
- **Rendering**: 60 FPS (RealityKit/Metal)

## Performance Bottlenecks

### Identified Bottlenecks:
1. **Depth buffer processing** (mitigated by sampling)
2. **Point clustering** (O(n²) - limited by max points)
3. **Control point fitting** (limited by grid size)
4. **NURBS evaluation** (simplified to bilinear)
5. **Mesh generation** (fixed resolution)

### Optimization Strategies:
1. **Spatial sampling**: Process every 8th pixel
2. **Depth filtering**: Reject points outside range
3. **Surface limiting**: Max 5 NURBS surfaces
4. **Fixed tessellation**: No adaptive refinement
5. **Background processing**: Keep main thread free
6. **Entity reuse**: Minimize allocation/deallocation

## Future Architecture Enhancements

### Short-term:
- Add surface caching for stable regions
- Implement adaptive tessellation
- Add texture mapping pipeline
- Optimize clustering algorithm

### Long-term:
- GPU-accelerated NURBS evaluation
- Multi-threaded surface generation
- Object detection integration
- Cloud processing offload
- Real-time collaboration

## Comparison with Original CLOCs

| Aspect | Original CLOCs | iOS Real-Time |
|--------|----------------|---------------|
| **Platform** | Python/PyTorch | Swift/iOS |
| **Architecture** | Offline batch | Online streaming |
| **Input** | KITTI dataset | LiDAR sensor |
| **Processing** | CPU/GPU (desktop) | Mobile GPU |
| **Output** | 3D bounding boxes | NURBS surfaces |
| **Latency** | Batch (minutes) | Real-time (33ms) |
| **Framework** | SECOND-1.5 | ARKit/RealityKit |
