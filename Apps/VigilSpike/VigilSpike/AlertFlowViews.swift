import SwiftUI
import VigilDesignSystem

/// Check now fills the screen and stays until a nurse responds,
/// or until the mother turns her wrist.
struct CheckNowView: View {
    let store: SpikeStore

    var body: some View {
        ScrollView {
            VStack(spacing: VigilLayout.Space.m) {
                HStack(spacing: VigilLayout.Space.s) {
                    StatusBadge(status: .checkNow)
                    if let alert = store.nurseAlert {
                        Text(HeldTime.clock(alert.raisedAt))
                            .font(.footnote)
                            .foregroundStyle(VigilColor.textSecondary)
                    }
                }
                if let mother = store.liveMother {
                    PatientAvatar(initials: mother.initials, photo: nil, size: 72)
                        .accessibilityHidden(true)
                }
                VStack(spacing: VigilLayout.Space.xs) {
                    Text(store.nurseAlert?.title ?? "")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(VigilColor.textPrimary)
                    Text(store.liveMother?.nameLine ?? "")
                        .font(.subheadline)
                        .foregroundStyle(VigilColor.textSecondary)
                }
                .multilineTextAlignment(.center)
                .accessibilityElement(children: .combine)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    RowGroup {
                        VitalRow(label: "Watch alert", value: "30 sec", meta: "She has not turned her wrist")
                        RowSeparator()
                        LiveVitalRows(store: store, now: context.date)
                    }
                }
            }
            .padding(VigilLayout.Space.l)
        }
        // The whole screen takes the Check now tint, as in Figma.
        .background(VigilColor.statusCheckNowTint)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: VigilLayout.Space.s) {
                VigilButton("I’m going now") { store.nurseGoing() }
                Footnote("This alert stays until a nurse responds.")
            }
            .padding(VigilLayout.Space.l)
        }
    }
}

/// After a Check now, the nurse records what she found and what she did.
/// Moving the baby to the isolette ends the session.
struct FoundView: View {
    let store: SpikeStore
    @State private var found = -1
    @State private var did: Set<Int> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VigilLayout.Space.m) {
                    SectionHeader("When you got there")
                    RowGroup {
                        ForEach(NurseChoices.found.indices, id: \.self) { i in
                            ChoiceRow(NurseChoices.found[i], isSelected: found == i, mark: .radio) { found = i }
                            if i < NurseChoices.found.count - 1 { RowSeparator() }
                        }
                    }
                    SectionHeader("What you did · pick all that apply")
                    RowGroup {
                        ForEach(NurseChoices.did.indices, id: \.self) { i in
                            ChoiceRow(NurseChoices.did[i], isSelected: did.contains(i), mark: .checkbox) { toggle(i) }
                            if i < NurseChoices.did.count - 1 { RowSeparator() }
                        }
                    }
                    Footnote("Saved with this session on this phone. The mother does not see this.")
                }
                .padding(VigilLayout.Space.l)
            }
            .background(VigilToken.screenBackground)
            .bottomAction {
                VigilButton(did.contains(NurseChoices.isolette) ? "Save and end session" : "Save and resume holding") {
                    store.saveFinding(found: found, did: did.sorted())
                }
                .disabled(found < 0)
            }
            .navigationTitle("What you found")
            .subtitle(subtitleText)
        }
    }

    private var subtitleText: String {
        let name = store.liveMother?.name ?? ""
        guard let at = store.foundAlertAt else { return name }
        return "\(name) · alert at \(HeldTime.clock(at))"
    }

    /// "She kept holding" and "Moved the baby to the isolette" can't both be true.
    private func toggle(_ i: Int) {
        if did.contains(i) { did.remove(i); return }
        did.insert(i)
        if i == NurseChoices.keptHolding { did.remove(NurseChoices.isolette) }
        if i == NurseChoices.isolette { did.remove(NurseChoices.keptHolding) }
    }
}

/// When a session ends, the nurse sees how it went and picks why it ended.
struct SessionEndedView: View {
    let store: SpikeStore
    @State private var why = -1

    var body: some View {
        NavigationStack {
            ScrollView {
                if let e = store.data.ended {
                    let end = e.end ?? Date()
                    let held = e.heldSeconds(at: end)
                    VStack(alignment: .leading, spacing: VigilLayout.Space.m) {
                        SessionCard(label: "Holding time",
                                    elapsed: HeldTime.text(held),
                                    goal: "of 2 hr goal",
                                    meta: "Paused time is not counted.",
                                    progress: min(1, Double(held) / Double(HeldTime.goalSeconds)))
                        SectionHeader("During the session")
                        RowGroup {
                            VitalRow(label: "Watch alerts", value: "\(e.watchAlerts)",
                                     meta: e.watchAlerts == 0 ? "None" : "She answered \(e.answered) of \(e.watchAlerts)")
                            RowSeparator()
                            VitalRow(label: "Nurse alerts", value: "\(e.nurseAlerts)",
                                     meta: e.nurseAlerts == 0 ? "None" : "A nurse answered \(e.findings.count)")
                        }
                        SectionHeader("Why it ended")
                        RowGroup {
                            ForEach(NurseChoices.ended.indices, id: \.self) { i in
                                ChoiceRow(NurseChoices.ended[i], isSelected: why == i, mark: .radio) { why = i }
                                if i < NurseChoices.ended.count - 1 { RowSeparator() }
                            }
                        }
                        Footnote("Saved on this phone.")
                    }
                    .padding(VigilLayout.Space.l)
                }
            }
            .background(VigilToken.screenBackground)
            .bottomAction {
                VigilButton("Save session") { store.saveEnded(why: why) }
                    .disabled(why < 0)
            }
            .navigationTitle("Session ended")
            .subtitle(subtitleText)
        }
    }

    private var subtitleText: String {
        guard let e = store.data.ended else { return "" }
        let name = store.mother(e.motherID)?.name ?? ""
        return "\(name) · \(HeldTime.clock(e.start)) to \(HeldTime.clock(e.end ?? Date()))"
    }
}
