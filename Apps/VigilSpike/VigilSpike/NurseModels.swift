import Foundation

/// One mother in the pilot. The phone and her watch show first names only.
/// The study code, such as "V-01", is what the research logs carry.
struct Mother: Identifiable, Codable, Hashable {
    var id = UUID()
    /// Her first name.
    var name: String
    /// Her baby's first name, for the watch's goal screen.
    var babyName: String
    /// Her study code.
    var code: String = ""
    var bed: String

    init(name: String, babyName: String, code: String, bed: String) {
        self.name = name
        self.babyName = babyName
        self.code = code
        self.bed = bed
    }

    /// Mothers saved before study codes existed still load, with an empty code.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        babyName = try c.decodeIfPresent(String.self, forKey: .babyName) ?? ""
        code = try c.decodeIfPresent(String.self, forKey: .code) ?? ""
        bed = try c.decodeIfPresent(String.self, forKey: .bed) ?? ""
    }

    var firstName: String { name.split(separator: " ").first.map(String.init) ?? name }

    var initials: String { String(name.prefix(1)).uppercased() }

    /// "Bed 4", or empty when no bed was entered.
    var bedLabel: String {
        let trimmed = bed.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }
        return trimmed.lowercased().hasPrefix("bed") ? trimmed : "Bed \(trimmed)"
    }

    /// "V-01 · Bed 4"
    var bedLine: String {
        [code, bedLabel].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// "Malika · V-01 · Bed 4"
    var nameLine: String {
        [name, code, bedLabel].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

/// What the nurse found when she answered a Check now alert.
struct Finding: Codable, Hashable {
    var at: Date
    var found: Int
    var did: [Int]
}

/// The holding session running now. Its times come from the watch.
struct LiveSession: Codable {
    var motherID: UUID
    var start: Date
    var end: Date?
    var pausedAt: Date?
    var pausedTotal: TimeInterval = 0
    var watchAlerts = 0
    var answered = 0
    var nurseAlerts = 0
    var findings: [Finding] = []
    var goalReached = false

    var isPaused: Bool { pausedAt != nil && end == nil }

    /// Time she has held the baby, leaving out paused time.
    func heldSeconds(at now: Date = Date()) -> Int {
        let stop = end ?? now
        var paused = pausedTotal
        if let pausedAt { paused += max(0, stop.timeIntervalSince(pausedAt)) }
        return max(0, Int(stop.timeIntervalSince(start) - paused))
    }
}

/// A finished session, saved when the nurse picks why it ended.
struct SessionRecord: Identifiable, Codable {
    var id = UUID()
    var motherID: UUID
    var start: Date
    var end: Date
    var heldSeconds: Int
    var watchAlerts: Int
    var answered: Int
    var nurseAlerts: Int
    var findings: [Finding]
    var whyEnded: Int
}

/// Every alert the nurse got, for the Alerts tab.
struct AlertRecord: Identifiable, Codable {
    var id: UUID
    var motherID: UUID?
    var isCheckNow: Bool
    var title: String
    var raisedAt: Date
    var resolvedAt: Date?
}

/// The answers the nurse picks from. Saved records store the index.
enum NurseChoices {
    static let found = ["She was awake", "Drowsy, woke when I spoke",
                        "Asleep, woke when I touched her", "Hard to wake"]
    static let did = ["Talked with her, she kept holding", "Moved the baby to the isolette",
                      "Called the charge nurse"]
    static let keptHolding = 0
    /// Moving the baby to the isolette ends the session.
    static let isolette = 1
    static let ended = ["She reached her goal", "She chose to stop",
                        "The baby needed care", "Safety concern"]
}

/// Everything the nurse app keeps between launches. It stays on this phone.
struct NurseData: Codable {
    var mothers: [Mother] = []
    var sessions: [SessionRecord] = []
    var alerts: [AlertRecord] = []
    /// The mother whose names are on the watch now.
    var watchMotherID: UUID?
    var live: LiveSession?
    /// A session that ended and is waiting for the nurse to say why.
    var ended: LiveSession?
}

enum HeldTime {
    static let goalSeconds = 120 * 60

    /// "42 min", "2 hr" or "1 hr 5 min"
    static func text(_ seconds: Int) -> String {
        let m = seconds / 60
        if m < 60 { return "\(m) min" }
        return m % 60 == 0 ? "\(m / 60) hr" : "\(m / 60) hr \(m % 60) min"
    }

    static func clock(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }
}
