import Foundation
import WatchConnectivity
import UserNotifications
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

/// An alert for the nurse. It stays on screen until she acts.
struct NurseAlert: Identifiable {
    let id = UUID()
    let level: AlertLevel
    let title: String
    let message: String
    let raisedAt: Date
    /// What the alert asks the nurse to do.
    var kind: Kind = .vibration
    enum Kind { case vibration, paused, goalReached, signalLost }
}

/// The nurse app's store. It receives rows from the paired watch, runs the alert rule,
/// tracks the holding session, alerts the nurse, and writes every row to a CSV file.
/// Vigil follows one mother at a time: her watch is paired with this phone.
@Observable
final class SpikeStore: NSObject {
    var rows: [LogRow] = []
    var watchReachable = false
    private(set) var fileURL: URL
    private(set) var rule = AlertRule()

    /// Mothers, sessions and alerts. Saved to this phone on every change.
    var data: NurseData { didSet { saveData() } }

    /// When off, Vigil only records: the watch does not vibrate and the nurse gets no
    /// drowsiness alerts. Pause and goal alerts still reach her. Off by default for the first pilot sits.
    var alertsOn = UserDefaults.standard.bool(forKey: "alertsOn") {
        didSet { UserDefaults.standard.set(alertsOn, forKey: "alertsOn") }
    }

    /// The alert waiting for the nurse, if any.
    var nurseAlert: NurseAlert?
    /// True while the nurse fills in What you found.
    var showFound = false
    /// When the Check now she is answering was raised.
    var foundAlertAt: Date?

    /// The tab showing now, and the screens opened on the Patients tab.
    /// Saving an ended session clears both, so the nurse lands on her list of mothers.
    var selectedTab = 0
    var patientsPath: [UUID] = []
    /// Shown on screen when a message did not reach the watch.
    var watchProblem: String?

    var latestReading: LogRow? { rows.last { $0.heartRate != nil } }
    var latestMovement: LogRow? { rows.last { $0.movement != nil } }

    private(set) var sessionActive = false
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

    private static let dataURL = URL.documentsDirectory.appending(path: "nurse-data.json")

