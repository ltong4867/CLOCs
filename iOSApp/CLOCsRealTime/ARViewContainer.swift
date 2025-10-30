import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    let lidarProcessor: LiDARProcessor
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session for LiDAR with iOS 26 enhancements
        let config = ARWorldTrackingConfiguration()
        
        // iOS 26: Enhanced scene reconstruction with improved mesh quality
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        // iOS 26: Enhanced plane detection with semantic classification
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        // iOS 26: Improved depth sensing with higher resolution
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }
        
        // iOS 26: Enable smooth depth for better NURBS fitting
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            config.frameSemantics.insert(.smoothedSceneDepth)
        }
        
        // iOS 26: Object occlusion for better AR integration
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        
        context.coordinator.arView = arView
        context.coordinator.lidarProcessor = lidarProcessor
        
        // iOS 26: Enhanced RealityKit lighting with image-based lighting
        arView.environment.lighting.intensityExponent = 1.5
        arView.environment.lighting.resource = nil // Use automatic IBL
        
        // Add dynamic lighting with iOS 26 improvements
        let sunlight = DirectionalLight()
        sunlight.light.intensity = 1000
        sunlight.light.color = .white
        sunlight.shadow = DirectionalLightComponent.Shadow(
            maximumDistance: 10.0,
            depthBias: 5.0
        )
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
            if let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor }), !meshAnchors.isEmpty {
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
