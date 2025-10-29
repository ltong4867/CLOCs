import Foundation
import RealityKit
import simd

class NURBSGenerator {
    // NURBS parameters
    private let degree = 3 // Cubic NURBS
    private let gridSize = 10 // Grid resolution for control points
    
    func generateSurfaces(from points: [SIMD3<Float>]) -> [ModelEntity] {
        guard points.count > 16 else { return [] }
        
        // Cluster points into regions for separate NURBS surfaces
        let clusters = clusterPoints(points, maxClusters: 5)
        
        var surfaces: [ModelEntity] = []
        
        for cluster in clusters {
            if let surface = createNURBSSurface(from: cluster) {
                surfaces.append(surface)
            }
        }
        
        return surfaces
    }
    
    private func clusterPoints(_ points: [SIMD3<Float>], maxClusters: Int) -> [[SIMD3<Float>]] {
        // Simple spatial clustering based on distance
        var clusters: [[SIMD3<Float>]] = []
        var remaining = points
        
        while !remaining.isEmpty && clusters.count < maxClusters {
            var currentCluster: [SIMD3<Float>] = []
            let seed = remaining.removeFirst()
            currentCluster.append(seed)
            
            // Find nearby points
            let threshold: Float = 1.0 // 1 meter radius
            var i = 0
            while i < remaining.count {
                let point = remaining[i]
                let distance = simd_distance(seed, point)
                
                if distance < threshold {
                    currentCluster.append(point)
                    remaining.remove(at: i)
                } else {
                    i += 1
                }
            }
            
            if currentCluster.count >= 9 { // Minimum points for a surface
                clusters.append(currentCluster)
            }
        }
        
        return clusters
    }
    
    private func createNURBSSurface(from points: [SIMD3<Float>]) -> ModelEntity? {
        guard points.count >= 9 else { return nil }
        
        // Create a grid of control points from the point cloud
        let controlPoints = createControlPointGrid(from: points, gridSize: gridSize)
        
        // Generate NURBS surface mesh
        let mesh = generateNURBSMesh(controlPoints: controlPoints)
        
        // Create material with wireframe and surface
        var material = SimpleMaterial()
        material.color = .init(tint: .init(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.7))
        material.roughness = .float(0.5)
        material.metallic = .float(0.1)
        
        // Create model entity
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        
        return modelEntity
    }
    
    private func createControlPointGrid(from points: [SIMD3<Float>], gridSize: Int) -> [[SIMD3<Float>]] {
        // Find bounding box
        var minPoint = points[0]
        var maxPoint = points[0]
        
        for point in points {
            minPoint = SIMD3<Float>(
                min(minPoint.x, point.x),
                min(minPoint.y, point.y),
                min(minPoint.z, point.z)
            )
            maxPoint = SIMD3<Float>(
                max(maxPoint.x, point.x),
                max(maxPoint.y, point.y),
                max(maxPoint.z, point.z)
            )
        }
        
        // Create grid of control points
        var grid: [[SIMD3<Float>]] = []
        
        for i in 0..<gridSize {
            var row: [SIMD3<Float>] = []
            for j in 0..<gridSize {
                let u = Float(i) / Float(gridSize - 1)
                let v = Float(j) / Float(gridSize - 1)
                
                // Interpolate position in bounding box
                let basePoint = SIMD3<Float>(
                    minPoint.x + u * (maxPoint.x - minPoint.x),
                    minPoint.y + v * (maxPoint.y - minPoint.y),
                    minPoint.z + u * v * (maxPoint.z - minPoint.z)
                )
                
                // Find nearest actual point to adjust height
                var nearestPoint = basePoint
                var minDistance: Float = .infinity
                
                for point in points {
                    let distance = simd_distance(
                        SIMD2<Float>(basePoint.x, basePoint.z),
                        SIMD2<Float>(point.x, point.z)
                    )
                    if distance < minDistance {
                        minDistance = distance
                        nearestPoint = point
                    }
                }
                
                // Use nearest point's Y coordinate for better surface fitting
                let controlPoint = SIMD3<Float>(basePoint.x, nearestPoint.y, basePoint.z)
                row.append(controlPoint)
            }
            grid.append(row)
        }
        
        return grid
    }
    
    private func generateNURBSMesh(controlPoints: [[SIMD3<Float>]]) -> MeshResource {
        let resolution = 20 // Tessellation resolution
        
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        var normals: [SIMD3<Float>] = []
        
        // Evaluate NURBS surface at regular intervals
        for i in 0..<resolution {
            for j in 0..<resolution {
                let u = Float(i) / Float(resolution - 1)
                let v = Float(j) / Float(resolution - 1)
                
                // Simple bilinear interpolation (simplified NURBS evaluation)
                let position = evaluateNURBS(controlPoints: controlPoints, u: u, v: v)
                positions.append(position)
            }
        }
        
        // Generate indices for triangles
        for i in 0..<(resolution - 1) {
            for j in 0..<(resolution - 1) {
                let topLeft = UInt32(i * resolution + j)
                let topRight = UInt32(i * resolution + j + 1)
                let bottomLeft = UInt32((i + 1) * resolution + j)
                let bottomRight = UInt32((i + 1) * resolution + j + 1)
                
                // First triangle
                indices.append(topLeft)
                indices.append(bottomLeft)
                indices.append(topRight)
                
                // Second triangle
                indices.append(topRight)
                indices.append(bottomLeft)
                indices.append(bottomRight)
            }
        }
        
        // Calculate normals
        for i in 0..<positions.count {
            // Simple normal calculation
            let normal = SIMD3<Float>(0, 1, 0)
            normals.append(normalize(normal))
        }
        
        // Create mesh descriptor
        var descriptor = MeshDescriptor(name: "NURBS_Surface")
        descriptor.positions = .init(positions)
        descriptor.primitives = .triangles(indices)
        descriptor.normals = .init(normals)
        
        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            print("Error generating NURBS mesh: \(error)")
            // Return a simple plane as fallback
            return MeshResource.generatePlane(width: 0.1, depth: 0.1)
        }
    }
    
    private func evaluateNURBS(controlPoints: [[SIMD3<Float>]], u: Float, v: Float) -> SIMD3<Float> {
        let rows = controlPoints.count
        let cols = controlPoints[0].count
        
        // Bilinear interpolation as simplified NURBS evaluation
        let i = min(Int(u * Float(rows - 1)), rows - 2)
        let j = min(Int(v * Float(cols - 1)), cols - 2)
        
        let localU = u * Float(rows - 1) - Float(i)
        let localV = v * Float(cols - 1) - Float(j)
        
        let p00 = controlPoints[i][j]
        let p10 = controlPoints[i + 1][j]
        let p01 = controlPoints[i][j + 1]
        let p11 = controlPoints[i + 1][j + 1]
        
        // Bilinear interpolation
        let p0 = p00 * (1 - localU) + p10 * localU
        let p1 = p01 * (1 - localU) + p11 * localU
        
        return p0 * (1 - localV) + p1 * localV
    }
}
