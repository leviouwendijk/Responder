import Foundation

public enum ProgramPricer {}

extension ProgramPricer {
    public struct Input: Sendable, Hashable {
        // Band range (precise doubles)
        public var bandLow: Double
        public var bandHigh: Double

        // Strategy
        public var pricingStrategy: PricingStrategy
        public var midpointMarginPercent: Double
        public var weightedHighWeightPercent: Double
        public var weightedMarginPercent: Double

        // Pricing inputs
        public var sessionRate: Double
        public var homeSessions: Int
        public var travelDistanceKm: Double
        public var travelRatePerKm: Double

        public init(
            bandLow: Double,
            bandHigh: Double,
            pricingStrategy: PricingStrategy,
            midpointMarginPercent: Double,
            weightedHighWeightPercent: Double,
            weightedMarginPercent: Double,
            sessionRate: Double,
            homeSessions: Int,
            travelDistanceKm: Double,
            travelRatePerKm: Double
        ) {
            self.bandLow = bandLow
            self.bandHigh = bandHigh
            self.pricingStrategy = pricingStrategy
            self.midpointMarginPercent = midpointMarginPercent
            self.weightedHighWeightPercent = weightedHighWeightPercent
            self.weightedMarginPercent = weightedMarginPercent
            self.sessionRate = sessionRate
            self.homeSessions = homeSessions
            self.travelDistanceKm = travelDistanceKm
            self.travelRatePerKm = travelRatePerKm
        }
    }
}

extension ProgramPricer {
    public static func compute(_ input: Input) -> Result {
        let low = max(0, input.bandLow)
        let high = max(0, input.bandHigh)

        let base: Double
        let marginPercent: Double

        switch input.pricingStrategy {
        case .midpoint:
            base = (low + high) / 2.0
            marginPercent = clamp(input.midpointMarginPercent, 0, 200)

        case .weighted_average:
            let wHigh = clamp(input.weightedHighWeightPercent, 0, 100) / 100.0
            let wLow = 1.0 - wHigh
            base = (wLow * low) + (wHigh * high)
            marginPercent = clamp(input.weightedMarginPercent, 0, 200)
        }

        let sessionsPrecise = max(0, base)
        let sessionsCeiled = Int(ceil(sessionsPrecise))

        let rate = max(0, input.sessionRate)

        // Price based on decimals
        let sessionCostPrecise = sessionsPrecise * rate

        // Optional: conservative number you can still display
        let sessionCostCeiled = Double(sessionsCeiled) * rate

        let hs = max(0, input.homeSessions)
        let km = max(0, input.travelDistanceKm)
        let kmRate = max(0, input.travelRatePerKm)
        let travelCost = Double(hs) * km * kmRate

        // Subtotal uses precise session cost
        let subtotal = sessionCostPrecise + travelCost

        let marginFraction = marginPercent / 100.0
        let total = subtotal * (1.0 + marginFraction)
        let markup = total - subtotal

        return Result(
            bandLow: low,
            bandHigh: high,
            baseSessions: base,
            sessionsPrecise: sessionsPrecise,
            sessionsCeiled: sessionsCeiled,
            marginPercent: marginPercent,
            marginFraction: marginFraction,
            sessionRate: rate,
            sessionCostPrecise: sessionCostPrecise,
            sessionCostCeiled: sessionCostCeiled,
            homeSessions: hs,
            travelDistanceKm: km,
            travelRatePerKm: kmRate,
            travelCost: travelCost,
            subtotal: subtotal,
            markupAmount: markup,
            totalCost: total
        )
    }

    private static func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        max(lo, min(hi, v))
    }

    private static func roundToNearest(_ value: Double, step: Double) -> Double {
        let s = abs(step)
        guard s > 0 else { return value }
        return (value / s).rounded(.toNearestOrAwayFromZero) * s
    }
}

extension ProgramPricer {
    public struct Result: Sendable, Hashable {
        public var bandLow: Double
        public var bandHigh: Double

        public var baseSessions: Double

        public var sessionsPrecise: Double
        public var sessionsCeiled: Int

        public var marginPercent: Double
        public var marginFraction: Double

        public var sessionRate: Double

        public var sessionCostPrecise: Double
        public var sessionCostCeiled: Double

        public var homeSessions: Int
        public var travelDistanceKm: Double
        public var travelRatePerKm: Double
        public var travelCost: Double

        public var subtotal: Double
        public var markupAmount: Double
        public var totalCost: Double

        public func formulaLine(strategy: PricingStrategy, weightedHighWeightPercent: Double) -> String {
            switch strategy {
            case .midpoint:
                return "base = (low + high) / 2"
            case .weighted_average:
                let wHigh = max(0, min(100, weightedHighWeightPercent))
                let wLow = 100.0 - wHigh
                return "base = \(format2(wLow / 100.0))×low + \(format2(wHigh / 100.0))×high"
            }
        }

        /// Rounded to nearest 10 by default (e.g. 3,243 -> 3,240 ; 3,245 -> 3,250).
        public var totalCostRounded: Double {
            roundedTotalCost()
        }

        /// Choose your own step (10, 25, 50, 100, ...)
        public func roundedTotalCost(toNearest step: Double = 10) -> Double {
            ProgramPricer.roundToNearest(totalCost, step: step)
        }

        public var bandLine: String {
            "\(formatSessions(bandLow))–\(formatSessions(bandHigh)) sess"
        }

        public var baseLine: String {
            "\(formatSessions(baseSessions)) sess"
        }

        public var marginLine: String {
            "\(formatSessions(marginPercent))%"
        }

        public var sessionsLine: String { "\(sessionsCeiled) sess" }

        public func sessionCostLine(formatMoney: (Double) -> String) -> String {
            "\(formatSessions(sessionsPrecise)) × \(formatMoney(sessionRate)) = \(formatMoney(sessionCostPrecise))"
        }

        public func sessionCostCeiledLine(formatMoney: (Double) -> String) -> String {
            "\(sessionsCeiled) × \(formatMoney(sessionRate)) = \(formatMoney(sessionCostCeiled))"
        }

        public func travelCostLine(formatMoney: (Double) -> String) -> String {
            "\(homeSessions) × \(format2(travelDistanceKm)) km × \(formatMoney(travelRatePerKm)) = \(formatMoney(travelCost))"
        }

        public func subtotalLine(formatMoney: (Double) -> String) -> String {
            "\(formatMoney(sessionCostPrecise)) + \(formatMoney(travelCost)) = \(formatMoney(subtotal))"
        }

        public func markupLine(formatMoney: (Double) -> String) -> String {
            formatMoney(markupAmount)
        }

        public func totalLine(formatMoney: (Double) -> String) -> String {
            "\(formatMoney(subtotal)) + \(formatMoney(markupAmount)) = \(formatMoney(totalCost))"
        }

        public func roundedTotalLine(
            toNearest step: Double = 10,
            formatMoney: (Double) -> String
        ) -> String {
            let rounded = roundedTotalCost(toNearest: step)
            return "\(formatMoney(totalCost)) to nearest \(Int(step)) -> \(formatMoney(rounded))"
        }

        private func format2(_ v: Double) -> String { String(format: "%.2f", v) }
    }
}
