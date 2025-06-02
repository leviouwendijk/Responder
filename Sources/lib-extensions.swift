import Foundation
import plate
import Economics

extension QuotaTierContent {
    public func replacements(roundTo multiple: Double = 10) -> [StringTemplateReplacement] {
        let prefix = tier.rawValue

        return [
            // base
            StringTemplateReplacement(
                placeholders: ["\(prefix)_base_prognosis"], 
                replacement: "\(base.rounded(to: multiple).prognosis)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_base_suggestion"], 
                replacement: "\(base.rounded(to: multiple).suggestion)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_base_base"], 
                replacement: "\(base.rounded(to: multiple).base)",
                initializer: .auto
            ),

            // cost
            StringTemplateReplacement(
                placeholders: ["\(prefix)_cost_prognosis"], 
                replacement: "\(cost.rounded(to: multiple).prognosis)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_cost_suggestion"], 
                replacement: "\(cost.rounded(to: multiple).suggestion)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_cost_base"], 
                replacement: "\(cost.rounded(to: multiple).base)",
                initializer: .auto
            ),

            // price
            StringTemplateReplacement(
                placeholders: ["\(prefix)_price_prognosis"], 
                replacement: "\(price.rounded(to: multiple).prognosis)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_price_suggestion"], 
                replacement: "\(price.rounded(to: multiple).suggestion)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_price_base"], 
                replacement: "\(price.rounded(to: multiple).base)",
                initializer: .auto
            ),
        ]
    }
}

extension QuotaTierRate {
    public func rounded(to multiple: Double) -> QuotaTierRate {
        return QuotaTierRate(
            prognosis: prognosis.roundTo(multiple),
            suggestion: suggestion.roundTo(multiple),
            base: base.roundTo(multiple)
        )
    }
}
