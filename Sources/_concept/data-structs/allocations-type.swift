import Foundation

public struct SessionAllocation: Sendable, Codable, Hashable {
    public var minutes: MinuteRange

    public init(minutes: MinuteRange) {
        self.minutes = minutes
    }

    public init(sessions: SessionRange) {
        self.minutes = sessions.minute_range()
    }
}

public struct MinuteRange: Sendable, Codable, Hashable {
    public var low: Int
    public var medium: Int?
    public var high: Int

    public init(low: Int, medium: Int? = nil, high: Int? = nil) {
        let lo = max(0, low)
        let hi = max(0, high ?? low)

        self.low = lo
        self.high = hi

        if let m = medium {
            self.medium = max(lo, min(hi, m))
        } else {
            self.medium = nil
        }
    }

    /// Precise sessions (Double) for UI display.
    public func session_range(session_duration: Int = 60) -> SessionRange {
        let d = Double(max(session_duration, 1))
        return .init(
            low: Double(self.low) / d,
            medium: self.medium.map { Double($0) / d },
            high: Double(self.high) / d
        )
    }

    /// Medium value used when medium is nil (keeps downstream code simple).
    public func effectiveMedium() -> Int {
        if let medium { return medium }
        return (low + high) / 2
    }
}

public struct SessionRange: Sendable, Codable, Hashable {
    public var low: Double
    public var medium: Double?
    public var high: Double

    public init(low: Double, medium: Double? = nil, high: Double? = nil) {
        self.low = low
        self.medium = medium
        self.high = high ?? low
    }

    public func minute_range(session_duration: Int = 60) -> MinuteRange {
        let d = Double(max(session_duration, 1))
        return .init(
            low: Int((self.low * d).rounded(.toNearestOrAwayFromZero)),
            medium: self.medium.map { Int(($0 * d).rounded(.toNearestOrAwayFromZero)) },
            high: Int((self.high * d).rounded(.toNearestOrAwayFromZero))
        )
    }

    /// Integer view of the session range for tallying (nearest).
    public var rounded: Rounded {
        Rounded(
            low: Int(self.low.rounded(.toNearestOrAwayFromZero)),
            medium: self.medium.map { Int($0.rounded(.toNearestOrAwayFromZero)) },
            high: Int(self.high.rounded(.toNearestOrAwayFromZero))
        )
    }

    public var floored: Rounded {
        Rounded(
            low: Int(self.low.rounded(.down)),
            medium: self.medium.map { Int($0.rounded(.down)) },
            high: Int(self.high.rounded(.down))
        )
    }

    public var ceiled: Rounded {
        Rounded(
            low: Int(self.low.rounded(.up)),
            medium: self.medium.map { Int($0.rounded(.up)) },
            high: Int(self.high.rounded(.up))
        )
    }

    /// Medium value used when medium is nil (keeps downstream code simple).
    public func effectiveMedium() -> Double {
        if let medium { return medium }
        return (low + high) / 2.0
    }

    public struct Rounded: Sendable, Codable, Hashable {
        public var low: Int
        public var medium: Int?
        public var high: Int

        public init(low: Int, medium: Int?, high: Int) {
            self.low = low
            self.medium = medium
            self.high = high
        }

        public func effectiveMedium() -> Int {
            if let medium { return medium }
            return (low + high) / 2
        }
    }
}

public struct AllocationSummary: Sendable, Hashable {
    public var minutesText: String
    public var sessionsText: String?

    public init(minutesText: String, sessionsText: String?) {
        self.minutesText = minutesText
        self.sessionsText = sessionsText
    }
}

public extension SessionAllocation {
    /// UI summary (minutes always, sessions with up to 2 decimals).
    /// Sessions shown are low–high; medium is intentionally not shown here.
    func summary(sessionDuration: Int = 60) -> AllocationSummary {
        let lo = minutes.low
        let hi = minutes.high

        let minutesText: String = {
            if lo == hi { return "\(lo) min" }
            return "\(lo)–\(hi) min"
        }()

        let sessionsText: String? = {
            if lo == 0 && hi == 0 { return nil }

            let s = minutes.session_range(session_duration: sessionDuration)

            if nearlyEqual(s.low, s.high) {
                return "\(formatSessions(s.low)) sess"
            }

            return "\(formatSessions(s.low))–\(formatSessions(s.high)) sess"
        }()

        return AllocationSummary(minutesText: minutesText, sessionsText: sessionsText)
    }
}

public func formatSessions(_ value: Double) -> String {
    // Up to 2 decimals, but trim trailing zeros and the dot if needed.
    let raw = String(format: "%.2f", value)

    var s = raw
    while s.contains(".") && (s.hasSuffix("0") || s.hasSuffix(".")) {
        if s.hasSuffix("0") {
            s.removeLast()
            continue
        }
        if s.hasSuffix(".") {
            s.removeLast()
            break
        }
    }
    return s
}

public func nearlyEqual(_ a: Double, _ b: Double, epsilon: Double = 0.0000001) -> Bool {
    abs(a - b) <= epsilon
}
