import SwiftUI
import Charts

enum ThemeColor: String, CaseIterable, Identifiable {
    case blue, yellow, green, orange, purple, red
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .yellow: return .yellow
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .red: return .red
        }
    }
}

struct ContentView: View {
    @StateObject private var smcManager = SMCManager.shared
    @State private var showingSettings = false
    @AppStorage("themeColor") private var themeColor: ThemeColor = .blue
    
    var body: some View {
        VStack(spacing: 20) {
            HeaderView(showingSettings: $showingSettings, themeColor: themeColor.color)
            
            if showingSettings {
                SettingsView(showingSettings: $showingSettings)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                          removal: .move(edge: .trailing).combined(with: .opacity)))
            } else {
                DashboardView(smcManager: smcManager, themeColor: themeColor.color)
                    .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                          removal: .move(edge: .leading).combined(with: .opacity)))
            }
        }
        .padding()
        .frame(width: 380, height: 450) // Fixed size for consistency
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingSettings)
        // Modern glassmorphic background
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var smcManager: SMCManager
    let themeColor: Color
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                TemperatureCard(title: "CPU", temperature: smcManager.cpuTemperature, history: smcManager.cpuHistory, icon: "cpu", themeColor: themeColor)
                TemperatureCard(title: "GPU", temperature: smcManager.gpuTemperature, history: smcManager.gpuHistory, icon: "display", themeColor: themeColor)
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
                        FanRowView(fan: fan, themeColor: themeColor)
                    }
                }
            }
            .padding(.vertical)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(12)
            
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Binding var showingSettings: Bool
    @AppStorage("refreshInterval") private var refreshInterval = 2.0
    @AppStorage("themeColor") private var themeColor: ThemeColor = .blue
    
    var body: some View {
        VStack(spacing: 20) {
            Form {
                Section(header: Text("General").font(.headline)) {
                    VStack(alignment: .leading) {
                        Text("Refresh Interval: \(String(format: "%.1f", refreshInterval))s")
                        Slider(value: $refreshInterval, in: 1.0...10.0, step: 0.5)
                    }
                    .padding(.vertical, 5)
                    
                    Picker("Theme Color", selection: $themeColor) {
                        ForEach(ThemeColor.allCases) { colorOption in
                            HStack {
                                Circle()
                                    .fill(colorOption.color)
                                    .frame(width: 12, height: 12)
                                Text(colorOption.rawValue.capitalized)
                            }
                            .tag(colorOption)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("About").font(.headline)) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    Text("Breeze is a lightweight SMC monitoring tool for macOS.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden) // Makes it translucent
            
            Spacer(minLength: 10)
            
            Button("Done") {
                showingSettings = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.bottom, 5)
            .tint(themeColor.color)
        }
    }
}

// MARK: - Subviews

struct HeaderView: View {
    @Binding var showingSettings: Bool
    let themeColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: "wind")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(themeColor)
            Text("Breeze")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Spacer()
            
            if !showingSettings {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
        }
        .padding(.bottom, 5)
    }
}

struct TemperatureCard: View {
    let title: String
    let temperature: Double
    let history: [Double]
    let icon: String
    let themeColor: Color
    
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
                    .foregroundStyle(themeColor)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", index),
                        y: .value("Temp", value)
                    )
                    .foregroundStyle(themeColor.opacity(0.1))
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
    let themeColor: Color
    
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
                        .fill(themeColor)
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
