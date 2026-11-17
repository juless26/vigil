import SwiftUI
import VigilDesignSystem

struct ContentView: View {
    @State private var manager = WorkoutManager()

    var body: some View {
        VStack(spacing: VigilLayout.Space.s) {
            Text(manager.heartRate.map { "\(Int($0.rounded()))" } ?? "--")
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundStyle(VigilColor.textPrimary)
            Text("bpm")
                .font(.footnote)
                .foregroundStyle(VigilToken.Watch.accent)
            Text(manager.statusMessage)
                .font(.footnote)
                .foregroundStyle(VigilColor.textPrimary)
                .multilineTextAlignment(.center)

            if manager.isAlerting {
                Text("Turn your wrist to stop")
                    .font(.footnote)
                    .foregroundStyle(VigilToken.Watch.accent)
                    .multilineTextAlignment(.center)
            }

            switch manager.state {
            case .idle, .ended:
                WatchButton("Start session") { Task { await manager.start() } }
            case .running:
                WatchButton("End session") { Task { await manager.end() } }
            }
        }
        .padding(.horizontal, VigilLayout.Space.s)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VigilToken.Watch.background)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    ContentView()
}
