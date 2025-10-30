import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    let lidarProcessor: LiDARProcessor
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session for LiDAR
        let config = ARWorldTrackingConfiguration()
        
        // Enable scene reconstruction if available
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        // Enable plane detection
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        // Enable depth sensing if available
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }
        
        // Enable smoothed scene depth if available (iOS 14+)
        if #available(iOS 14.0, *) {
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
                config.frameSemantics.insert(.smoothedSceneDepth)
            }
        }
        
        // Enable person segmentation with depth if available
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        
        context.coordinator.arView = arView
        context.coordinator.lidarProcessor = lidarProcessor
        
        // Configure lighting
        arView.environment.lighting.intensityExponent = 1.0
        
        // Add directional light for better visualization
        let sunlight = DirectionalLight()
        sunlight.light.intensity = 500
        sunlight.light.color = .white
        sunlight.look(at: [0, 0, 0], from: [0, 5, 5], relativeTo: nil)
        
        let lightAnchor = AnchorEntity(world: .zero)
        lightAnchor.addChild(sunlight)
        arView.scene.addAnchor(lightAnchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Updates handled by coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var arView: ARView?
        var lidarProcessor: LiDARProcessor?
        private var lastUpdateTime = Date()
        private var frameCount = 0
        private var cachedAnchors: [String: AnchorEntity] = [:]
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let lidarProcessor = lidarProcessor else { return }
            
            // Calculate FPS
            frameCount += 1
            let now = Date()
            let elapsed = now.timeIntervalSince(lastUpdateTime)
            if elapsed >= 1.0 {
                DispatchQueue.main.async {
                    lidarProcessor.fps = Double(self.frameCount) / elapsed
                }
                frameCount = 0
                lastUpdateTime = now
            }
            
            // Process depth data if available
            if let depthData = frame.sceneDepth {
                lidarProcessor.processDepthData(depthData, frame: frame)
                
                // Generate and display NURBS surfaces
                if let arView = arView {
                    updateNURBSVisualization(in: arView, processor: lidarProcessor)
                }
            }
            
            // Also process mesh anchors
            let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
            if !meshAnchors.isEmpty {
                lidarProcessor.processMeshAnchors(meshAnchors)
                
                if let arView = arView {
                    updateNURBSVisualization(in: arView, processor: lidarProcessor)
                }
            }
        }
        
        private func updateNURBSVisualization(in arView: ARView, processor: LiDARProcessor) {
            // Use efficient anchor management with diff-based updates
            let surfaces = processor.getNURBSSurfaces()
            
            // Create a set of current surface names
            var currentNames = Set<String>()
            
            // Update or add surfaces with proper coordinate space handling
            for (index, surfaceData) in surfaces.enumerated() {
                let anchorName = "nurbs_\(index)"
                currentNames.insert(anchorName)
                
                if let existingAnchor = cachedAnchors[anchorName] {
                    // Update existing anchor's position and child if content changed
                    existingAnchor.position = surfaceData.centroid
                    existingAnchor.children.removeAll()
                    existingAnchor.addChild(surfaceData.surface)
                } else {
                    // Create new anchor at the centroid position
                    let anchor = AnchorEntity(world: surfaceData.centroid)
                    anchor.name = anchorName
                    anchor.addChild(surfaceData.surface)
                    arView.scene.addAnchor(anchor)
                    cachedAnchors[anchorName] = anchor
                }
            }
            
            // Remove anchors that are no longer needed
            let anchorsToRemove = cachedAnchors.keys.filter { !currentNames.contains($0) }
            for anchorName in anchorsToRemove {
                if let anchor = cachedAnchors[anchorName] {
                    arView.scene.removeAnchor(anchor)
                    cachedAnchors.removeValue(forKey: anchorName)
                }
            }
        }
    }
}
