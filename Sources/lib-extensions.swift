import Foundation
import plate
import Economics

extension QuotaTierRate {
    public func rounded(to multiple: Double) -> QuotaTierRate {
        return QuotaTierRate(
            prognosis: prognosis.roundTo(multiple),
            suggestion: suggestion.roundTo(multiple),
            base: base.roundTo(multiple)
        )
    }
}

extension QuotaTierContent {
    public func replacements(roundTo multiple: Double = 10) -> [StringTemplateReplacement] {
        let prefix = tier.rawValue

        return [
            // // base
            // ---------------------------------------------------
            // StringTemplateReplacement(
            //     placeholders: ["\(prefix)_base_prognosis"], 
            //     replacement: "\(base.rounded(to: multiple).prognosis)",
            //     initializer: .auto
            // ),
            // StringTemplateReplacement(
            //     placeholders: ["\(prefix)_base_suggestion"], 
            //     replacement: "\(base.rounded(to: multiple).suggestion)",
            //     initializer: .auto
            // ),
            // StringTemplateReplacement(
            //     placeholders: ["\(prefix)_base_base"], 
            //     replacement: "\(base.rounded(to: multiple).base)",
            //     initializer: .auto
            // ),

            // // cost
            // ---------------------------------------------------
            // StringTemplateReplacement(
            //     placeholders: ["\(prefix)_cost_prognosis"], 
            //     replacement: "\(cost.rounded(to: multiple).prognosis)",
            //     initializer: .auto
            // ),
            // StringTemplateReplacement(
            //     placeholders: ["\(prefix)_cost_suggestion"], 
            //     replacement: "\(cost.rounded(to: multiple).suggestion)",
            //     initializer: .auto
            // ),
            // StringTemplateReplacement(
            //     placeholders: ["\(prefix)_cost_base"], 
            //     replacement: "\(cost.rounded(to: multiple).base)",
            //     initializer: .auto
            // ),


            // price
            // (for now, only price is relevant for quota)
            // ---------------------------------------------------
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

extension CustomQuota {
    public func replacements() -> [StringTemplateReplacement] {
        let prefix = "estimation"
        let kilometerCode = KilometerCodes.encrypt(for: travelCost.kilometers)

        return [
            StringTemplateReplacement(
                placeholders: ["\(prefix)_prognosis_count"], 
                replacement: "\(estimation.prognosis.count)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_prognosis_local"], 
                replacement: "\(estimation.prognosis.local)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_suggestion_count"], 
                replacement: "\(estimation.suggestion.count)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_suggestion_local"], 
                replacement: "\(estimation.suggestion.local)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["encrypted_kilometer_code"], 
                replacement: kilometerCode,
                initializer: .auto
            ),
        ]
    }
}
