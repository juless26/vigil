import Foundation
import HealthKit
import CoreMotion
import WatchConnectivity
import WatchKit
import Observation

/// Runs a workout session so the watch reads heart rate about every 5 seconds,
/// counts wrist movement, and sends one row to the iPhone every 5 seconds.
/// The nurse starts and resumes holding from the iPhone. The mother never sees her heart rate.
@Observable
final class WorkoutManager: NSObject {
    /// Which Figma screen the watch shows.
    enum Phase {
        /// Figma: Watch · Welcome. Shown when the app opens.
        case welcome
        /// Figma: Watch · 2 Hour Goal. Shown after a session ends. Looks the same as welcome.
        case waiting
        /// Figma: Watch · Snuggle Time and Holding Controls.
        case holding
        /// Figma: Watch · Wait for Nurse. Holding time is paused until the nurse resumes it.
        case waitingForNurse
    }

    /// Names the nurse sets on the iPhone before a session. The watch keeps them until she changes them.
    /// The Figma sample names are the starting values.
    var motherName = UserDefaults.standard.string(forKey: "motherName") ?? "Malika" {
        didSet { UserDefaults.standard.set(motherName, forKey: "motherName") }
    }
    var babyName = UserDefaults.standard.string(forKey: "babyName") ?? "Jeffrey" {
        didSet { UserDefaults.standard.set(babyName, forKey: "babyName") }
    }
    /// Her holding goal, in minutes.
    static let goalMinutes = 120

    var phase: Phase = .welcome
    var heartRate: Double?
    var statusMessage = "Not started"
    /// Seconds she has held her baby this session, not counting pauses.
    var heldSeconds = 0
    var goalProgress: Double { Double(heldSeconds) / Double(Self.goalMinutes * 60) }
    var goalReached: Bool { goalProgress >= 1 }
    /// True while an alert is waiting for the mother to turn her wrist.
    var isAlerting = false

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var lastSampleDate: Date?

    private let motion = CMMotionManager()
    private var movementCount = 0
    private var sliceTask: Task<Void, Never>?
    private var alertTask: Task<Void, Never>?
    private var holdingClock: Task<Void, Never>?

    /// One log row every 5 seconds, matching the alert rule spec.
    private let sliceSeconds: TimeInterval = 5
    /// A reading counts as movement when the wrist's acceleration is this far from still (in g).
    private let movementThreshold = 0.05

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    /// Asks for Health access as soon as the app opens, so the nurse's Start works without a prompt.
    func appeared() async {
        try? await healthStore.requestAuthorization(
            toShare: [HKObjectType.workoutType()],
            read: [HKQuantityType(.heartRate)]
        )
    }

    // MARK: Session

    func start() async {
        guard phase == .welcome || phase == .waiting else { return }
        do {
            try await healthStore.requestAuthorization(
                toShare: [HKObjectType.workoutType()],
                read: [HKQuantityType(.heartRate)]
            )
        } catch {
            statusMessage = "Health access failed"
            return
        }

        let config = HKWorkoutConfiguration()
        config.activityType = .mindAndBody
        config.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            session.delegate = self
            builder.delegate = self
            self.session = session
            self.builder = builder

            let startDate = Date()
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)

