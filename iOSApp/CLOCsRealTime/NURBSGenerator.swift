import Foundation
import RealityKit
import simd

class NURBSGenerator {
    // Grid parameters
    private let gridSize = 10 // Grid resolution for control points
    
    func generateSurfaces(from points: [SIMD3<Float>]) -> [(surface: ModelEntity, centroid: SIMD3<Float>)] {
        guard points.count > 16 else { return [] }
        
        // Cluster points into regions for separate NURBS surfaces
        let clusters = clusterPoints(points, maxClusters: 5)
        
        var surfaces: [(surface: ModelEntity, centroid: SIMD3<Float>)] = []
        
        for cluster in clusters {
            if let result = createNURBSSurface(from: cluster) {
                surfaces.append(result)
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
            let seed = remaining.removeLast() // O(1) instead of removeFirst()
            currentCluster.append(seed)
            
            // Find nearby points using swap-remove pattern for O(1) deletions
            let threshold: Float = 1.0 // 1 meter radius
            var i = 0
            while i < remaining.count {
                let point = remaining[i]
                let distance = simd_distance(seed, point)
                
                if distance < threshold {
                    currentCluster.append(point)
                    // Swap with last element and remove - O(1) operation
                    remaining.swapAt(i, remaining.count - 1)
                    remaining.removeLast()
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
    
    private func createNURBSSurface(from points: [SIMD3<Float>]) -> (surface: ModelEntity, centroid: SIMD3<Float>)? {
        guard points.count >= 9 else { return nil }
        
        // Calculate centroid of the cluster
        var centroid = SIMD3<Float>(0, 0, 0)
        for point in points {
            centroid += point
        }
        centroid /= Float(points.count)
        
        // Transform points to local space around centroid
        let localPoints = points.map { $0 - centroid }
        
        // Create a grid of control points from the point cloud in local space
        let controlPoints = createControlPointGrid(from: localPoints, gridSize: gridSize)
        
        // Generate NURBS surface mesh in local space
        let mesh = generateNURBSMesh(controlPoints: controlPoints)
        
        // Use initializer-based SimpleMaterial API for better compatibility
        var material = SimpleMaterial(color: .init(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.75),
                                      roughness: 0.4,
                                      isMetallic: false)
        
        // Create model entity
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        
        return (surface: modelEntity, centroid: centroid)
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
                
                // Bilinear surface evaluation (simplified approach)
                let position = evaluateSurface(controlPoints: controlPoints, u: u, v: v)
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
        
        // Calculate normals per-vertex from triangle faces
        normals = Array(repeating: SIMD3<Float>(0, 0, 0), count: positions.count)
        
        // Accumulate face normals for each vertex
        for i in stride(from: 0, to: indices.count, by: 3) {
            let i0 = Int(indices[i])
            let i1 = Int(indices[i + 1])
            let i2 = Int(indices[i + 2])
            
            let p0 = positions[i0]
            let p1 = positions[i1]
            let p2 = positions[i2]
            
            // Calculate face normal using cross product
            let edge1 = p1 - p0
            let edge2 = p2 - p0
            let faceNormal = cross(edge1, edge2)
            
            // Accumulate to vertex normals
            normals[i0] += faceNormal
            normals[i1] += faceNormal
            normals[i2] += faceNormal
        }
        
        // Normalize all vertex normals
        for i in 0..<normals.count {
            normals[i] = normalize(normals[i])
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
    
    private func evaluateSurface(controlPoints: [[SIMD3<Float>]], u: Float, v: Float) -> SIMD3<Float> {
        let rows = controlPoints.count
        let cols = controlPoints[0].count
        
        // Bilinear interpolation for surface evaluation
        // NOTE: This is a simplified approximation, not true NURBS with basis functions
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
