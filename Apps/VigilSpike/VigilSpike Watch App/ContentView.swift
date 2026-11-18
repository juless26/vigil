import SwiftUI
import VigilDesignSystem

/// The mother's watch, built to match the "Watch · watchOS 26" page in the Vigil Figma file.
/// She never sees her heart rate here. Her nurse sees it on the iPhone.
struct ContentView: View {
    @State private var manager = WorkoutManager()

    var body: some View {
        screen
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
                    holdingPages
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
            GoalRing(icon: icon, progress: manager.goalProgress)
            Spacer(minLength: 0)
            GoalReadout(percent: "GOAL \(percent)%",
                        minutes: "\(minutes)/\(WorkoutManager.goalMinutes) MIN")
                .padding(.top, 4)
        }
        .padding(.horizontal, f.x(14))
        .padding(.top, f.y(4))
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

    /// Figma buttons sit 16 in from each edge. WatchButton adds 4 above and below for the tap area.
    private func button(_ title: String, _ f: FigmaScale, action: @escaping () -> Void) -> some View {
        WatchButton(title, action: action)
            .padding(.horizontal, f.x(16))
    }

    private func endButton(_ f: FigmaScale) -> some View {
        button("End Holding Session", f) { Task { await manager.end() } }
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

    /// Figma: Watch · Snuggle Time (page 1) and Watch · Holding Controls (page 2).
    /// She swipes left for Pause and End.
    private var holdingPages: some View {
        TabView {
            FigmaLayout { f in
                VStack(spacing: 0) {
                    goalHeader(icon: .handHeart, f)
                    Spacer(minLength: f.y(8))
                    message("Snuggle time!", f, color: VigilToken.Watch.accent, weight: .semibold)
                    Spacer(minLength: f.y(8))
                    Spacer(minLength: 0)
                    WatchPageDots(page: .first)
                        .padding(.bottom, f.y(16))
                }
            }
            FigmaLayout { f in
                VStack(spacing: 0) {
                    goalHeader(icon: .handHeart, f)
                    Spacer(minLength: f.y(4))
                    VStack(spacing: 2) {
                        button("Pause Holding", f) { manager.pauseHolding() }
                        endButton(f)
                    }
                    Spacer(minLength: f.y(4))
                    WatchPageDots(page: .second)
                        .padding(.bottom, f.y(16))
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    /// Figma: Watch · Tier 2 · Strong Vibration, now the only alert.
    /// The watch taps until she turns her wrist. Her hands hold the baby, so nothing needs tapping.
    private var alertScreen: some View {
        FigmaLayout { f in
            VStack(spacing: 0) {
                goalHeader(icon: .hand, f)
                Spacer(minLength: 0)
                WristTurnHint(alert: .strongVibration)
                message("Rotate wrist to dismiss vibration alert.", f)
                    .accessibilityHidden(true)
                    .padding(.top, f.y(6))
                Spacer(minLength: 0)
                endButton(f)
                    .padding(.bottom, f.y(18))
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

    /// Figma: Watch · Goal Complete. The falling hearts animation isn't built yet.
    private var goalCompleteScreen: some View {
        FigmaLayout { f in
            VStack(spacing: 0) {
                goalHeader(icon: .star, f)
                Spacer(minLength: 0)
                message("Great job holding \(manager.babyName)!", f)
                Image("GoalHeart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 53)
                    .accessibilityHidden(true)
                    .padding(.top, f.y(14))
                Spacer(minLength: 0)
                endButton(f)
                    .padding(.bottom, f.y(18))
            }
        }
    }
}

/// Converts Figma distances, drawn on the 46 mm watch (208 × 248), to this watch's screen.
/// Only gaps and insets use it. Components keep their real size.
struct FigmaScale {
    let size: CGSize
    func x(_ figma: CGFloat) -> CGFloat { figma * size.width / 208 }
    func y(_ figma: CGFloat) -> CGFloat { figma * size.height / 248 }
}

/// Gives a screen the space below the watch's clock, plus a FigmaScale for its gaps.
/// watchOS always shows the time at the top right, so content starts below it.
private struct FigmaLayout<Content: View>: View {
    @ViewBuilder let content: (FigmaScale) -> Content

    var body: some View {
        GeometryReader { geo in
            let f = FigmaScale(size: geo.size)
            // If her text size is too large for the screen, the screen scrolls instead of cutting off.
            ViewThatFits(in: .vertical) {
                // Measured at its natural height, then stretched to fill, so ViewThatFits can tell when it's too tall.
                content(f)
                    .frame(width: geo.size.width)
                    .frame(maxHeight: .infinity)
                ScrollView {
                    content(f)
                        .frame(width: geo.size.width)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
