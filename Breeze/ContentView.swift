import SwiftUI

struct ContentView: View {
    @StateObject private var smcManager = SMCManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HeaderView()
            
            HStack(spacing: 20) {
                TemperatureCard(title: "CPU", temperature: smcManager.cpuTemperature, icon: "cpu")
                TemperatureCard(title: "GPU", temperature: smcManager.gpuTemperature, icon: "display")
            }
            
            VStack(spacing: 16) {
                Text("Fans")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                if smcManager.fans.isEmpty {
                    Text("No fans detected.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(smcManager.fans) { fan in
                        FanRowView(fan: fan)
                    }
                }
            }
            .padding(.vertical)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(12)
        }
        .padding()
        .frame(width: 350)
        // Modern glassmorphic background
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}

// MARK: - Subviews

struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "wind")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.blue)
            Text("Breeze")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Spacer()
        }
        .padding(.bottom, 5)
    }
}

struct TemperatureCard: View {
    let title: String
    let temperature: Double
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", temperature))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("°C")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
}

struct FanRowView: View {
    let fan: FanData
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(fan.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\\(Int(fan.actualSpeed)) RPM")
                    .font(.subheadline.monospacedDigit())
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(fan.percentage / 100), height: 8)
                        // Add a slight animation when the percentage changes
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: fan.percentage)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("Min: \\(Int(fan.minimumSpeed))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Max: \\(Int(fan.maximumSpeed))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Visual Effect View
// Allows utilizing macOS native blur behind windows easily in SwiftUI
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
