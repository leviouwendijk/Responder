import Foundation

public enum ProgramTally {
    public enum EstimateBand: Sendable, Hashable {
        case low_high
        case low_medium
        case medium_high
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
                    medium += r.effectiveMedium()
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

        let roundedA = Int(a.rounded(.toNearestOrAwayFromZero))
        let roundedB = Int(b.rounded(.toNearestOrAwayFromZero))

        return .init(
            low: Double(roundedA),
            high: Double(roundedB)
        )
    }

    public static func minutes(
        program: Program,
        placements: Set<ModuleComponentPlacement> = [.elementary]
    ) -> MinuteRange {
        var low: Int = 0
        var high: Int = 0

        for pkg in program {
            for module in pkg.modules {
                for entry in module.entries where shouldCount(entry, placements: placements) {
                    guard let alloc = entry.component.allocation else { continue }
                    low += alloc.minutes.low
                    high += alloc.minutes.high
                }
            }
        }

        return .init(low: low, high: high)
    }
}
