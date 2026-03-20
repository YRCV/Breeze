import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var smcManager = SMCManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HeaderView()
            
            HStack(spacing: 20) {
                TemperatureCard(title: "CPU", temperature: smcManager.cpuTemperature, history: smcManager.cpuHistory, icon: "cpu")
                TemperatureCard(title: "GPU", temperature: smcManager.gpuTemperature, history: smcManager.gpuHistory, icon: "display")
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
        .frame(width: 380) // Slightly wider for better charts
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
    let history: [Double]
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
            
            Chart {
                ForEach(Array(history.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Temp", value)
                    )
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", index),
                        y: .value("Temp", value)
                    )
                    .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: 30...100) // Realistic temperature range for MBP
            .frame(height: 40)
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
                Text(String(format: "%.0f", fan.actualSpeed) + " RPM")
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
                Text(String(format: "Min: %.0f", fan.minimumSpeed))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "Max: %.0f", fan.maximumSpeed))
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
