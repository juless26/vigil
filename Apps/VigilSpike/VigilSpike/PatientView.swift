import SwiftUI
import VigilDesignSystem

/// One mother: her session now, live readings from the watch, and past sessions.
struct PatientView: View {
    @Bindable var store: SpikeStore
    let motherID: UUID
    @State private var starting = false
    @State private var confirmEnd = false

    var body: some View {
        if let mother = store.mother(motherID) {
            content(mother)
        } else {
            Footnote("This mother was removed.")
        }
    }

    private func content(_ mother: Mother) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: VigilLayout.Space.m) {
                    if let alert = store.nurseAlert, store.data.live?.motherID == mother.id,
                       alert.level == .checkSoon {
                        AlertCard(level: alert.level, title: alert.title, message: alert.message,
                                  time: HeldTime.clock(alert.raisedAt),
                                  primary: AlertActions.primary(for: alert, store: store),
                                  secondary: AlertActions.secondary(for: alert, store: store))
                    }

                    if let problem = store.watchProblem { Footnote(problem) }

                    if let live = store.data.live, live.motherID == mother.id {
                        liveSection(live, now: context.date)
                    } else if let other = store.liveMother {
                        Footnote("\(other.firstName) is holding now. Start \(mother.firstName)'s session after hers ends.")
                    } else {
                        VigilButton("Start holding") { starting = true }
                    }

                    let past = store.sessions(for: mother)
                    if !past.isEmpty {
                        SectionHeader("Past sessions")
                        RowGroup {
                            ForEach(past.prefix(10)) { s in
                                VitalRow(label: s.start.formatted(.dateTime.month(.abbreviated).day().hour().minute()),
                                         value: HeldTime.text(s.heldSeconds),
                                         meta: NurseChoices.ended[safe: s.whyEnded] ?? "")
                                if s.id != past.prefix(10).last?.id { RowSeparator() }
                            }
                        }
                    }
                }
                .padding(VigilLayout.Space.l)
            }
        }
        .background(VigilToken.screenBackground)
        .navigationTitle(mother.name)
        .subtitle(mother.bedLine)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PatientAvatar(initials: mother.initials, photo: nil, size: VigilLayout.Size.avatar)
                    .accessibilityHidden(true)
            }
        }
        .sheet(isPresented: $starting) { StartHoldingView(store: store, mother: mother) }
        .confirmationDialog("End holding for \(mother.firstName)?", isPresented: $confirmEnd,
                            titleVisibility: .visible) {
            Button("End session", role: .destructive) { store.stopHolding() }
        }
    }

    @ViewBuilder
    private func liveSection(_ live: LiveSession, now: Date) -> some View {
        let held = live.heldSeconds(at: now)
        let pause: (() -> Void)? = live.isPaused ? nil : { store.pauseHolding() }
        let end: (() -> Void)? = live.isPaused ? nil : { confirmEnd = true }
        SessionCard(label: live.isPaused ? "Holding paused" : "Holding session",
                    elapsed: HeldTime.text(held),
                    goal: "of 2 hr goal",
                    meta: "Started \(HeldTime.clock(live.start)) · "
                        + (store.watchReachable ? "watch connected" : "watch not reachable"),
                    progress: min(1, Double(held) / Double(HeldTime.goalSeconds)),
                    onPause: pause,
                    onEnd: end)
        // When she pressed pause, the alert card above already offers these two choices.
        if live.isPaused, store.nurseAlert?.kind != .paused {
            HStack(spacing: VigilLayout.Space.s) {
                VigilButton("Resume holding") { store.resumeHolding() }
                VigilButton("End session", style: .tinted) { confirmEnd = true }
            }
        }
        SectionHeader("Live from her watch")
        LiveVitals(store: store, now: now)
    }
}

/// Heart rate and movement as the watch last reported them, as their own group.
struct LiveVitals: View {
    let store: SpikeStore
    let now: Date

    var body: some View {
        RowGroup { LiveVitalRows(store: store, now: now) }
    }
}

