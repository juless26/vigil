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
                    if let alert = store.nurseAlert {
                        AlertCard(
                            level: alert.level,
                            title: alert.title,
                            message: alert.message,
                            time: alert.raisedAt.formatted(date: .omitted, time: .shortened),
                            primary: primaryAction(for: alert),
                            secondary: secondaryAction(for: alert))
                    }

                    SectionHeader("Tester")
                    VStack(spacing: 0) {
                        FormTextRow(label: "Mother", prompt: "Required", text: $store.motherName)
                        Rectangle()
                            .fill(VigilToken.List.separator)
                            .frame(height: 0.5)
                        FormTextRow(label: "Baby", prompt: "Required", text: $store.babyName)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: VigilLayout.Radius.tile))
                    VigilButton("Send names to watch", style: .tinted) { store.sendNames() }
                        .disabled(store.motherName.trimmingCharacters(in: .whitespaces).isEmpty
                                  || store.babyName.trimmingCharacters(in: .whitespaces).isEmpty)

                    SectionHeader("Holding session")
                    VigilButton("Start holding") { store.startHolding() }
                    if store.holdingPaused {
                        VigilButton("Resume holding") { store.resumeHolding() }
                    }
                    if store.sessionActive {
                        VigilButton("Stop holding", style: .tinted) { store.stopHolding() }
                    }
                    Text("Open Vigil on the watch first. It waits on the 2 Hour Goal screen.")
                        .font(.footnote)
                        .foregroundStyle(VigilColor.textSecondary)

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
            .navigationTitle("Vigil")
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

    // The nurse decides what happens next, so each card offers the two real choices.
    private func primaryAction(for alert: NurseAlert) -> AlertCard.Action {
        switch alert.kind {
        case .vibration:
            AlertCard.Action("Stop watch vibration") { store.stopWatchVibration(); store.dismissAlert() }
        case .paused:
            AlertCard.Action("Resume holding") { store.resumeHolding(); store.dismissAlert() }
        case .goalReached:
            AlertCard.Action("Stop holding") { store.stopHolding(); store.dismissAlert() }
        }
    }

    private func secondaryAction(for alert: NurseAlert) -> AlertCard.Action {
        switch alert.kind {
        case .vibration, .goalReached:
            AlertCard.Action("Dismiss") { store.dismissAlert() }
        case .paused:
            AlertCard.Action("Stop holding") { store.stopHolding(); store.dismissAlert() }
        }
    }
}

#Preview {
    ContentView()
}