    override init() {
        fileURL = Self.makeFileURL()
        data = Self.loadData()
        super.init()
        Self.removeEmptyLogs()
        startFile()
        startWatchdog()
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: Saved data

    private static func loadData() -> NurseData {
        guard let raw = try? Data(contentsOf: dataURL),
              let saved = try? JSONDecoder().decode(NurseData.self, from: raw) else { return NurseData() }
        return saved
    }

    /// The app writes while the phone is locked during a session,
    /// so the file stays readable after the first unlock.
    private func saveData() {
        guard let raw = try? JSONEncoder().encode(data) else { return }
        try? raw.write(to: Self.dataURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func mother(_ id: UUID?) -> Mother? {
        guard let id else { return nil }
        return data.mothers.first { $0.id == id }
    }

    var liveMother: Mother? { mother(data.live?.motherID) }

    func addMother(name: String, baby: String, code: String, bed: String) {
        let trim = { (s: String) in s.trimmingCharacters(in: .whitespaces) }
        data.mothers.append(Mother(name: trim(name), babyName: trim(baby), code: trim(code), bed: trim(bed)))
    }

    /// The first name of the mother holding now, for alert wording.
    private var who: String { liveMother?.name ?? "the mother" }

    /// A mother who is holding now cannot be removed.
    func removeMother(_ mother: Mother) {
        guard data.live?.motherID != mother.id else { return }
        data.mothers.removeAll { $0.id == mother.id }
        data.sessions.removeAll { $0.motherID == mother.id }
        if data.watchMotherID == mother.id { data.watchMotherID = nil }
    }

    func sessions(for mother: Mother) -> [SessionRecord] {
        data.sessions.filter { $0.motherID == mother.id }
    }

    func status(for mother: Mother) -> VigilStatus {
        guard data.live?.motherID == mother.id else { return .notHolding }
        if let alert = nurseAlert { return alert.level == .checkNow ? .checkNow : .checkSoon }
        return .holding
    }

    /// What is happening now, for the Patients list.
    func detail(for mother: Mother, now: Date) -> String {
        if let live = data.live, live.motherID == mother.id {
            let held = HeldTime.text(live.heldSeconds(at: now))
            return live.isPaused ? "Paused at \(held)" : "Holding \(held)"
        }
        if let last = sessions(for: mother).first {
            let day = Calendar.current.isDateInToday(last.start)
                ? "today" : last.start.formatted(.dateTime.month(.abbreviated).day())
            return "Held \(day), \(HeldTime.clock(last.start))"
        }
        return "Not held yet"
    }

    // MARK: Logs

    /// Deletes logs that hold only the header row, left by app launches with no session.
    private static func removeEmptyLogs() {
        let fm = FileManager.default
        let files = (try? fm.contentsOfDirectory(at: URL.documentsDirectory,
                                                 includingPropertiesForKeys: [.fileSizeKey])) ?? []
        for url in files where url.pathExtension == "csv" {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let headerOnly = url.lastPathComponent.hasPrefix("watch-log-") ? 60 : header.utf8.count
            if size <= headerOnly { try? fm.removeItem(at: url) }
        }
    }

    /// Every log with data on this phone, newest first. Rebuilding the app keeps them.
    var savedLogs: [URL] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: URL.documentsDirectory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { url in
            let name = url.lastPathComponent
            guard url.pathExtension == "csv",
                  name.hasPrefix("vigil-log-") || name.hasPrefix("watch-log-") else { return false }
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return size > (name.hasPrefix("watch-log-") ? 60 : Self.header.utf8.count)
        }
        .sorted { $0.lastPathComponent.dropFirst(10) > $1.lastPathComponent.dropFirst(10) }
    }

    /// Starts a fresh CSV file. Use it between test sits.
    func newLog() {
        rows.removeAll()
        fileURL = Self.makeFileURL()
        startFile()
    }

    // MARK: Messages to the watch

    /// Names for the watch. It shows the mother's first name on Welcome and the baby's on Goal Complete.
    var motherName = UserDefaults.standard.string(forKey: "motherName") ?? "Malika" {
        didSet { UserDefaults.standard.set(motherName, forKey: "motherName") }
    }
    var babyName = UserDefaults.standard.string(forKey: "babyName") ?? "Jeffrey" {
        didSet { UserDefaults.standard.set(babyName, forKey: "babyName") }
    }

    /// Puts this mother's and baby's first names on the watch.
    /// Application context reaches the watch even if its app is closed.
    func sendNames(for mother: Mother) {
        data.watchMotherID = mother.id
        motherName = mother.firstName
        babyName = mother.babyName
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

    /// The nurse starts holding. Vigil must be open on the watch.
    func startHolding(for mother: Mother) {
        sendNames(for: mother)
        sendToWatch(["start": true], label: "start")
    }

    /// The nurse pauses holding time from the phone. The watch shows Wait for Nurse.
    func pauseHolding() { sendToWatch(["pause": true], label: "pause") }

    /// The nurse resumes holding time.
    func resumeHolding() {
        if nurseAlert?.kind == .paused { resolveAlert() }
        sendToWatch(["resume": true], label: "resume")
    }

    /// The nurse ends the session. The watch goes back to Welcome and the phone asks why it ended.
    func stopHolding() {
        if nurseAlert != nil, nurseAlert?.level != .checkNow { resolveAlert() }
        sendToWatch(["stop": true], label: "stop")
    }

    /// Starts the watch vibrating until she turns her wrist. Tester tool.
    func sendWatchAlert() { sendToWatch(["alert": true], label: "alert") }

    /// Stops the watch vibrating. The watch pauses holding time until the nurse resumes it.
    func stopWatchVibration() { sendToWatch(["stopHaptic": true], label: "stop vibration") }

    /// Test only: moves held time to 10 seconds before the goal.
    func jumpToGoal() { sendToWatch(["jumpToGoal": true], label: "jump to goal") }

    /// Asks the watch to send every log it saved. They appear under Saved logs.
    func getWatchLogs() { sendToWatch(["sendLogs": true], label: "watch logs") }

    private func sendToWatch(_ message: [String: Any], label: String) {
        guard WCSession.default.isReachable else {
            watchProblem = "The watch did not get that. Check that Vigil is open on the watch, then try again."
            record(event: "\(label) not sent: watch not reachable")
            return
        }
        watchProblem = nil
        WCSession.default.sendMessage(message, replyHandler: nil) { [weak self] _ in
            Task { @MainActor in
                self?.watchProblem = "The watch did not get that. Check that Vigil is open on the watch, then try again."
                self?.record(event: "\(label) send failed")
            }
        }
        record(event: "\(label) requested")
    }

    // MARK: Nurse actions on alerts

    /// The nurse is on her way to a Check now. The watch stops vibrating and holding time pauses
    /// while she writes down what she found.
    func nurseGoing() {
        foundAlertAt = nurseAlert?.raisedAt
        stopWatchVibration()
        pauseHolding()
        resolveAlert()
        // Wait for Check now to close before What you found opens over it.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            self.showFound = true
        }
    }

    /// Saves what the nurse found. Moving the baby to the isolette ends the session;
    /// otherwise holding resumes.
    func saveFinding(found: Int, did: [Int]) {
        data.live?.findings.append(Finding(at: Date(), found: found, did: did))
        showFound = false
        if did.contains(NurseChoices.isolette) { stopHolding() } else { resumeHolding() }
    }

    /// Saves the ended session with the reason the nurse picked.
    func saveEnded(why: Int) {
        guard let e = data.ended else { return }
        let end = e.end ?? Date()
        data.sessions.insert(SessionRecord(
            motherID: e.motherID, start: e.start, end: end, heldSeconds: e.heldSeconds(at: end),
            watchAlerts: e.watchAlerts, answered: e.answered, nurseAlerts: e.nurseAlerts,
            findings: e.findings, whyEnded: why), at: 0)
        data.ended = nil
        selectedTab = 0
        patientsPath = []
    }

    func dismissAlert() { resolveAlert() }

    private func raise(_ alert: NurseAlert) {
        let urgent = alert.level == .checkNow
        data.alerts.insert(AlertRecord(id: alert.id, motherID: data.live?.motherID, isCheckNow: urgent,
                                       title: alert.title, raisedAt: alert.raisedAt), at: 0)
        if data.alerts.count > 300 { data.alerts.removeLast(data.alerts.count - 300) }
        if urgent { data.live?.nurseAlerts += 1 }
        // A Check now is never replaced by a quieter alert.
        if nurseAlert?.level != .checkNow || urgent {
            if nurseAlert != nil { resolveAlert() }
            nurseAlert = alert
        }
        let content = UNMutableNotificationContent()
        content.title = urgent ? "Check now: \(alert.title)" : alert.title
        content.body = alert.message
        content.sound = .default
        content.interruptionLevel = urgent ? .timeSensitive : .active
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: alert.id.uuidString, content: content, trigger: nil),
            withCompletionHandler: nil)
    }

