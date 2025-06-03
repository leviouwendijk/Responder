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

    public func universalReplacements(roundTo multiple: Double = 10) -> [StringTemplateReplacement] {
        return [
            StringTemplateReplacement(
                placeholders: ["price_prognosis"], 
                replacement: "\(roundedToInt(price.rounded(to: multiple).prognosis))",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["price_suggestion"], 
                replacement: "\(roundedToInt(price.rounded(to: multiple).suggestion))",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["price_base"], 
                replacement: "\(roundedToInt(price.rounded(to: multiple).base))",
                initializer: .auto
            ),
        ]
    }
}

extension CustomQuota {
    public func replacements(for tier: QuotaTierType) -> [StringTemplateReplacement] {
        let prefix = "estimation"
        let kilometerCode = KilometerCodes.encrypt(for: travelCost.kilometers)
        let prognosisLocationStrings = SessionLocationString(for: tier, estimationObject: self.estimation.prognosis)
        let suggestionLocationStrings = SessionLocationString(for: tier, estimationObject: self.estimation.suggestion)
        
        func suffix(_ count: Int) -> String {
            return count > 1 ? "sessies" : "sessie"
        }   

        return [
            // prognosis
            StringTemplateReplacement(
                placeholders: ["\(prefix)_prognosis_count"], 
                replacement: "\(estimation.prognosis.count)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_prognosis_count_suffix"], 
                replacement: "\(estimation.prognosis.count) \(suffix(estimation.prognosis.count))",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_prognosis_local"], 
                replacement: "\(estimation.prognosis.local)",
                initializer: .auto
            ),

            // suggestion
            StringTemplateReplacement(
                placeholders: ["\(prefix)_suggestion_count"], 
                replacement: "\(estimation.suggestion.count)",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_suggestion_count_suffix"], 
                replacement: "\(estimation.suggestion.count) \(suffix(estimation.suggestion.count))",
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_suggestion_local"], 
                replacement: "\(estimation.suggestion.local)",
                initializer: .auto
            ),

            // kilometer code
            StringTemplateReplacement(
                placeholders: ["encrypted_kilometer_code"], 
                replacement: kilometerCode,
                initializer: .auto
            ),

            // particularized location strings
            StringTemplateReplacement(
                placeholders: ["\(prefix)_prognosis_remote_string"], 
                replacement: prognosisLocationStrings.split(for: .remote),
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_prognosis_local_string"], 
                replacement: prognosisLocationStrings.split(for: .local),
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_prognosis_full_string"], 
                replacement: prognosisLocationStrings.combined(),
                initializer: .auto
            ),

            StringTemplateReplacement(
                placeholders: ["\(prefix)_suggestion_remote_string"], 
                replacement: suggestionLocationStrings.split(for: .remote),
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_suggestion_local_string"],
                replacement: suggestionLocationStrings.split(for: .local),
                initializer: .auto
            ),
            StringTemplateReplacement(
                placeholders: ["\(prefix)_suggestion_full_string"],
                replacement: suggestionLocationStrings.combined(),
                initializer: .auto
            ),

            StringTemplateReplacement(
                placeholders: ["session_locations"],
                replacement: " ",
                initializer: .auto
            ),
        ]
    }
}
