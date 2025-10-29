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
            if let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor }) as? [ARMeshAnchor], !meshAnchors.isEmpty {
                lidarProcessor.processMeshAnchors(meshAnchors)
                
                if let arView = arView {
                    updateNURBSVisualization(in: arView, processor: lidarProcessor)
                }
            }
        }
        
        private func updateNURBSVisualization(in arView: ARView, processor: LiDARProcessor) {
            // iOS 26: Use efficient anchor management for better performance
            // Remove old NURBS surfaces with batch operations
            let oldAnchors = arView.scene.anchors.filter { $0.name.hasPrefix("nurbs_") }
            oldAnchors.forEach { arView.scene.removeAnchor($0) }
            
            // iOS 26: Add new NURBS surfaces with enhanced materials
            let surfaces = processor.getNURBSSurfaces()
            for (index, surface) in surfaces.enumerated() {
                let anchor = AnchorEntity(world: .zero)
                anchor.name = "nurbs_\(index)"
                anchor.addChild(surface)
                arView.scene.addAnchor(anchor)
            }
        }
    }
}
