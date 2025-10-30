import Foundation
import ARKit
import RealityKit
import Combine

class LiDARProcessor: ObservableObject {
    @Published var fps: Double = 0.0
    @Published var pointCount: Int = 0
    @Published var nurbsSurfaceCount: Int = 0
    
    private var nurbsGenerator = NURBSGenerator()
    private var currentSurfaces: [ModelEntity] = []
    
    // iOS 26: Use concurrent queue for better multi-core utilization
    private let processingQueue = DispatchQueue(label: "com.clocs.lidar.processing", 
                                                qos: .userInteractive, 
                                                attributes: .concurrent)
    
    func processDepthData(_ depthData: ARDepthData, frame: ARFrame) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let depthMap = depthData.depthMap
            let width = CVPixelBufferGetWidth(depthMap)
            let height = CVPixelBufferGetHeight(depthMap)
            
            CVPixelBufferLockBaseAddress(depthMap, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
            
            guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else { return }
            let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
            
            // iOS 26: Optimized point sampling with adaptive resolution
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
            
            DispatchQueue.main.async {
                self.pointCount = points.count
            }
            
            // Generate NURBS surfaces from point cloud
            let surfaces = self.nurbsGenerator.generateSurfaces(from: points)
            
            DispatchQueue.main.async {
                self.currentSurfaces = surfaces
                self.nurbsSurfaceCount = surfaces.count
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
                for i in 0..<vertices.count {
                    let vertex = vertices[i]
                    let worldPosition = transform * SIMD4<Float>(vertex.0, vertex.1, vertex.2, 1.0)
                    allPoints.append(SIMD3<Float>(worldPosition.x, worldPosition.y, worldPosition.z))
                }
            }
            
            DispatchQueue.main.async {
                self.pointCount = allPoints.count
            }
            
            // Generate NURBS surfaces from mesh vertices
            let surfaces = self.nurbsGenerator.generateSurfaces(from: allPoints)
            
            DispatchQueue.main.async {
                self.currentSurfaces = surfaces
                self.nurbsSurfaceCount = surfaces.count
            }
        }
    }
    
    func getNURBSSurfaces() -> [ModelEntity] {
        return currentSurfaces
    }
    
    private func unprojectPoint(x: Float, y: Float, depth: Float, intrinsics: simd_float3x3, transform: simd_float4x4) -> SIMD3<Float> {
        // Convert normalized coordinates to pixel coordinates
        let fx = intrinsics[0][0]
        let fy = intrinsics[1][1]
        let cx = intrinsics[2][0]
        let cy = intrinsics[2][1]
        
        // Calculate camera space coordinates
        let xCam = (x * Float(intrinsics[2][0]) * 2.0 - cx) * depth / fx
        let yCam = (y * Float(intrinsics[2][1]) * 2.0 - cy) * depth / fy
        let zCam = depth
        
        // Transform to world space
        let cameraSpacePoint = SIMD4<Float>(xCam, yCam, -zCam, 1.0)
        let worldSpacePoint = transform * cameraSpacePoint
        
        return SIMD3<Float>(worldSpacePoint.x, worldSpacePoint.y, worldSpacePoint.z)
    }
}
