import Foundation

public enum PricingStrategy: String, Sendable, Hashable, CaseIterable {
    case weighted_average
    case midpoint

    public var title: String {
        switch self {
        case .weighted_average: return "Weighted"
        case .midpoint: return "Midpoint"
        }
    }
}
