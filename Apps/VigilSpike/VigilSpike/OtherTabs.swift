import SwiftUI
import VigilDesignSystem

/// Alerts tab: the alert waiting now and today's earlier alerts.
struct AlertsView: View {
    let store: SpikeStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VigilLayout.Space.m) {
                    if let alert = store.nurseAlert {
                        SectionHeader("Waiting now")
                        AlertCard(level: alert.level, title: alert.title, message: alert.message,
                                  time: HeldTime.clock(alert.raisedAt),
                                  primary: AlertActions.primary(for: alert, store: store),
                                  secondary: AlertActions.secondary(for: alert, store: store))
                    } else {
                        Footnote("No alerts waiting.")
                    }
                    let today = store.data.alerts.filter {
                        Calendar.current.isDateInToday($0.raisedAt) && $0.resolvedAt != nil
                    }
                    if !today.isEmpty {
                        SectionHeader("Earlier today")
                        RowGroup {
                            ForEach(today) { a in
                                VitalRow(label: a.title, value: HeldTime.clock(a.raisedAt),
                                         meta: (a.isCheckNow ? "Check now" : "Check soon")
                                            + (a.resolvedAt.map { " · answered \(HeldTime.clock($0))" } ?? ""))
                                if a.id != today.last?.id { RowSeparator() }
                            }
                        }
                    }
                    if !store.alertsOn {
                        Footnote("Recording only is on in Settings, so drowsiness alerts are off.")
                    }
                }
                .padding(VigilLayout.Space.l)
            }
            .background(VigilToken.screenBackground)
            .navigationTitle("Alerts")
        }
    }
}

/// Unit tab: today's totals and recent sessions.
struct UnitView: View {
    let store: SpikeStore

    private let columns = [
        GridItem(.flexible(), spacing: VigilLayout.Space.m),
        GridItem(.flexible(), spacing: VigilLayout.Space.m)
    ]

    var body: some View {
        let today = store.data.sessions.filter { Calendar.current.isDateInToday($0.start) }
        let held = today.reduce(0) { $0 + $1.heldSeconds }
        let taps = today.reduce(0) { $0 + $1.watchAlerts }
        let answered = today.reduce(0) { $0 + $1.answered }
        let nurse = today.reduce(0) { $0 + $1.nurseAlerts }
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VigilLayout.Space.m) {
                    SectionHeader("Today")
                    LazyVGrid(columns: columns, spacing: VigilLayout.Space.m) {
                        MetricTile(value: "\(today.count)", label: "Sessions")
                        MetricTile(value: HeldTime.text(held), label: "Time held")
                        MetricTile(value: taps == 0 ? "--" : "\(answered) of \(taps)", label: "Watch alerts answered")
                        MetricTile(value: "\(nurse)", label: "Nurse alerts")
                    }
                    if !store.data.sessions.isEmpty {
                        SectionHeader("Recent sessions")
                        RowGroup {
                            ForEach(store.data.sessions.prefix(20)) { s in
                                VitalRow(label: store.mother(s.motherID)?.name ?? "Removed",
                                         value: HeldTime.text(s.heldSeconds),
                                         meta: s.start.formatted(.dateTime.month(.abbreviated).day().hour().minute())
                                            + " · " + (NurseChoices.ended[safe: s.whyEnded] ?? ""))
                                if s.id != store.data.sessions.prefix(20).last?.id { RowSeparator() }
                            }
                        }
                    }
                    Footnote("Sessions stay on this phone.")
                }
                .padding(VigilLayout.Space.l)
            }
            .background(VigilToken.screenBackground)
            .navigationTitle("Unit")
        }
    }
}

/// Settings tab: the recording-only switch, the watch, logs, and tester tools.
struct SettingsView: View {
    @Bindable var store: SpikeStore

    private let columns = [
        GridItem(.flexible(), spacing: VigilLayout.Space.m),
        GridItem(.flexible(), spacing: VigilLayout.Space.m)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VigilLayout.Space.m) {
                    SectionHeader("Alerts")
                    Picker("Alerts", selection: $store.alertsOn) {
                        Text("Recording only").tag(false)
                        Text("Alerts on").tag(true)
                    }
                    .pickerStyle(.segmented)
                    Footnote(store.alertsOn
                        ? "The watch vibrates when it senses drowsiness. If she does not turn her wrist within 30 seconds, you get Check now."
                        : "Vigil records heart rate and movement but alerts no one about drowsiness. Pause and goal alerts still reach you.")

                    SectionHeader("Watch")
                    RowGroup {
                        VitalRow(label: "Paired watch",
                                 value: store.watchReachable ? "Connected" : "Not reachable",
                                 meta: "Open Vigil on the watch to connect")
                    }

                    SectionHeader("Logs")
                    VigilButton("Get logs from watch", style: .tinted) { store.getWatchLogs() }
                    RowGroup {
                        ForEach(store.savedLogs, id: \.self) { url in
                            ShareLink(item: url) {
                                HStack {
                                    Text(url.lastPathComponent.hasPrefix("watch-log-")
                                         ? "Watch · " + url.lastPathComponent.dropFirst(10).dropLast(4)
                                         : "Phone · " + url.lastPathComponent.dropFirst(10).dropLast(4))
                                        .font(.body)
                                        .foregroundStyle(VigilColor.textPrimary)
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(VigilColor.actionPrimary)
                                }
                                .frame(minHeight: VigilLayout.Size.touchMin)
                                .padding(.horizontal, VigilLayout.Space.l)
                                .background(VigilColor.surfaceCard)
                            }
                            .accessibilityLabel("Share log \(url.lastPathComponent)")
                        }
                    }

                    SectionHeader("Tester tools")
                    LazyVGrid(columns: columns, spacing: VigilLayout.Space.m) {
                        MetricTile(value: ruleStateText, label: "Rule state")
                        MetricTile(value: store.rule.baseline.map { "\(Int($0.rounded()))" } ?? "--", label: "Baseline, bpm")
                    }
                    VigilButton("Start alert on watch", style: .tinted) { store.sendWatchAlert() }
                    VigilButton("Stop watch vibration", style: .tinted) { store.stopWatchVibration() }
                    VigilButton("Jump to goal", style: .tinted) { store.jumpToGoal() }
                    VigilButton("Start new log", style: .tinted) { store.newLog() }
                    Footnote(store.fileURL.lastPathComponent)
                }
                .padding(VigilLayout.Space.l)
            }
            .background(VigilToken.screenBackground)
            .navigationTitle("Settings")
        }
    }

    /// Plain words for each rule state.
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
}