    private func resolveAlert() {
        guard let alert = nurseAlert else { return }
        if let i = data.alerts.firstIndex(where: { $0.id == alert.id }) { data.alerts[i].resolvedAt = Date() }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [alert.id.uuidString])
        nurseAlert = nil
    }

    // MARK: Incoming rows

    /// Keeps the live session in step with what the watch reports.
    private func trackSession(_ row: LogRow) {
        switch row.event {
        case "session started":
            guard let id = data.watchMotherID ?? data.mothers.first?.id else { return }
            data.live = LiveSession(motherID: id, start: row.time)
        case "holding paused":
            if data.live?.pausedAt == nil { data.live?.pausedAt = row.time }
        case "holding resumed":
            if let pausedAt = data.live?.pausedAt {
                data.live?.pausedTotal += max(0, row.time.timeIntervalSince(pausedAt))
                data.live?.pausedAt = nil
            }
        case "alert started":
            data.live?.watchAlerts += 1
        case "mother responded":
            data.live?.answered += 1
        case "goal reached":
            data.live?.goalReached = true
        case "session ended":
            guard var live = data.live else { return }
            live.end = row.time
            data.ended = live
            data.live = nil
            showFound = false
            resolveAlert()
        default:
            break
        }
    }

    fileprivate func handle(_ incoming: LogRow) {
        var row = incoming
        trackSession(row)

        if row.event == "session started" {
            // The log carries her study code, never her name.
            if let code = liveMother?.code, !code.isEmpty { record(event: "study code \(code)") }
            rule.startSession(at: row.time)
            sessionActive = true
            lastProcessedTime = nil
            lastDataReceivedAt = row.receivedAt
            reportedNoData = false
        } else if row.event == "session ended" {
            rule.endSession()
            sessionActive = false
        } else if row.event == "mother asked for nurse" {
            raise(NurseAlert(
                level: .checkSoon,
                title: "Pause pressed on \(who)'s watch",
                message: "Holding time is paused. Resume or stop holding after you talk with her.",
                raisedAt: row.receivedAt,
                kind: .paused))
        } else if row.event == "goal reached" {
            raise(NurseAlert(
                level: .checkSoon,
                title: "\(who) reached her 2 hour goal",
                message: "Go relieve her when you can.",
                raisedAt: row.receivedAt,
                kind: .goalReached))
        } else if row.event == "mother responded" || row.event == "vibration stopped from iPhone" {
            rule.alertAnswered()
            // She turned her wrist after the nurse was alerted, so the Check now has been answered.
            if row.event == "mother responded", nurseAlert?.level == .checkNow { resolveAlert() }
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
        if data.live?.isPaused == true {
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
        // Recording only: the rule still runs and logs, but nobody is alerted.
        guard alertsOn else { return }
        if out.startWatchAlert {
            sendWatchAlert()
        }
        if out.alertNurse {
            raise(NurseAlert(
                level: .checkNow,
                title: "No response to the watch alert",
                message: "The watch vibrated for 30 seconds and \(who) has not turned her wrist.",
                raisedAt: Date()))
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
        guard alertsOn else { return }
        raise(NurseAlert(
            level: .checkSoon,
            title: "No signal from \(who)'s watch",
            message: "The phone has not heard from the watch for 30 seconds. Check that it is on her wrist and Vigil is open.",
            raisedAt: Date(),
            kind: .signalLost))
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

extension SpikeStore: UNUserNotificationCenterDelegate {
    /// Shows alerts as banners with sound even while the app is open.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
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

    /// A log file from the watch. The system deletes the incoming file when this
    /// returns, so it is copied into Documents first.
    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let name = file.fileURL.lastPathComponent
        let dest = URL.documentsDirectory.appending(path: name)
        try? FileManager.default.removeItem(at: dest)
        let ok = (try? FileManager.default.copyItem(at: file.fileURL, to: dest)) != nil
        Task { @MainActor in self.record(event: ok ? "watch log received: \(name)" : "watch log not saved: \(name)") }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let row = Self.parse(userInfo, receivedAt: Date()) else { return }
        Task { @MainActor in self.handle(row) }
    }
}
