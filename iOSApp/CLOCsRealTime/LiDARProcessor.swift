import Foundation
import ARKit
import RealityKit
import Combine

class LiDARProcessor: ObservableObject {
    @Published var fps: Double = 0.0
    @Published var pointCount: Int = 0
    @Published var nurbsSurfaceCount: Int = 0
    
    private var nurbsGenerator = NURBSGenerator()
    private var currentSurfaces: [(surface: ModelEntity, centroid: SIMD3<Float>)] = []
    
    // Use .userInitiated QoS for background processing without blocking UI
    private let processingQueue = DispatchQueue(label: "com.clocs.lidar.processing", 
                                                qos: .userInitiated, 
                                                attributes: .concurrent)
    
    func processDepthData(_ depthData: ARDepthData, frame: ARFrame) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let depthMap = depthData.depthMap
            let width = CVPixelBufferGetWidth(depthMap)
            let height = CVPixelBufferGetHeight(depthMap)
            
            CVPixelBufferLockBaseAddress(depthMap, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
            
            guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
                print("Error: Could not get base address of depth map")
                return
            }
            let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
            
            // Optimized point sampling with adaptive resolution
            var points: [SIMD3<Float>] = []
            let sampleStep = 8 // Sample every 8th point for performance
            
            for y in stride(from: 0, to: height, by: sampleStep) {
                for x in stride(from: 0, to: width, by: sampleStep) {
                    let index = y * width + x
                    let depth = floatBuffer[index]
                    
                    // Filter out invalid depths
                    guard depth > 0.1 && depth < 10.0 else { continue }
                    
                    // Convert pixel coordinates to normalized coordinates
                    let normalizedX = Float(x) / Float(width)
                    let normalizedY = Float(y) / Float(height)
                    
                    // Unproject to 3D space
                    let point = self.unprojectPoint(
                        x: normalizedX,
                        y: normalizedY,
                        depth: depth,
                        intrinsics: frame.camera.intrinsics,
                        transform: frame.camera.transform
                    )
                    
                    points.append(point)
                }
            }
            
            // Debug log on first successful processing
            if points.count > 0 {
                print("Processed \(points.count) points from depth map (size: \(width)x\(height))")
            }
            
            DispatchQueue.main.async {
                self.pointCount = points.count
            }
            
            // Generate NURBS surfaces from point cloud
            if points.count > 0 {
                let surfaces = self.nurbsGenerator.generateSurfaces(from: points)
                print("Generated \(surfaces.count) NURBS surfaces")
                
                DispatchQueue.main.async {
                    self.currentSurfaces = surfaces
                    self.nurbsSurfaceCount = surfaces.count
                }
            }
        }
    }
    
    func processMeshAnchors(_ meshAnchors: [ARMeshAnchor]) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            var allPoints: [SIMD3<Float>] = []
            
            for meshAnchor in meshAnchors {
                let geometry = meshAnchor.geometry
                let vertices = geometry.vertices
                let transform = meshAnchor.transform
                
                // Extract vertex positions
                let vertexCount = Int(vertices.count)
                let vertexBuffer = vertices.buffer.contents()
                let vertexStride = vertices.stride
                
                for i in 0..<vertexCount {
                    let vertexPointer = vertexBuffer.advanced(by: i * vertexStride)
                    let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                    let worldPosition = transform * SIMD4<Float>(vertex.x, vertex.y, vertex.z, 1.0)
                    allPoints.append(SIMD3<Float>(worldPosition.x, worldPosition.y, worldPosition.z))
                }
            }
            
            // Debug log
            if allPoints.count > 0 {
                print("Processed \(allPoints.count) points from \(meshAnchors.count) mesh anchors")
            }
            
            DispatchQueue.main.async {
                self.pointCount = allPoints.count
            }
            
            // Generate NURBS surfaces from mesh vertices
            if allPoints.count > 0 {
                let surfaces = self.nurbsGenerator.generateSurfaces(from: allPoints)
                print("Generated \(surfaces.count) NURBS surfaces from mesh")
                
                DispatchQueue.main.async {
                    self.currentSurfaces = surfaces
                    self.nurbsSurfaceCount = surfaces.count
                }
            }
        }
    }
    
    func getNURBSSurfaces() -> [(surface: ModelEntity, centroid: SIMD3<Float>)] {
        return currentSurfaces
    }
    
    private func unprojectPoint(x: Float, y: Float, depth: Float, intrinsics: simd_float3x3, transform: simd_float4x4) -> SIMD3<Float> {
        // Camera intrinsics matrix format:
        // [fx  0  cx]
        // [0  fy  cy]
        // [0   0   1]
        let fx = intrinsics[0][0]
        let fy = intrinsics[1][1]
        let cx = intrinsics[0][2]
        let cy = intrinsics[1][2]
        
        // Get image dimensions from the intrinsics
        let imageWidth = cx * 2.0
        let imageHeight = cy * 2.0
        
        // Convert normalized coordinates (0-1) to pixel coordinates
        let pixelX = x * imageWidth
        let pixelY = y * imageHeight
        
        // Calculate camera space coordinates using pinhole camera model
        let xCam = (pixelX - cx) * depth / fx
        let yCam = (pixelY - cy) * depth / fy
        let zCam = depth
        
        // Transform to world space
        let cameraSpacePoint = SIMD4<Float>(xCam, yCam, -zCam, 1.0)
        let worldSpacePoint = transform * cameraSpacePoint
        
        return SIMD3<Float>(worldSpacePoint.x, worldSpacePoint.y, worldSpacePoint.z)
    }
}
