import SwiftUI

@MainActor
public final class ProgramEditorViewModel: ObservableObject {
    @Published public var program: Program
    @Published public var selectedPackageID: Package.ID?

    // Swap UI state
    @Published public var swapTarget: SwapTarget?

    @Published public var estimateBand: ProgramTally.EstimateBand = .low_medium
    @Published public var tallyPlacements: Set<ModuleComponentPlacement> = [.elementary]

    // ---------------------------------------------------------
    // PRICING
    // ---------------------------------------------------------
    @Published public var sessionRate: Double = 300
    @Published public var homeSessions: Int = 0
    @Published public var travelDistanceKm: Double = 0
    @Published public var travelRatePerKm: Double = 2.50

    @Published public var includePriceInProgram: Bool = true

    // ---------------------------------------------------------
    // PRICING STRATEGY
    // ---------------------------------------------------------
    @Published public var pricingStrategy: PricingStrategy = .weighted_average
    @Published public var midpointMarginPercent: Double = 15
    @Published public var weightedHighWeightPercent: Double = 65
    @Published public var weightedMarginPercent: Double = 0

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

    // // ---------------------------------------------------------
    // // PRICING (derived)
    // // ---------------------------------------------------------
    // private var includedProgram: Program {
    //     program.filter { $0.include }
    // }

    // public var pricedSessionRangeRounded: SessionRange.Rounded {
    //     ProgramTally.sessions(
    //         program: includedProgram,
    //         sessionDuration: sessionDuration,
    //         band: estimateBand,
    //         placements: tallyPlacements
    //     ).rounded
    // }

    // // /// Uses the "high" value of the currently selected estimate band.
    // // public var pricedSessionsHigh: Int {
    // //     pricedSessionRangeRounded.high
    // // }

    // // public var estimatedSessionCost: Double {
    // //     Double(pricedSessionsHigh) * max(0, sessionRate)
    // // }

    // // private func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
    // //     max(lo, min(hi, v))
    // // }

    // private var pricedSessionsForPricing: Int {
    //     let r = pricedSessionRangeRounded
    //     let low = Double(max(0, r.low))
    //     let high = Double(max(0, r.high))

    //     let base: Double
    //     let marginFraction: Double

    //     switch pricingStrategy {
    //     case .midpoint:
    //         base = (low + high) / 2.0
    //         marginFraction = clamp(midpointMarginPercent, 0, 200) / 100.0

    //     case .weighted_average:
    //         let wHigh = clamp(weightedHighWeightPercent, 0, 100) / 100.0
    //         let wLow = 1.0 - wHigh
    //         base = (wLow * low) + (wHigh * high)
    //         marginFraction = clamp(weightedMarginPercent, 0, 200) / 100.0
    //     }

    //     let withMargin = base * (1.0 + marginFraction)
    //     return Int(ceil(withMargin))
    // }

    // public var estimatedSessionCost: Double {
    //     Double(pricedSessionsForPricing) * max(0, sessionRate)
    // }

    // public var estimatedTravelCost: Double {
    //     let hs = Double(max(0, homeSessions))
    //     let km = max(0, travelDistanceKm)
    //     let rate = max(0, travelRatePerKm)
    //     return hs * km * rate
    // }

    // public var estimatedTotalCost: Double {
    //     estimatedSessionCost + estimatedTravelCost
    // }

    // public var estimatedTotalCostLabel: String {
    //     Self.formatEUR(estimatedTotalCost)
    // }
}

public extension ProgramEditorViewModel {
    private var includedProgram: Program {
        program.filter { $0.include }
    }

    var pricedSessionRangeRounded: SessionRange.Rounded {
        ProgramTally.sessions(
            program: includedProgram,
            sessionDuration: sessionDuration,
            band: estimateBand,
            placements: tallyPlacements
        ).rounded
    }

    /// Base session estimate (no margin applied here).
    private var pricingBaseSessions: Double {
        let r = pricedSessionRangeRounded
        let low = Double(max(0, r.low))
        let high = Double(max(0, r.high))

        switch pricingStrategy {
        case .midpoint:
            return (low + high) / 2.0

        case .weighted_average:
            let wHigh = clamp(weightedHighWeightPercent, 0, 100) / 100.0
            let wLow = 1.0 - wHigh
            return (wLow * low) + (wHigh * high)
        }
    }