            phase = .holding
            heldSeconds = 0
            statusMessage = "Recording"
            startMotion()
            startSliceTimer()
            startHoldingClock()
            send(event: "session started")
        } catch {
            statusMessage = "Could not start: \(error.localizedDescription)"
        }
    }

    func end() async {
        sliceTask?.cancel()
        sliceTask = nil
        holdingClock?.cancel()
        holdingClock = nil
        stopAlert()
        motion.stopDeviceMotionUpdates()
        session?.end()
        do {
            try await builder?.endCollection(at: Date())
        } catch {}
        // Spike sits are tests, so they are not saved to the Health app.
        builder?.discardWorkout()
        send(event: "session ended")
        phase = .waiting
        statusMessage = "Ended"
    }

    // MARK: Holding time

    /// Counts held time once a second, except while waiting for the nurse.
    private func startHoldingClock() {
        holdingClock?.cancel()
        holdingClock = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                if self.phase == .holding {
                    self.heldSeconds += 1
                    // Tell the nurse once, the second she reaches her goal.
                    if self.heldSeconds == Self.goalMinutes * 60 { self.send(event: "goal reached") }
                }
            }
        }
    }

    /// She pressed pause. Holding time stops, the watch shows Wait for Nurse,
    /// and the nurse's iPhone gets an alert. The nurse resumes or stops holding from the iPhone.
    func pauseHolding() {
        guard phase == .holding else { return }
        phase = .waitingForNurse
        send(event: "mother asked for nurse")
        send(event: "holding paused")
    }

    fileprivate func resumeHolding() {
        guard phase == .waitingForNurse else { return }
        phase = .holding
        send(event: "holding resumed")
    }

    // MARK: Movement

    private func startMotion() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 0.1
        let threshold = movementThreshold
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            let a = data.userAcceleration
            let moved = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot() > threshold
            let g = data.gravity
            // The handler runs on the main queue, so it is safe to touch main-actor data here.
            MainActor.assumeIsolated {
                guard let self else { return }
                if moved { self.movementCount += 1 }
                self.checkForWristTurn(gravity: (g.x, g.y, g.z), at: Date())
            }
        }
    }

    // MARK: Wrist turn

    /// Recent gravity directions, used to spot a deliberate wrist turn.
    private var gravityHistory: [(time: Date, x: Double, y: Double, z: Double)] = []
    /// A turn counts when the watch rotates more than this many degrees...
    private let wristTurnDegrees = 60.0
    /// ...within this many seconds.
    private let wristTurnSeconds: TimeInterval = 1.5

    /// While an alert is waiting, a deliberate wrist turn is how the mother answers it.
    /// Her hands are holding the baby, so the watch never asks her to tap a button.
    private func checkForWristTurn(gravity g: (Double, Double, Double), at now: Date) {
        gravityHistory.append((now, g.0, g.1, g.2))
        gravityHistory.removeAll { now.timeIntervalSince($0.time) > wristTurnSeconds }
        guard isAlerting, let oldest = gravityHistory.first else { return }
        let dot = oldest.x * g.0 + oldest.y * g.1 + oldest.z * g.2
        let lengths = (oldest.x * oldest.x + oldest.y * oldest.y + oldest.z * oldest.z).squareRoot()
            * (g.0 * g.0 + g.1 * g.1 + g.2 * g.2).squareRoot()
        guard lengths > 0 else { return }
        let degrees = acos(max(-1, min(1, dot / lengths))) * 180 / .pi
        if degrees >= wristTurnDegrees {
            gravityHistory.removeAll()
            motherResponded()
        }
    }

    // MARK: Rows

    private func startSliceTimer() {
        let interval = sliceSeconds
        sliceTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled, let self else { return }
                self.sendSlice()
            }
        }
    }

    private func sendSlice() {
        let now = Date()
        var row: [String: Any] = [
            "t": now.timeIntervalSince1970,
            "move": movementCount
        ]
        if let heartRate { row["hr"] = heartRate }
        if let lastSampleDate { row["age"] = now.timeIntervalSince(lastSampleDate) }
        movementCount = 0
        send(row)
    }

    private func send(event: String) {
        send(["t": Date().timeIntervalSince1970, "event": event])
    }

    /// Sends live when the iPhone is reachable. Otherwise queues the row so none are lost.
    private func send(_ row: [String: Any]) {
        let wc = WCSession.default
        guard wc.activationState == .activated else { return }
        if wc.isReachable {
            wc.sendMessage(row, replyHandler: nil) { _ in
                wc.transferUserInfo(row.merging(["queued": true]) { $1 })
            }
        } else {
            wc.transferUserInfo(row.merging(["queued": true]) { $1 })
        }
    }

    // MARK: Haptics

    /// One alert: firm taps that repeat until the mother turns her wrist, or the iPhone stops them.
    /// Vibration only, never sound. If she doesn't respond, the iPhone alerts the nurse;
    /// the watch keeps tapping.
    func startAlert() {
        let device = WKInterfaceDevice.current()
        isAlerting = true
        guard alertTask == nil else { return }
        send(event: "alert started")
        alertTask = Task { [weak self] in
            while !Task.isCancelled {
                for _ in 0..<3 {
                    guard !Task.isCancelled else { return }
                    device.play(.notification)
                    try? await Task.sleep(for: .milliseconds(700))
                }
                try? await Task.sleep(for: .seconds(2))
                guard self != nil else { return }
            }
        }
    }

    /// The mother turned her wrist. Stops any vibration and tells the iPhone.
    func motherResponded() {
        guard isAlerting else { return }
        stopAlert()
        send(event: "mother responded")
    }

    /// Stops the vibration and clears the alert.
    private func stopAlert() {
        alertTask?.cancel()
        alertTask = nil
        isAlerting = false
    }

    /// The nurse stopped the vibration from the iPhone, so she is on her way.
    /// Holding time pauses and the watch shows Wait for Nurse until she resumes it.
    fileprivate func nurseStoppedAlert() {
        guard isAlerting else { return }
        stopAlert()
        send(event: "vibration stopped from iPhone")
        if phase == .holding {
            phase = .waitingForNurse
            send(event: "holding paused")
        }
    }
}

