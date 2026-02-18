import SwiftUI

@MainActor
public final class ProgramEditorViewModel: ObservableObject {
    @Published public var program: Program
    @Published public var selectedPackageID: Package.ID?

    @Published public var swapTarget: SwapTarget?

    @Published public var estimateBand: ProgramTally.EstimateBand = .low_medium
    @Published public var tallyPlacements: Set<ModuleComponentPlacement> = [.elementary]

    @Published public var sessionRate: Double = 300
    @Published public var homeSessions: Int = 0
    @Published public var travelDistanceKm: Double = 0
    @Published public var travelRatePerKm: Double = 2.50

    @Published public var includePriceInProgram: Bool = true

    @Published public var pricingStrategy: PricingStrategy = .weighted_average
    @Published public var midpointMarginPercent: Double = 15
    @Published public var weightedHighWeightPercent: Double = 65
    @Published public var weightedMarginPercent: Double = 0

    @Published public var priceRoundingStep: Double = 10

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

    public var totalSessionsLabelRounded: String {
        let r = totalSessions.rounded
        if r.low == 0 && r.high == 0 { return "—" }
        if r.low == r.high { return "\(r.low)" }
        return "\(r.low)–\(r.high)"
    }
}

public extension ProgramEditorViewModel {
    private var includedProgram: Program {
        program.filter { $0.include }
    }

    var pricedSessionRangePrecise: SessionRange {
        ProgramTally.sessions(
            program: includedProgram,
            sessionDuration: sessionDuration,
            band: estimateBand,
            placements: tallyPlacements
        )
    }

    var pricedSessionRangeRounded: SessionRange.Rounded {
        pricedSessionRangePrecise.rounded
    }

    private var pricerInput: ProgramPricer.Input {
        let r = pricedSessionRangePrecise
        return .init(
            bandLow: max(0, r.low),
            bandHigh: max(0, r.high),
            pricingStrategy: pricingStrategy,
            midpointMarginPercent: midpointMarginPercent,
            weightedHighWeightPercent: weightedHighWeightPercent,
            weightedMarginPercent: weightedMarginPercent,
            sessionRate: sessionRate,
            homeSessions: homeSessions,
            travelDistanceKm: travelDistanceKm,
            travelRatePerKm: travelRatePerKm
        )
    }

    private var pricerResult: ProgramPricer.Result {
        ProgramPricer.compute(pricerInput)
    }

    var estimatedSessionCost: Double { pricerResult.sessionCostPrecise }
    var estimatedTravelCost: Double { pricerResult.travelCost }
    var estimatedSubtotalCost: Double { pricerResult.subtotal }
    var pricingMarginPercent: Double { pricerResult.marginPercent }
    var pricingMarginFraction: Double { pricerResult.marginFraction }
    var estimatedTotalCost: Double { pricerResult.totalCost }

    var estimatedTotalCostLabel: String {
        Self.formatEUR(estimatedTotalCost)
    }

    var estimatedTotalCostRoundedLine: String {
        pricerResult.roundedTotalLine(toNearest: priceRoundingStep, formatMoney: formatMoney)
    }
}

// public func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
//     max(lo, min(hi, v))
// }

public extension ProgramEditorViewModel {
    typealias PricingDebug = ProgramPricer.Result

    private func makeDebug(strategy: PricingStrategy) -> PricingDebug {
        // let r = pricedSessionRangeRounded
        let r = pricedSessionRangePrecise

        let input = ProgramPricer.Input(
            bandLow: max(0, r.low),
            bandHigh: max(0, r.high),
            pricingStrategy: strategy,
            midpointMarginPercent: midpointMarginPercent,
            weightedHighWeightPercent: weightedHighWeightPercent,
            weightedMarginPercent: weightedMarginPercent,
            sessionRate: sessionRate,
            homeSessions: homeSessions,
            travelDistanceKm: travelDistanceKm,
            travelRatePerKm: travelRatePerKm
        )
        return ProgramPricer.compute(input)
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