/// The heart rate and movement rows, for use inside a larger group.
struct LiveVitalRows: View {
    let store: SpikeStore
    let now: Date

    var body: some View {
        VStack(spacing: 0) {
            VitalRow(label: "Heart rate", value: heartRate, unit: "bpm", meta: heartMeta)
            RowSeparator()
            VitalRow(label: "Movement", value: movement, meta: movementMeta)
        }
    }

    private var heartRate: String {
        store.latestReading?.heartRate.map { "\(Int($0.rounded()))" } ?? "--"
    }

    private var heartMeta: String {
        guard let row = store.latestReading, let hr = row.heartRate else { return "Waiting for the watch" }
        let place: String
        if let base = store.rule.baseline {
            let b = Int(base.rounded())
            place = hr < base - 3 ? "Below her resting \(b)" : hr > base + 3 ? "Above her resting \(b)" : "At her resting \(b)"
        } else {
            place = "Learning her resting rate"
        }
        return "\(place) · \(age(of: row)) sec ago"
    }

    private var movement: String {
        guard let count = store.latestMovement?.movement else { return "--" }
        return count > 0 ? "Moving" : "Still"
    }

    private var movementMeta: String {
        guard let row = store.latestMovement else { return "Waiting for the watch" }
        return "Last 5 seconds · \(age(of: row)) sec ago"
    }

    private func age(of row: LogRow) -> Int {
        max(0, Int(now.timeIntervalSince(row.receivedAt) + (row.sampleAge ?? 0)))
    }
}

/// Checks before holding starts, then starts the watch.
struct StartHoldingView: View {
    let store: SpikeStore
    let mother: Mother
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VigilLayout.Space.m) {
                    SectionHeader("Before you start")
                    RowGroup {
                        VitalRow(label: "1. Put the watch on her wrist", value: "", meta: "Snug, above the wrist bone")
                        RowSeparator()
                        VitalRow(label: "2. Open Vigil on the watch", value: "",
                                 meta: "It says Welcome \(mother.firstName)!")
                        RowSeparator()
                        VitalRow(label: "3. Confirm and start", value: "",
                                 meta: store.watchReachable ? "Watch connected" : "Watch not reachable yet")
                    }
                    Footnote("Vigil learns her resting heart rate in the first 6 minutes, then again in minutes 10 to 20, once she has settled.")
                    if !store.alertsOn {
                        Footnote("Recording only is on in Settings. The watch will not vibrate and you will not get drowsiness alerts. Pause and goal alerts still come through.")
                    }
                    if let problem = store.watchProblem { Footnote(problem) }
                }
                .padding(VigilLayout.Space.l)
            }
            .background(VigilToken.screenBackground)
            .bottomAction {
                VigilButton("Confirm and start") {
                    store.startHolding(for: mother)
                    if store.watchProblem == nil { dismiss() }
                }
                .disabled(!store.watchReachable)
            }
            .navigationTitle("Start holding")
            .subtitle(mother.nameLine)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            // Puts her name on the watch so it greets her before the session starts.
            .onAppear { store.sendNames(for: mother) }
        }
    }
}

/// The two choices each kind of alert offers the nurse.
enum AlertActions {
    static func primary(for alert: NurseAlert, store: SpikeStore) -> AlertCard.Action {
        switch alert.kind {
        case .vibration: AlertCard.Action("I'm going now") { store.nurseGoing() }
        case .paused: AlertCard.Action("Resume holding") { store.resumeHolding() }
        case .goalReached: AlertCard.Action("Stop holding") { store.stopHolding() }
        case .signalLost: AlertCard.Action("Dismiss") { store.dismissAlert() }
        }
    }

    static func secondary(for alert: NurseAlert, store: SpikeStore) -> AlertCard.Action {
        switch alert.kind {
        case .vibration: AlertCard.Action("Stop watch vibration") { store.stopWatchVibration(); store.dismissAlert() }
        case .paused, .signalLost: AlertCard.Action("Stop holding") { store.stopHolding() }
        case .goalReached: AlertCard.Action("Dismiss") { store.dismissAlert() }
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
