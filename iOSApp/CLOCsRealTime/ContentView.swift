import SwiftUI

struct ContentView: View {
    @StateObject private var lidarProcessor = LiDARProcessor()
    @State private var showInfo = true
    
    var body: some View {
        ZStack {
            ARViewContainer(lidarProcessor: lidarProcessor)
                .ignoresSafeArea()
            
            VStack {
                if showInfo {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CLOCs Real-Time")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("NURBS Environment Mapping")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("FPS: \(lidarProcessor.fps, specifier: "%.1f")")
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundColor(.green)
                            Text("Points: \(lidarProcessor.pointCount)")
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundColor(.cyan)
                            Text("NURBS Surfaces: \(lidarProcessor.nurbsSurfaceCount)")
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        
                        Spacer()
                    }
                    .padding()
                }
                
                Spacer()
                
                Button(action: {
                    showInfo.toggle()
                }) {
                    Image(systemName: showInfo ? "info.circle.fill" : "info.circle")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
