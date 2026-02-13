import SwiftUI

@MainActor
public final class ProgramEditorViewModel: ObservableObject {
    @Published public var program: Program
    @Published public var selectedPackageID: Package.ID?

    // Swap UI state
    @Published public var swapTarget: SwapTarget?

    @Published public var estimateBand: ProgramTally.EstimateBand = .low_high
    @Published public var tallyPlacements: Set<ModuleComponentPlacement> = [.elementary]

    // ---------------------------------------------------------
    // PRICING
    // ---------------------------------------------------------
    @Published public var sessionRate: Double = 300
    @Published public var homeSessions: Int = 0
    @Published public var travelDistanceKm: Double = 0
    @Published public var travelRatePerKm: Double = 2.50

    private static let euroFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency

        // UI preference: 1,234.56 (dot decimal, comma grouping)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.currencyCode = "EUR"
        f.currencySymbol = "€"

        f.usesGroupingSeparator = true
        f.groupingSeparator = ","
        f.decimalSeparator = "."

        // Keep 2 decimals for money
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2

        return f
    }()

    private static func formatEUR(_ value: Double) -> String {
        euroFormatter.string(from: NSNumber(value: value)) ?? "€ \(String(format: "%.2f", value))"
    }

    public struct SwapTarget: Identifiable {
        public let id: UUID = UUID()
        public let packageID: Package.ID
        public let moduleID: UUID
        public let entryID: UUID
        public let current: ModuleComponent
    }

    public init(program: Program = []) {
        self.program = program
        self.selectedPackageID = program.first?.id
    }

    public var selectedPackageIndex: Int? {
        guard let id = selectedPackageID else { return nil }
        return program.firstIndex(where: { $0.id == id })
    }

    public func addTemplate(_ template: Package) {
        let instance = template.package()
        program.append(instance)
        selectedPackageID = instance.id
    }

    public func deletePackage(at offsets: IndexSet) {
        program.remove(atOffsets: offsets)
        if selectedPackageIndex == nil {
            selectedPackageID = program.first?.id
        }
    }

    public func movePackage(from: IndexSet, to: Int) {
        program.move(fromOffsets: from, toOffset: to)
    }

    public func beginSwap(packageID: Package.ID, moduleID: UUID, entryID: UUID, current: ModuleComponent) {
        swapTarget = .init(packageID: packageID, moduleID: moduleID, entryID: entryID, current: current)
    }

    public func commitSwap(newComponent: ModuleComponent) {
        guard let target = swapTarget else { return }

        guard let pIndex = program.firstIndex(where: { $0.id == target.packageID }) else { return }
        guard let mIndex = program[pIndex].modules.firstIndex(where: { $0.id == target.moduleID }) else { return }
        guard let eIndex = program[pIndex].modules[mIndex].entries.firstIndex(where: { $0.id == target.entryID }) else { return }

        program[pIndex].modules[mIndex].entries[eIndex].component = newComponent
        swapTarget = nil
    }

    // tallying
    public var sessionDuration: Int { 60 }

    public var totalSessions: SessionRange {
        ProgramTally.sessions(program: program, sessionDuration: sessionDuration)
    }

    public var totalMinutes: MinuteRange {
        ProgramTally.minutes(program: program)
    }

    public var totalSessionsLabel: String {
        let t = totalSessions
        if t.low == 0 && t.high == 0 { return "—" }
        if t.low == t.high { return "\(t.low)" }
        return "\(t.low)–\(t.high)"
    }

    // ---------------------------------------------------------
    // PRICING (derived)
    // ---------------------------------------------------------
    private var includedProgram: Program {
        program.filter { $0.include }
    }

    public var pricedSessionRangeRounded: SessionRange.Rounded {
        ProgramTally.sessions(
            program: includedProgram,
            sessionDuration: sessionDuration,
            band: estimateBand,
            placements: tallyPlacements
        ).rounded
    }

    /// Uses the "high" value of the currently selected estimate band.
    public var pricedSessionsHigh: Int {
        pricedSessionRangeRounded.high
    }

    public var estimatedSessionCost: Double {
        Double(pricedSessionsHigh) * max(0, sessionRate)
    }

    public var estimatedTravelCost: Double {
        let hs = Double(max(0, homeSessions))
        let km = max(0, travelDistanceKm)
        let rate = max(0, travelRatePerKm)
        return hs * km * rate
    }

    public var estimatedTotalCost: Double {
        estimatedSessionCost + estimatedTravelCost
    }

    public var estimatedTotalCostLabel: String {
        Self.formatEUR(estimatedTotalCost)
    }
}

// @MainActor
// public final class ProgramEditorViewModel: ObservableObject {
//     @Published public var program: Program
//     @Published public var selectedPackageID: Package.ID?

//     // Swap UI state
//     @Published public var swapTarget: SwapTarget?

//     @Published public var estimateBand: ProgramTally.EstimateBand = .low_high
//     @Published public var tallyPlacements: Set<ModuleComponentPlacement> = [.elementary]

//     public struct SwapTarget: Identifiable {
//         public let id: UUID = UUID()
//         public let packageID: Package.ID
//         public let moduleID: UUID
//         public let entryID: UUID
//         public let current: ModuleComponent
//     }

//     public init(program: Program = []) {
//         self.program = program
//         self.selectedPackageID = program.first?.id
//     }

//     public var selectedPackageIndex: Int? {
//         guard let id = selectedPackageID else { return nil }
//         return program.firstIndex(where: { $0.id == id })
//     }

//     public func addTemplate(_ template: Package) {
//         let instance = template.package() // NOTE: this currently regenerates id in your code. :contentReference[oaicite:1]{index=1}
//         program.append(instance)
//         selectedPackageID = instance.id
//     }

//     public func deletePackage(at offsets: IndexSet) {
//         program.remove(atOffsets: offsets)
//         if selectedPackageIndex == nil {
//             selectedPackageID = program.first?.id
//         }
//     }

//     public func movePackage(from: IndexSet, to: Int) {
//         program.move(fromOffsets: from, toOffset: to)
//     }

//     public func beginSwap(packageID: Package.ID, moduleID: UUID, entryID: UUID, current: ModuleComponent) {
//         swapTarget = .init(packageID: packageID, moduleID: moduleID, entryID: entryID, current: current)
//     }

//     public func commitSwap(newComponent: ModuleComponent) {
//         guard let target = swapTarget else { return }

//         guard let pIndex = program.firstIndex(where: { $0.id == target.packageID }) else { return }
//         guard let mIndex = program[pIndex].modules.firstIndex(where: { $0.id == target.moduleID }) else { return }
//         guard let eIndex = program[pIndex].modules[mIndex].entries.firstIndex(where: { $0.id == target.entryID }) else { return }

//         program[pIndex].modules[mIndex].entries[eIndex].component = newComponent
//         swapTarget = nil
//     }

//     // tallying
//     public var sessionDuration: Int { 60 }

//     public var totalSessions: SessionRange {
//         ProgramTally.sessions(program: program, sessionDuration: sessionDuration)
//     }

//     public var totalMinutes: MinuteRange {
//         ProgramTally.minutes(program: program)
//     }

//     public var totalSessionsLabel: String {
//         let t = totalSessions
//         if t.low == 0 && t.high == 0 { return "—" }
//         if t.low == t.high { return "\(t.low)" }
//         return "\(t.low)–\(t.high)"
//     }
// }
