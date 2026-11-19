import SwiftUI
import UIKit
import VigilDesignSystem

/// The nurse app: four tabs, plus the Check now, What you found and Session ended screens,
/// which open over whatever tab the nurse is on.
struct ContentView: View {
    @State private var store = SpikeStore()

    var body: some View {
        TabView(selection: $store.selectedTab) {
            PatientsView(store: store)
                .tabItem { Label("Patients", systemImage: "person.2") }
                .tag(0)
            AlertsView(store: store)
                .tabItem { Label("Alerts", systemImage: store.nurseAlert == nil ? "bell" : "bell.badge") }
                .tag(1)
            UnitView(store: store)
                .tabItem { Label("Unit", systemImage: "chart.bar") }
                .tag(2)
            SettingsView(store: store)
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .fullScreenCover(isPresented: checkNowShown) {
            CheckNowView(store: store)
        }
        // One sheet for both steps, so What you found can hand over to Session ended.
        .sheet(item: flowSheet) { sheet in
            switch sheet {
            case .found: FoundView(store: store).interactiveDismissDisabled()
            case .ended: SessionEndedView(store: store).interactiveDismissDisabled()
            }
        }
        .onChange(of: store.nurseAlert?.id) { _, _ in
            guard let alert = store.nurseAlert else { return }
            AccessibilityNotification.Announcement("\(alert.level == .checkNow ? "Check now" : "Check soon"). \(alert.title)").post()
        }
        // The unit phone stays awake while a session runs.
        .onChange(of: store.data.live != nil, initial: true) { _, running in
            UIApplication.shared.isIdleTimerDisabled = running
        }
    }

    private var checkNowShown: Binding<Bool> {
        Binding(get: { store.nurseAlert?.level == .checkNow }, set: { _ in })
    }

    private enum FlowSheet: String, Identifiable {
        case found, ended
        var id: String { rawValue }
    }

    private var flowSheet: Binding<FlowSheet?> {
        Binding(get: {
            if store.showFound { return .found }
            if store.data.ended != nil, store.nurseAlert?.level != .checkNow { return .ended }
            return nil
        }, set: { _ in })
    }
}

extension View {
    /// The gray line under a large title, for example "Mother of Jeffrey · Bed 4". iOS 26 and later.
    @ViewBuilder
    func subtitle(_ text: String) -> some View {
        if #available(iOS 26.0, *) {
            navigationSubtitle(text)
        } else {
            self
        }
    }

    /// The screen's main button, pinned above the home indicator the way Figma shows it.
    func bottomAction<B: View>(@ViewBuilder _ button: () -> B) -> some View {
        let action = button()
        return safeAreaInset(edge: .bottom) {
            action
                .padding(.horizontal, VigilLayout.Space.l)
                .padding(.top, VigilLayout.Space.s)
                .padding(.bottom, VigilLayout.Space.s)
                .background(VigilToken.screenBackground)
        }
    }
}

/// A hairline between rows in a grouped list.
struct RowSeparator: View {
    var body: some View {
        Rectangle()
            .fill(VigilToken.List.separator)
            .frame(height: 0.5)
            .padding(.leading, VigilLayout.Space.l)
            .background(VigilToken.List.background)
            .accessibilityHidden(true)
    }
}

/// Rows stacked into one rounded group, the way every list in Vigil looks.
struct RowGroup<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .clipShape(RoundedRectangle(cornerRadius: VigilLayout.Radius.tile))
    }
}

/// A short line of help text under a section.
struct Footnote: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(VigilColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ContentView()
}
