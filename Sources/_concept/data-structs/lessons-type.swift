import Foundation

public enum LessonFormat: String, Sendable, Codable, Hashable, CaseIterable {
    case preparation
    case equipment
    case comprehension
    case practice
    case exercise
    case demonstration
}

public extension LessonFormat {
    struct LessonFormatData: Sendable, Hashable {
        public let title: String

        public init(title: String) {
            self.title = title
        }
    }

    var data: LessonFormatData {
        switch self {
        case .preparation:
            return LessonFormatData(title: "Voorbereiding")

        case .equipment:
            return LessonFormatData(title: "Benodigdheden")

        case .comprehension:
            return LessonFormatData(title: "Uitleg")

        case .practice:
            return LessonFormatData(title: "Praktijk")

        case .exercise:
            return LessonFormatData(title: "Oefening")

        case .demonstration:
            return LessonFormatData(title: "Demonstratie")
        }
    }
}

public enum LessonConcept: String, Sendable, Codable, Hashable, CaseIterable {
    // preparation
    case training_process
    case quality_and_quantity_repetitions
    case duration_and_performance_peaks
    case training_logbook

    case hunger_drive

    // management
    case management
    case forced_lure_or_pressured_turn_away
    case above_threshold
    case near_or_at_threshold
    case below_threshold

    // knowledge of behavior
    case classical_conditioning
    case operant_conditioning
    case counter_conditioning
    case premack_principle
    case thresholds
    case salience
    case valence

    // communication
    case markers
    case overshadowing

    // motivation
    case food_drive
    case chase
    case food_chase
    case movement
    case contrast

    case attention_retention
    case post_reinforcement_pause
    case reward_variability
    case reinforcement_rate

    case play_drive
    case possession
    case outing
    case tugging

    // engagement
    case engagement
    case low_distraction_environments
    case controlled_static_distraction
    case controlled_dynamic_distraction
    case uncontrolled_static_distraction
    case uncontrolled_dynamic_distraction

    case around_distractions
    case social_distraction

    // shaping
    case obedience
    case assisted_shaping
    case luring
    case lure_fading
    case free_shaping

    case capping

    // pressure 
    case pressure_work
    case leash_habituation
    case opposition_reflex
    case body_pressure
    case spatial_pressure

    case punishment_event

    // applied behavior modification
    case habituation
    case desensitization
    case redirection

    case arousal
    case re_association // counter-conditioning
    case turn_away

    // applied behavior shaping
    case recall
    case restrained_recall
}

public extension ModuleComponent {
    var displayTagline: String {
        if let tagline, !tagline.isEmpty {
            return tagline
        }

        let prefix: String? = {
            if format.contains(.comprehension) { return "Begrip" }
            if format.contains(.practice) { return "Praktijk" }
            if format.contains(.exercise) { return "Oefening" }
            if format.contains(.demonstration) { return "Demo" }
            if format.contains(.preparation) { return "Voorbereiding" }
            if format.contains(.equipment) { return "Benodigdheden" }
            return nil
        }()

        let conceptList: [String] = concepts
            .map { $0.title_nl }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        let conceptsText = conceptList.joined(separator: " + ")

        if let prefix {
            if conceptsText.isEmpty { return prefix }
            return "\(prefix): \(conceptsText)"
        }

        return conceptsText.isEmpty ? "onderdeel" : conceptsText
    }
}

public extension LessonConcept {
    var title_nl: String {
        switch self {
        // preparation
        case .training_process: return "trainingsproces"
        case .quality_and_quantity_repetitions: return "kwaliteit / kwantiteit van herhalingen"
        case .duration_and_performance_peaks: return "trainings-duur en prestatie-pieken"
        case .training_logbook: return "training logboek"
        
        case .hunger_drive: return "hongerdrijf"

        // management
        case .management: return "management (restrictie)"
        case .forced_lure_or_pressured_turn_away: return "lokmiddel en/of draai forceren als (nood-)management"
        case .above_threshold: return "boven drempelwaarde"
        case .near_or_at_threshold: return "nabij of op drempelwaarde"
        case .below_threshold: return "onder drempelwaarde"

        // knowledge of behavior
        case .classical_conditioning: return "klassieke conditionering"
        case .operant_conditioning: return "operante conditionering"
        case .counter_conditioning: return "counter-conditioning"
        case .premack_principle: return "premack-principe"
        case .thresholds: return "drempelwaardes"
        case .salience: return "saillantie"
        case .valence: return "valentie"

        // communication
        case .markers: return "markeersignalen"
        case .overshadowing: return "overschaduwing"

        // motivation
        case .food_drive: return "voedseldrijf"
        case .chase: return "jagen"
        case .food_chase: return "voerjaagspel"
        case .movement: return "beweging"
        case .contrast: return "contrast"

        case .attention_retention: return "aandacht-behoud"
        case .post_reinforcement_pause: return "post-beloning-pauze"
        case .reward_variability: return "beloningsvariatie"
        // case .reinforcement_rate: return "bekrachtigingsfrequentie"
        case .reinforcement_rate: return "beloningsfrequentie"

        case .play_drive: return "speeldrijf"
        case .possession: return "bezit"
        case .outing: return "loslaten"
        case .tugging: return "trekspel"

        // engagement
        case .engagement: return "betrokkenheid"
        case .low_distraction_environments: return "laag-prikkelende omgevingen"
        case .controlled_static_distraction: return "statische afleiding (gecontroleerd)"
        case .controlled_dynamic_distraction: return "dynamische afleiding (gecontroleerd)"
        case .uncontrolled_static_distraction: return "statische afleiding (ongecontroleerd)"
        case .uncontrolled_dynamic_distraction: return "dynamische afleiding (ongecontroleerd)"

        case .around_distractions: return "rondom afleidingen"
        case .social_distraction: return "sociale afleiding"

        // shaping
        case .obedience: return "gehoorzaamheid"
        case .assisted_shaping: return "geassisteerd vormen"
        case .luring: return "lokmiddel"
        case .lure_fading: return "lokmiddel vervagen"
        case .free_shaping: return "vrij vormen"
        case .capping: return "capping"

        // pressure
        case .pressure_work: return "drukwerk"
        case .leash_habituation: return "lijn-gewenning"
        case .opposition_reflex: return "opposite-reflex"
        case .body_pressure: return "lichaamsdruk"
        case .spatial_pressure: return "ruimtelijke druk"

        case .punishment_event: return "correctie-handeling (sociaal aspect, fysieke handeling, meer dan disruptie)"

        // applied behavior modification
        case .habituation: return "habituatie"
        case .desensitization: return "desensitisatie"
        case .redirection: return "herleiden"
        case .arousal: return "opwinding"
        case .re_association: return "her-associatie"

        // key behaviors
        case .turn_away: return "afdraai en (weg)beweging"

        // applied behavior shaping
        case .recall: return "terugroepen"
        case .restrained_recall: return "terugroepen onder bedwelming"
        }
    }
}
