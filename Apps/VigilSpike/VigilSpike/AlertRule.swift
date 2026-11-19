import Foundation

/// Settings from specs/alert-rule-v0.1.md, tuned after the November 19 sit (v0.2).
/// Every number here is still a starting guess to tune.
struct AlertRuleSettings {
    /// D: how far the 2-minute median heart rate must fall below baseline, in bpm.
    /// Raised from 4 after an awake, still sit drifted 4 to 6 bpm below the first baseline.
    var drop: Double = 6
    /// M: how many 5-second slices with movement are allowed in the 2-minute window.
    var maxMovingSlices = 3
    /// A slice counts as moving when the watch saw at least this many movement readings in it.
    var movingSliceMinReadings = 2
    /// The rule looks back over this many seconds.
    var windowSeconds: TimeInterval = 120
    /// T: how long the drowsy condition must hold before the watch alerts her, in seconds.
    var holdSeconds: TimeInterval = 180
    /// How long the watch vibrates without a wrist turn before the nurse is alerted.
    var dismissWindowSeconds: TimeInterval = 30
    /// Baseline uses heart rate from minute 2 to minute 6 of the session.
    var baselineStartSeconds: TimeInterval = 60
    var baselineEndSeconds: TimeInterval = 360
    /// A second baseline from minute 10 to minute 20, once she has settled, replaces the first.
    /// The first baseline still covers minutes 6 to 20, so there is no gap.
    var settledBaselineStartSeconds: TimeInterval = 600
    var settledBaselineEndSeconds: TimeInterval = 1200
    /// No fresh heart-rate reading for this long means the signal is lost.
    var signalLostSeconds: TimeInterval = 30
}

enum RuleState: String {
    case idle = "idle"
    case baseline = "baseline"
    case watching = "watching"
    case drowsy = "drowsy"
    /// The watch is vibrating and waiting for a wrist turn.
    case alerting = "alerting"
    /// She didn't turn her wrist in time, so the nurse is alerted. The watch keeps vibrating.
    case nurseAlerted = "nurse alerted"
    case signalLost = "signal lost"
}

/// What the rule decided for one 5-second slice.
struct RuleOutput {
    var state: RuleState
    var events: [String] = []
    /// True when the watch should start vibrating.
    var startWatchAlert = false
    /// True when the nurse should be alerted.
    var alertNurse = false
}

/// Runs the v0.1 alert rule over the rows the watch sends every 5 seconds.
struct AlertRule {
    var settings = AlertRuleSettings()

    private(set) var state: RuleState = .idle
    private(set) var baseline: Double?

    private var sessionStart: Date?
    private var baselineSamples: [Double] = []
    private var settledSamples: [Double] = []
    private var baselineSettled = false
    private var window: [(time: Date, heartRate: Double, moving: Bool)] = []
    private var drowsySince: Date?
    private var alertAt: Date?

    init(settings: AlertRuleSettings = AlertRuleSettings()) {
        self.settings = settings
    }

    mutating func startSession(at time: Date) {
        self = AlertRule(settings: settings)
        sessionStart = time
        state = .baseline
    }

    /// The mother tapped "I'm awake", or the nurse stopped the vibration.
    /// The drowsy clock starts over, so a new alert needs the full hold time again.
    mutating func alertAnswered() {
        guard state == .drowsy || state == .alerting || state == .nurseAlerted else { return }
        state = .watching
        drowsySince = nil
        alertAt = nil
    }

    mutating func endSession() {
        state = .idle
        sessionStart = nil
    }

    mutating func process(time: Date, heartRate: Double?, sampleAge: Double?, movement: Int) -> RuleOutput {
        guard let start = sessionStart else { return RuleOutput(state: state) }
        var out = RuleOutput(state: state)

        // A missing or old reading means the watch isn't measuring. Never treat that as awake.
        guard let heartRate, let sampleAge, sampleAge <= settings.signalLostSeconds else {
            if state != .signalLost {
                out.events.append("signal lost")
            }
            state = .signalLost
            out.state = state
            return out
        }
        if state == .signalLost {
            out.events.append("signal back")
            state = baseline == nil ? .baseline : .watching
        }

        // Baseline: the median heart rate from minute 2 to minute 6.
        let elapsed = time.timeIntervalSince(start)
        if baseline == nil {
            if elapsed >= settings.baselineStartSeconds && elapsed < settings.baselineEndSeconds {
                baselineSamples.append(heartRate)
            }
            if elapsed >= settings.baselineEndSeconds, let value = Self.median(baselineSamples) {
                baseline = value
                state = .watching
                out.events.append("baseline set \(Int(value.rounded())) bpm")
            }
            out.state = state
            return out
        }
        // Settled baseline: the median from minute 10 to minute 20 replaces the first one.
        if !baselineSettled {
            if elapsed >= settings.settledBaselineStartSeconds && elapsed < settings.settledBaselineEndSeconds {
                settledSamples.append(heartRate)
            }
            if elapsed >= settings.settledBaselineEndSeconds {
                baselineSettled = true
                if let value = Self.median(settledSamples) {
                    baseline = value
                    out.events.append("baseline updated \(Int(value.rounded())) bpm")
                }
            }
        }
        guard let baseline else { return out }

        // The 2-minute window.
        window.append((time, heartRate, movement >= settings.movingSliceMinReadings))
        window.removeAll { time.timeIntervalSince($0.time) > settings.windowSeconds }
        guard let oldest = window.first,
              time.timeIntervalSince(oldest.time) >= settings.windowSeconds - 5,
              let windowMedian = Self.median(window.map { $0.heartRate }) else {
            out.state = state
            return out
        }
        let movingSlices = window.filter { $0.moving }.count
        let isDrowsy = baseline - windowMedian >= settings.drop && movingSlices <= settings.maxMovingSlices

        if !isDrowsy {
            if state == .drowsy || state == .alerting || state == .nurseAlerted {
                out.events.append("drowsy condition cleared")
            }
            state = .watching
            drowsySince = nil
            alertAt = nil
            out.state = state
            return out
        }

        switch state {
        case .watching, .baseline, .signalLost, .idle:
            state = .drowsy
            drowsySince = time
            out.events.append("drowsy condition started")
        case .drowsy:
            if let since = drowsySince, time.timeIntervalSince(since) >= settings.holdSeconds {
                state = .alerting
                alertAt = time
                out.events.append("watch alert fired")
                out.startWatchAlert = true
            }
        case .alerting:
            if let at = alertAt, time.timeIntervalSince(at) >= settings.dismissWindowSeconds {
                state = .nurseAlerted
                out.events.append("nurse alerted: no wrist turn in 30 s")
                out.alertNurse = true
            }
        case .nurseAlerted:
            break
        }
        out.state = state
        return out
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }
}
