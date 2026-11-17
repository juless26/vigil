import SwiftUI
import VigilDesignSystem

struct ContentView: View {
    @State private var store = SpikeStore()

    private let columns = [
        GridItem(.flexible(), spacing: VigilLayout.Space.m),
        GridItem(.flexible(), spacing: VigilLayout.Space.m)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VigilLayout.Space.m) {
                    SectionHeader("Live from the watch")
                    LazyVGrid(columns: columns, spacing: VigilLayout.Space.m) {
                        MetricTile(value: heartRateText, label: "Heart rate, bpm")
                        MetricTile(value: sampleAgeText, label: "Seconds since watch reading")
                        MetricTile(value: movementText, label: "Movement this 5 seconds")
                        MetricTile(value: "\(store.rows.count)", label: "Rows logged")
                    }
                    Text(store.watchReachable ? "Watch connected" : "Watch not reachable")
                        .font(.footnote)
                        .foregroundStyle(VigilColor.textSecondary)

                    SectionHeader("Alert rule v0.1")
                    LazyVGrid(columns: columns, spacing: VigilLayout.Space.m) {
                        MetricTile(value: ruleStateText, label: "Rule state")
                        MetricTile(value: baselineText, label: "Baseline, bpm")
                    }
                    Text("Vibrate the watch when the rule fires")
                        .font(.footnote)
                        .foregroundStyle(VigilColor.textSecondary)
                    Picker("Vibrate the watch when the rule fires", selection: $store.vibrateOnAlert) {
                        Text("Off").tag(false)
                        Text("On").tag(true)
                    }
                    .pickerStyle(.segmented)

                    SectionHeader("Test the alert")
                    VigilButton("Start alert on watch", style: .tinted) { store.sendWatchAlert() }
                    VigilButton("Stop watch vibration", style: .tinted) { store.stopWatchVibration() }

                    SectionHeader("Log")
                    Text(store.fileURL.lastPathComponent)
                        .font(.footnote)
                        .foregroundStyle(VigilColor.textSecondary)
                    VigilButton("Start new log", style: .tinted) { store.newLog() }
                }
                .padding(VigilLayout.Space.l)
            }
            .background(VigilToken.screenBackground)
            .navigationTitle("Vigil spike")
            .toolbar {
                ShareLink(item: store.fileURL) {
                    Label("Share log", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private var heartRateText: String {
        store.latestReading?.heartRate.map { "\(Int($0.rounded()))" } ?? "--"
    }

    private var sampleAgeText: String {
        store.latestReading?.sampleAge.map { String(format: "%.0f", $0) } ?? "--"
    }

    private var movementText: String {
        store.rows.last { $0.movement != nil }?.movement.map(String.init) ?? "--"
    }

    /// Plain words for each rule state, so the screen never relies on a code name.
    private var ruleStateText: String {
        switch store.rule.state {
        case .idle: "Not running"
        case .baseline: "Setting baseline"
        case .watching: "Watching"
        case .drowsy: "Drowsy signs"
        case .alerting: "Watch vibrating"
        case .nurseAlerted: "Nurse alerted"
        case .signalLost: "Signal lost"
        }
    }

    private var baselineText: String {
        store.rule.baseline.map { "\(Int($0.rounded()))" } ?? "--"
    }
}

#Preview {
    ContentView()
}
