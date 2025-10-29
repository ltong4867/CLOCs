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
        
        // Check if LiDAR is available (iPhone 12 Pro and later with LiDAR scanner)
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }
        
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        
        context.coordinator.arView = arView
        context.coordinator.lidarProcessor = lidarProcessor
        
        // Add lighting
        let sunlight = DirectionalLight()
        sunlight.light.intensity = 1000
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
            // Remove old NURBS surfaces
            arView.scene.anchors.forEach { anchor in
                if anchor.name.hasPrefix("nurbs_") {
                    arView.scene.removeAnchor(anchor)
                }
            }
            
            // Add new NURBS surfaces
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