    /// Sessions used for pricing (ceil of base). Margin is a PRICE markup, not added sessions.
    private var pricedSessionsForPricing: Int {
        Int(ceil(max(0, pricingBaseSessions)))
    }

    var estimatedSessionCost: Double {
        Double(pricedSessionsForPricing) * max(0, sessionRate)
    }

    var estimatedTravelCost: Double {
        let hs = Double(max(0, homeSessions))
        let km = max(0, travelDistanceKm)
        let rate = max(0, travelRatePerKm)
        return hs * km * rate
    }

    /// Subtotal before margin/markup.
    var estimatedSubtotalCost: Double {
        estimatedSessionCost + estimatedTravelCost
    }

    /// Margin percent for the currently selected strategy (price markup).
    var pricingMarginPercent: Double {
        switch pricingStrategy {
        case .midpoint:
            return clamp(midpointMarginPercent, 0, 200)
        case .weighted_average:
            return clamp(weightedMarginPercent, 0, 200)
        }
    }

    var pricingMarginFraction: Double {
        pricingMarginPercent / 100.0
    }

    /// Total cost includes PRICE markup on subtotal.
    var estimatedTotalCost: Double {
        estimatedSubtotalCost * (1.0 + pricingMarginFraction)
    }

    var estimatedTotalCostLabel: String {
        Self.formatEUR(estimatedTotalCost)
    }
}

public func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
    max(lo, min(hi, v))
}

public extension ProgramEditorViewModel {
    struct PricingDebug: Sendable, Hashable {
        public let bandLow: Int
        public let bandHigh: Int

        public let baseSessions: Double
        public let sessionsCeiled: Int

        public let marginPercent: Double
        public let marginFraction: Double

        public let sessionRate: Double
        public let sessionCost: Double

        public let homeSessions: Int
        public let travelDistanceKm: Double
        public let travelRatePerKm: Double
        public let travelCost: Double

        public let subtotal: Double
        public let markupAmount: Double
        public let totalCost: Double
    }

    private func makeDebug(strategy: PricingStrategy) -> PricingDebug {
        let r = pricedSessionRangeRounded
        let low = Double(max(0, r.low))
        let high = Double(max(0, r.high))

        let base: Double
        let marginPercent: Double

        switch strategy {
        case .midpoint:
            base = (low + high) / 2.0
            marginPercent = clamp(midpointMarginPercent, 0, 200)

        case .weighted_average:
            let wHigh = clamp(weightedHighWeightPercent, 0, 100) / 100.0
            let wLow = 1.0 - wHigh
            base = (wLow * low) + (wHigh * high)
            marginPercent = clamp(weightedMarginPercent, 0, 200)
        }

        let sessionsCeiled = Int(ceil(max(0, base)))

        let rate = max(0, sessionRate)
        let sessionCost = Double(sessionsCeiled) * rate

        let hs = max(0, homeSessions)
        let km = max(0, travelDistanceKm)
        let kmRate = max(0, travelRatePerKm)
        let travelCost = Double(hs) * km * kmRate

        let subtotal = sessionCost + travelCost

        let marginFraction = marginPercent / 100.0
        let total = subtotal * (1.0 + marginFraction)
        let markup = total - subtotal

        return PricingDebug(
            bandLow: max(0, r.low),
            bandHigh: max(0, r.high),
            baseSessions: base,
            sessionsCeiled: sessionsCeiled,
            marginPercent: marginPercent,
            marginFraction: marginFraction,
            sessionRate: rate,
            sessionCost: sessionCost,
            homeSessions: hs,
            travelDistanceKm: km,
            travelRatePerKm: kmRate,
            travelCost: travelCost,
            subtotal: subtotal,
            markupAmount: markup,
            totalCost: total
        )
    }

    var pricingDebugWeighted: PricingDebug {
        makeDebug(strategy: .weighted_average)
    }

    var pricingDebugMidpoint: PricingDebug {
        makeDebug(strategy: .midpoint)
    }

    func formatMoney(_ value: Double) -> String {
        Self.formatEUR(value)
    }

    func formatNumber2(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
