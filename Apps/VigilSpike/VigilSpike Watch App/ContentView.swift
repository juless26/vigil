import SwiftUI
import VigilDesignSystem

/// The mother's watch, built to match the "Watch · watchOS 26" page in the Vigil Figma file.
/// She never sees her heart rate here. Her nurse sees it on the iPhone.
struct ContentView: View {
    @State private var manager = WorkoutManager()
    /// Height of the strip at the top that holds the clock, measured once for the whole app.
    /// Swipeable pages report it as zero, so every screen reads it from here instead.
    @State private var clockStrip: CGFloat = 0

    var body: some View {
        screen
            .environment(\.clockStrip, clockStrip > 0 ? clockStrip : 30)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { clockStrip = geo.safeAreaInsets.top }
                        .onChange(of: geo.safeAreaInsets.top) { _, top in clockStrip = top }
                }
            }
            .background(VigilToken.Watch.background)
            .task { await manager.appeared() }
    }

    @ViewBuilder
    private var screen: some View {
        if manager.isAlerting {
            alertScreen
        } else {
            switch manager.phase {
            case .welcome, .waiting:
                welcomeScreen
            case .holding:
                if manager.goalReached {
                    goalCompleteScreen
                } else {
                    holdingScreen
                }
            case .waitingForNurse:
                waitForNurseScreen
            }
        }
    }

    // MARK: Pieces shared by the holding screens

    /// Figma: Goal Ring at 14, 14. Goal Readout right-aligned 14 from the edge, 4 lower than the ring.
    private func goalHeader(icon: GoalRing.Icon, _ f: FigmaScale) -> some View {
        let percent = Int((min(manager.goalProgress, 1) * 100).rounded(.down))
        let minutes = min(manager.heldSeconds / 60, WorkoutManager.goalMinutes)
        return HStack(alignment: .top, spacing: 0) {
            // The ring rises into the empty strip beside the clock.
            GoalRing(icon: icon, progress: manager.goalProgress)
                .padding(.top, 6)
            Spacer(minLength: 0)
            // The readout sits right under the clock at the top right.
            GoalReadout(percent: "GOAL \(percent)%",
                        minutes: "\(minutes)/\(WorkoutManager.goalMinutes) MIN")
                // The clock strip includes space above the time, so the readout can start a little inside it.
                .padding(.top, max(f.safeTop - 10, 18))
        }
        .padding(.horizontal, f.x(14))
    }

    /// Figma message text: 12 in from each edge, centered.
    private func message(_ text: String, _ f: FigmaScale, style: Font = .body,
                         color: Color = VigilColor.textPrimary, weight: Font.Weight = .regular) -> some View {
        Text(text)
            .font(style.weight(weight))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, f.x(12))
    }

    // MARK: Screens
    // Each gap is the Figma gap, resized in proportion to this watch's screen.
    // Rings, icons, text and buttons keep their real size.

    /// Figma: Watch · Welcome and Watch · 2 Hour Goal, combined.
    /// The welcome stays on screen above her goal until the nurse starts holding.
    private var welcomeScreen: some View {
        GeometryReader { geo in
            let f = FigmaScale(size: geo.size)
            VStack(spacing: 0) {
                // The hearts take whatever space the words leave, up to 120 × 110
                // (about 15% larger than Figma's 105 × 96, which read small on the watch),
                // centered in that space. The words always keep their full size.
                Image("Hearts")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 120, maxHeight: 110)
                    .frame(minHeight: 40, maxHeight: .infinity)
                    .accessibilityHidden(true)
                message("Welcome \(manager.motherName)!", f)
                    .padding(.top, f.y(8))
                // One text style smaller than the welcome, so the greeting leads.
                message("\(WorkoutManager.goalMinutes / 60) Hour Goal", f, style: .footnote)
                    .padding(.top, f.y(4))
                Spacer(minLength: f.y(12))
                    .frame(maxHeight: f.y(24))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// Figma: Watch · Snuggle Time. Her only holding screen.
    /// Pause calls the nurse, who then resumes or stops holding from the phone.
    private var holdingScreen: some View {
        FigmaLayout { f in
            VStack(spacing: 0) {
                goalHeader(icon: .handHeart, f)
                // The message and pause line sit centered between the goal and the pause button.
                Spacer(minLength: f.y(2))
                message("Snuggle time!", f, color: VigilToken.Watch.accent, weight: .semibold)
                // Always one line. At large text sizes it shrinks just enough to fit, to 70% at most.
                Text("Press pause for nurse")
                    .font(.caption2)
                    .foregroundStyle(VigilColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, f.x(6))
                    .padding(.top, f.y(4))
                Spacer(minLength: f.y(2))
                WatchIconButton(.pause, label: "Pause for nurse") { manager.pauseHolding() }
                    .padding(.bottom, f.y(12))
            }
        }
    }

    /// Figma: Watch · Tier 2 · Strong Vibration, now the only alert, without the End button.
    /// The watch taps until she turns her wrist. Her hands hold the baby, so the screen has
    /// nothing to tap. The nurse can end the session from the phone.
    private var alertScreen: some View {
        FigmaLayout { f in
            VStack(spacing: 0) {
                goalHeader(icon: .hand, f)
                Spacer(minLength: f.y(4))
                WristTurnHint(alert: .strongVibration)
                message("Rotate wrist to dismiss vibration alert.", f)
                    .accessibilityHidden(true)
                    .padding(.top, f.y(6))
                Spacer(minLength: f.y(4))
                Spacer(minLength: 0)
            }
        }
    }

    /// Figma: Watch · Wait for Nurse. Holding time is paused until the nurse resumes it.
    private var waitForNurseScreen: some View {
        FigmaLayout { f in
            VStack(spacing: 0) {
                goalHeader(icon: .pause, f)
                Spacer(minLength: 0)
                message("Please wait for the nurse.", f)
                Spacer(minLength: 0)
                Spacer(minLength: 0)
            }
        }
    }

    /// Figma: Watch · Goal Complete. The nurse's phone is told she reached her goal,
    /// and the nurse comes to relieve her. Nothing to tap.
    /// The falling hearts animation isn't built yet.
    private var goalCompleteScreen: some View {
        FigmaLayout { f in
            VStack(spacing: 0) {
                goalHeader(icon: .star, f)
                Spacer(minLength: f.y(4))
                message("Great job holding \(manager.babyName)!", f)
                Image("GoalHeart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 53)
                    .accessibilityHidden(true)
                    .padding(.top, f.y(14))
                Spacer(minLength: f.y(4))
                Spacer(minLength: 0)
            }
        }
    }
}

/// Converts Figma distances, drawn on the 46 mm watch (208 × 248), to this watch's screen.
/// Only gaps and insets use it. Components keep their real size.
struct FigmaScale {
    let size: CGSize
    /// Height of the strip at the top that holds the watch's clock.
    var safeTop: CGFloat = 0
    func x(_ figma: CGFloat) -> CGFloat { figma * size.width / 208 }
    func y(_ figma: CGFloat) -> CGFloat { figma * size.height / 248 }
}

/// Gives a screen the full display, plus a FigmaScale for its gaps and the clock strip's height.
/// watchOS always shows the time at the top right, so right-side content starts below it.
private struct FigmaLayout<Content: View>: View {
    @ViewBuilder let content: (FigmaScale) -> Content
    @Environment(\.clockStrip) private var clockStrip

    var body: some View {
        GeometryReader { geo in
            let f = FigmaScale(size: geo.size, safeTop: clockStrip)
            // If her text size is too large for the screen, the screen scrolls instead of cutting off.
            ViewThatFits(in: .vertical) {
                // Measured at its natural height, then stretched to fill, so ViewThatFits can tell when it's too tall.
                content(f)
                    .frame(width: geo.size.width)
                    .frame(maxHeight: .infinity)
                ScrollView {
                    // At least the full screen tall, so spacers still push content
                    // to the bottom instead of leaving an empty gap there.
                    content(f)
                        .frame(width: geo.size.width)
                        .frame(minHeight: geo.size.height)
                }
            }
        }
        // Screens use the full height, including the strip beside the clock.
        // Each screen keeps its own content clear of the clock itself.
        .ignoresSafeArea(edges: [.top, .bottom])
    }
}

private struct ClockStripKey: EnvironmentKey {
    static let defaultValue: CGFloat = 30
}

extension EnvironmentValues {
    /// Height of the strip at the top of the watch screen that holds the clock.
    var clockStrip: CGFloat {
        get { self[ClockStripKey.self] }
        set { self[ClockStripKey.self] = newValue }
    }
}

#Preview {
    ContentView()
}
