import Foundation

public enum ProgramTally {
    public enum EstimateBand: Sendable, Hashable {
        case low_high
        case low_medium
        case medium_high

        public var field_label_range_visual: String {
            switch self {
            case .low_medium:
                return "●-●-○"
            case .low_high:
                return "●-○-●"
            case .medium_high:
                return "○-●-●"
            }
        }

        public var dot_spread_count: Int {
            switch self {
            case .low_medium: return 1
            case .low_high: return 2
            case .medium_high: return 3
            }
        }

        public func dotString(filled: Int) -> String {
            let filledClamped = max(0, min(3, filled))
            return String(repeating: "●", count: filledClamped)
                + String(repeating: "○", count: 3 - filledClamped)
        }

        public var publicMarker: String {
            switch self {
            case .low_medium: return "S"
            case .medium_high: return "M"
            case .low_high: return "L"
            }
        }

        /// Friendly explanation for clients.
        public var publicDetails: String {
            switch self {
            case .low_medium: return "laag–medium"
            case .medium_high: return "medium–hoog"
            case .low_high: return "laag–hoog"
            }
        }

        /// More internal/technical label, if you ever want it.
        public var internalLabel: String {
            switch self {
            case .low_medium: return "Low–Medium"
            case .medium_high: return "Medium–High"
            case .low_high: return "Low–High"
            }
        }

        enum Anchor: Sendable, Hashable {
            case low
            case medium
            case high

            public var title: String {
                switch self {
                case .low: return "Low"
                case .medium: return "Medium"
                case .high: return "High"
                }
            }
        }

        /// Which of Low/Medium/High is NOT part of this band.
        var excludedAnchor: Anchor {
            switch self {
            case .low_medium:
                return .high
            case .low_high:
                return .medium
            case .medium_high:
                return .low
            }
        }
    }

    private static func shouldCount(
        _ entry: ModuleEntry,
        placements: Set<ModuleComponentPlacement>
    ) -> Bool {
        guard entry.include else { return false }
        return placements.contains(entry.placement)
    }

    public static func sessions(
        program: Program,
        sessionDuration: Int = 60,
        band: EstimateBand = .low_high,
        placements: Set<ModuleComponentPlacement> = [.elementary]
    ) -> SessionRange {
        var low: Double = 0
        var medium: Double = 0
        var high: Double = 0

        for pkg in program {
            for module in pkg.modules {
                for entry in module.entries where shouldCount(entry, placements: placements) {
                    guard let alloc = entry.component.allocation else { continue }

                    let r = alloc.minutes.session_range(session_duration: sessionDuration)
                    low += r.low
                    medium += r.medium ?? r.effectiveMedium()
                    high += r.high
                }
            }
        }

        let a: Double
        let b: Double

        switch band {
        case .low_high:
            a = low
            b = high
        case .low_medium:
            a = low
            b = medium
        case .medium_high:
            a = medium
            b = high
        }

        // let roundedA = Int(a.rounded(.toNearestOrAwayFromZero))
        // let roundedB = Int(b.rounded(.toNearestOrAwayFromZero))

        // return .init(
        //     low: Double(roundedA),
        //     high: Double(roundedB)
        // )
        return .init(low: a, high: b)
    }

    // public static func minutes(
    //     program: Program,
    //     placements: Set<ModuleComponentPlacement> = [.elementary]
    // ) -> MinuteRange {
    //     var low: Int = 0
    //     var high: Int = 0

    //     for pkg in program {
    //         for module in pkg.modules {
    //             for entry in module.entries where shouldCount(entry, placements: placements) {
    //                 guard let alloc = entry.component.allocation else { continue }
    //                 low += alloc.minutes.low
    //                 high += alloc.minutes.high
    //             }
    //         }
    //     }

    //     return .init(low: low, high: high)
    // }

    public static func minutes(
        program: Program,
        placements: Set<ModuleComponentPlacement> = [.elementary]
    ) -> MinuteRange {
        var low: Int = 0
        var medium: Int = 0
        var high: Int = 0

        for pkg in program {
            for module in pkg.modules {
                for entry in module.entries where shouldCount(entry, placements: placements) {
                    guard let alloc = entry.component.allocation else { continue }

                    low += alloc.minutes.low
                    medium += alloc.minutes.medium ?? alloc.minutes.effectiveMedium()
                    high += alloc.minutes.high
                }
            }
        }

        return .init(low: low, medium: medium, high: high)
    }
}
