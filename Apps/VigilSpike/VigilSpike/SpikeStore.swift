import Foundation
import WatchConnectivity
import Observation
import VigilDesignSystem

/// One row from the watch, or one event, as the iPhone logged it.
struct LogRow: Identifiable, Sendable {
    let id = UUID()
    let time: Date
    let receivedAt: Date
    let heartRate: Double?
    let sampleAge: Double?
    let movement: Int?
    let event: String
    let queued: Bool
    var ruleState: String = ""
}

/// An alert for the nurse, shown as an Alert Card at the top of the phone app until she acts.
struct NurseAlert: Identifiable {
    let id = UUID()
    let level: AlertLevel
    let title: String
    let message: String
    let raisedAt: Date
}

/// Receives rows from the watch, runs the alert rule, shows the latest values,
/// and writes every row to a CSV file.
@Observable
final class SpikeStore: NSObject {
    var rows: [LogRow] = []
    var watchReachable = false
    /// When on, the watch vibrates when the rule fires.
    /// Off by default so the first sits record how the body behaves without alerts.
    var vibrateOnAlert = false
    private(set) var fileURL: URL
    private(set) var rule = AlertRule()

    var latestReading: LogRow? { rows.last { $0.heartRate != nil } }

    private var sessionActive = false
    private var lastProcessedTime: Date?
    private var lastDataReceivedAt: Date?
    private var reportedNoData = false
    private var watchdog: Task<Void, Never>?

    private static let header = "time,received_at,delivery_delay_s,heart_rate_bpm,hr_sample_age_s,movement_count,rule_state,baseline_bpm,event,delivery\n"

    private static let timeFormat: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    override init() {
        fileURL = Self.makeFileURL()
        super.init()
        startFile()
        startWatchdog()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    /// Starts a fresh CSV file. Use it between test sits.
    func newLog() {
        rows.removeAll()
        fileURL = Self.makeFileURL()
        startFile()
    }

    /// Starts the watch vibrating until she turns her wrist.
    func sendWatchAlert() {
        guard WCSession.default.isReachable else {
            record(event: "alert not sent: watch not reachable")
            return
        }
        WCSession.default.sendMessage(["alert": true], replyHandler: nil) { [weak self] _ in
            Task { @MainActor in self?.record(event: "alert send failed") }
        }
        record(event: "alert requested")
    }

    /// Names for this tester. The watch shows the mother's name on Welcome and the baby's on Goal Complete.
    var motherName = UserDefaults.standard.string(forKey: "motherName") ?? "Malika" {
        didSet { UserDefaults.standard.set(motherName, forKey: "motherName") }
    }
    var babyName = UserDefaults.standard.string(forKey: "babyName") ?? "Jeffrey" {
        didSet { UserDefaults.standard.set(babyName, forKey: "babyName") }
    }

    /// Sends both names to the watch. Application context reaches the watch even if its app is closed.
    func sendNames() {
        let names: [String: Any] = ["motherName": motherName, "babyName": babyName]
        do {
            try WCSession.default.updateApplicationContext(names)
        } catch {
            record(event: "names not sent: \(error.localizedDescription)")
            return
        }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(names, replyHandler: nil, errorHandler: nil)
        }
        record(event: "names sent")
    }

    /// The alert waiting for the nurse, if any.
    var nurseAlert: NurseAlert?

    func dismissAlert() { nurseAlert = nil }

    /// True while holding is paused and the watch shows Wait for Nurse.
    var holdingPaused = false

    /// The nurse starts holding. The watch app must be open on the 2 Hour Goal screen.
    func startHolding() { sendToWatch(["start": true], label: "start") }

    /// The nurse arrived and resumes holding time.
    func resumeHolding() { sendToWatch(["resume": true], label: "resume") }

    private func sendToWatch(_ message: [String: Any], label: String) {
        guard WCSession.default.isReachable else {
            record(event: "\(label) not sent: watch not reachable")
            return
        }
        WCSession.default.sendMessage(message, replyHandler: nil) { [weak self] _ in
            Task { @MainActor in self?.record(event: "\(label) send failed") }
        }
        record(event: "\(label) requested")
    }

    /// The nurse stops the watch vibrating from the iPhone.
    func stopWatchVibration() {
        guard WCSession.default.isReachable else {
            record(event: "stop not sent: watch not reachable")
            return
        }
        WCSession.default.sendMessage(["stopHaptic": true], replyHandler: nil) { [weak self] _ in
            Task { @MainActor in self?.record(event: "stop send failed") }
        }
    }

    // MARK: Incoming rows