// MARK: - HealthKit delegates

extension WorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {}

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in
            self.statusMessage = "Session error: \(message)"
            self.send(event: "session error")
        }
    }

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let type = HKQuantityType(.heartRate)
        guard collectedTypes.contains(type),
              let stats = workoutBuilder.statistics(for: type),
              let quantity = stats.mostRecentQuantity() else { return }
        let bpm = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        let sampleDate = stats.mostRecentQuantityDateInterval()?.end ?? Date()
        Task { @MainActor in
            self.heartRate = bpm
            self.lastSampleDate = sampleDate
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

// MARK: - iPhone link

extension WorkoutManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {}

    /// The iPhone sends names both as a message and as application context,
    /// so the watch gets them even if its app was closed when the nurse tapped Send.
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let names = Self.names(from: applicationContext) else { return }
        Task { @MainActor in self.apply(names) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let names = Self.names(from: message) {
            Task { @MainActor in self.apply(names) }
            return
        }
        if message["start"] as? Bool == true {
            Task { @MainActor in await self.start() }
            return
        }
        // Test only: jump to 10 seconds before the goal, so goal complete can be checked
        // without holding for 2 hours. The goal-reached alert still fires on its own.
        if message["jumpToGoal"] as? Bool == true {
            Task { @MainActor in
                if self.phase == .holding { self.heldSeconds = max(self.heldSeconds, Self.goalMinutes * 60 - 10) }
            }
            return
        }
        if message["stop"] as? Bool == true {
            Task { @MainActor in await self.end() }
            return
        }
        if message["resume"] as? Bool == true {
            Task { @MainActor in self.resumeHolding() }
            return
        }
        if message["stopHaptic"] as? Bool == true {
            Task { @MainActor in self.nurseStoppedAlert() }
            return
        }
        guard message["alert"] as? Bool == true else { return }
        Task { @MainActor in self.startAlert() }
    }
}

// MARK: - Names from the iPhone

extension WorkoutManager {
    nonisolated static func names(from message: [String: Any]) -> (mother: String, baby: String)? {
        guard let mother = message["motherName"] as? String,
              let baby = message["babyName"] as? String else { return nil }
        return (mother, baby)
    }

    func apply(_ names: (mother: String, baby: String)) {
        let mother = names.mother.trimmingCharacters(in: .whitespacesAndNewlines)
        let baby = names.baby.trimmingCharacters(in: .whitespacesAndNewlines)
        if !mother.isEmpty { motherName = mother }
        if !baby.isEmpty { babyName = baby }
        send(event: "names received")
    }
}
