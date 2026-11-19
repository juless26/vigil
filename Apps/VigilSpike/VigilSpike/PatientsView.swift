import SwiftUI
import VigilDesignSystem

/// Patients tab: every mother on the unit and what is happening with her now.
struct PatientsView: View {
    @Bindable var store: SpikeStore
    @State private var adding = false

    var body: some View {
        NavigationStack(path: $store.patientsPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: VigilLayout.Space.m) {
                    if store.data.mothers.isEmpty {
                        Footnote("Add a mother to start her first holding session.")
                        VigilButton("Add mother") { adding = true }
                    } else {
                        TimelineView(.periodic(from: .now, by: 15)) { context in
                            RowGroup {
                                ForEach(store.data.mothers) { mother in
                                    NavigationLink(value: mother.id) {
                                        PatientRow(name: mother.name,
                                                   detail: store.detail(for: mother, now: context.date),
                                                   initials: mother.initials,
                                                   status: store.status(for: mother))
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        if store.data.live?.motherID != mother.id {
                                            Button("Remove \(mother.firstName)", role: .destructive) {
                                                store.removeMother(mother)
                                            }
                                        }
                                    }
                                    if mother.id != store.data.mothers.last?.id { RowSeparator() }
                                }
                            }
                        }
                        Footnote("Vigil follows one mother at a time, the one wearing the watch paired with this phone.")
                    }
                }
                .padding(VigilLayout.Space.l)
            }
            .background(VigilToken.screenBackground)
            .navigationTitle("Patients")
            .navigationDestination(for: UUID.self) { id in
                PatientView(store: store, motherID: id)
            }
            .toolbar {
                Button { adding = true } label: { Label("Add mother", systemImage: "plus") }
            }
            .sheet(isPresented: $adding) {
                NewMotherView(store: store)
            }
        }
    }
}

/// New mother setup. Only names and bed are kept, on this phone.
struct NewMotherView: View {
    let store: SpikeStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var baby = ""
    @State private var bed = ""

    private var ready: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !baby.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VigilLayout.Space.m) {
                    SectionHeader("Mother and baby")
                    RowGroup {
                        FormTextRow(label: "Mother", prompt: "Full name", text: $name)
                        RowSeparator()
                        FormTextRow(label: "Baby", prompt: "First name", text: $baby)
                        RowSeparator()
                        FormTextRow(label: "Bed", prompt: "Optional", text: $bed)
                    }
                    Footnote("Names and bed stay on this phone.")
                }
                .padding(VigilLayout.Space.l)
            }
            .background(VigilToken.screenBackground)
            .bottomAction {
                VigilButton("Add mother") {
                    store.addMother(name: name, baby: baby, bed: bed)
                    dismiss()
                }
                .disabled(!ready)
            }
            .navigationTitle("New mother")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