    fileprivate func handle(_ incoming: LogRow) {
        var row = incoming

        if row.event == "session started" {
            holdingPaused = false
            rule.startSession(at: row.time)
            sessionActive = true
            lastProcessedTime = nil
            lastDataReceivedAt = row.receivedAt
            reportedNoData = false
        } else if row.event == "session ended" {
            rule.endSession()
            sessionActive = false
            holdingPaused = false
        } else if row.event == "mother asked for nurse" {
            nurseAlert = NurseAlert(
                level: .checkSoon,
                title: "Pause pressed on \(motherName)'s watch",
                message: "Holding time is paused until you resume it.",
                raisedAt: row.receivedAt)
        } else if row.event == "holding paused" {
            holdingPaused = true
        } else if row.event == "holding resumed" {
            holdingPaused = false
        } else if row.event == "mother responded" || row.event == "vibration stopped from iPhone" {
            rule.alertAnswered()
            // She turned her wrist after the nurse was alerted, so the Check now alert has been answered.
            if row.event == "mother responded", nurseAlert?.level == .checkNow { nurseAlert = nil }
        }

        // Data rows go through the rule in time order. Rows that arrive late from the queue are logged but not re-run.
        guard row.event.isEmpty, sessionActive else {
            row.ruleState = rule.state.rawValue
            append(row)
            return
        }
        lastDataReceivedAt = row.receivedAt
        reportedNoData = false
        if let last = lastProcessedTime, row.time <= last {
            row.ruleState = "late"
            append(row)
            return
        }
        lastProcessedTime = row.time

        // While holding is paused the nurse is with her, so the rule doesn't alert.
        if holdingPaused {
            row.ruleState = "paused"
            append(row)
            return
        }

        let out = rule.process(time: row.time, heartRate: row.heartRate,
                               sampleAge: row.sampleAge, movement: row.movement ?? 0)
        row.ruleState = out.state.rawValue
        append(row)
        for event in out.events {
            record(event: event)
        }
        if out.startWatchAlert, vibrateOnAlert {
            sendWatchAlert()
        }
        if out.alertNurse {
            nurseAlert = NurseAlert(
                level: .checkNow,
                title: "No response to the watch alert",
                message: "The watch vibrated for 30 seconds and \(motherName) has not turned her wrist.",
                raisedAt: Date())
        }
    }

    /// If the watch stops sending rows altogether, the rule never runs. This catches that case.
    private func startWatchdog() {
        watchdog = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let self else { return }
                self.checkForSilence()
            }
        }
    }

    private func checkForSilence() {
        guard sessionActive, !reportedNoData, let last = lastDataReceivedAt,
              Date().timeIntervalSince(last) > rule.settings.signalLostSeconds else { return }
        reportedNoData = true
        record(event: "signal lost: no rows from watch for 30 s")
    }

    // MARK: File

    private static func makeFileURL() -> URL {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return URL.documentsDirectory.appending(path: "vigil-log-\(f.string(from: Date())).csv")
    }

    private func startFile() {
        try? Self.header.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func record(event: String) {
        let now = Date()
        var row = LogRow(time: now, receivedAt: now, heartRate: nil, sampleAge: nil,
                         movement: nil, event: event, queued: false)
        row.ruleState = rule.state.rawValue
        append(row)
    }

    private func append(_ row: LogRow) {
        rows.append(row)
        let fmt = Self.timeFormat
        let fields: [String] = [
            fmt.string(from: row.time),
            fmt.string(from: row.receivedAt),
            String(format: "%.1f", row.receivedAt.timeIntervalSince(row.time)),
            row.heartRate.map { String(format: "%.0f", $0) } ?? "",
            row.sampleAge.map { String(format: "%.1f", $0) } ?? "",
            row.movement.map(String.init) ?? "",
            row.ruleState,
            rule.baseline.map { String(format: "%.0f", $0) } ?? "",
            row.event,
            row.queued ? "queued" : "live"
        ]
        let line = fields.joined(separator: ",") + "\n"
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        }
    }

    /// Reads a watch message into a row. Runs off the main thread, so it only touches its inputs.
    fileprivate nonisolated static func parse(_ message: [String: Any], receivedAt: Date) -> LogRow? {
        guard let t = message["t"] as? Double else { return nil }
        return LogRow(
            time: Date(timeIntervalSince1970: t),
            receivedAt: receivedAt,
            heartRate: message["hr"] as? Double,
            sampleAge: message["age"] as? Double,
            movement: message["move"] as? Int,
            event: message["event"] as? String ?? "",
            queued: message["queued"] as? Bool ?? false
        )
    }
}

extension SpikeStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        let reachable = session.isReachable
        Task { @MainActor in self.watchReachable = reachable }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in self.watchReachable = reachable }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let row = Self.parse(message, receivedAt: Date()) else { return }
        Task { @MainActor in self.handle(row) }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let row = Self.parse(userInfo, receivedAt: Date()) else { return }
        Task { @MainActor in self.handle(row) }
    }
}
