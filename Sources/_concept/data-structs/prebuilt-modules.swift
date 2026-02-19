import Foundation

public enum PrebuiltModules {
    public static func preparation() -> Module {
        Module(
            title: "Voorbereiding",
            entries: [
                .init(component: PrebuiltModuleComponents.Preparation.training_process_design, placement: .elementary),
                .init(component: PrebuiltModuleComponents.Preparation.training_logbook, placement: .exchangeable),
            ]
        )
    }

    public static func equipment() -> Module {
        Module(
            title: "Materiaal",
            entries: [
                .init(component: PrebuiltModuleComponents.Equipment.equipment_leashing, placement: .elementary),
                .init(component: PrebuiltModuleComponents.Equipment.equipment_mounting, placement: .elementary),

                .init(component: PrebuiltModuleComponents.Equipment.equipment_pouch, placement: .exchangeable),
                .init(component: PrebuiltModuleComponents.Equipment.equipment_toys, placement: .exchangeable),
            ]
        )
    }

    public static func management() -> Module {
        Module(
            title: "Management: opzet (her)vorming, voorkom ongewenst gedrag (en/of verergerging)",
            entries: [
                .init(component: PrebuiltModuleComponents.Management.forced_turn_away, placement: .elementary),
            ]
        )
    }

    public static func communication() -> Module {
        Module(
            title: "Voorspelbaarheid en communicatie",
            entries: [
                // Elementary (core)
                .init(component: PrebuiltModuleComponents.Communication.markers_and_overshadowing, placement: .elementary),
                .init(component: PrebuiltModuleComponents.Communication.thresholds_drive_priority, placement: .elementary),

                // Exchangeable
                .init(component: PrebuiltModuleComponents.Communication.classical_conditioning, placement: .exchangeable),
                // .init(component: PrebuiltModuleComponents.Communication.overshadowing, placement: .exchangeable),
            ]
        )
    }

    public static func motivation() -> Module {
        Module(
            title: "Motivatie: ontwikkeling hoge aantrekkingskracht en aandacht-manipulatie",
            entries: [
                // Elementary (core)
                .init(component: PrebuiltModuleComponents.Motivation.movement_variation_frequency, placement: .elementary),
                .init(component: PrebuiltModuleComponents.Motivation.food_drive_chase_game, placement: .elementary),

                // Exchangeable
                .init(component: PrebuiltModuleComponents.Motivation.play_drive_tug_development, placement: .exchangeable),
                .init(component: PrebuiltModuleComponents.Motivation.demo_chase, placement: .exchangeable),
                .init(component: PrebuiltModuleComponents.Motivation.demo_tug, placement: .exchangeable),
            ]
        )
    }

    public static func engagement() -> Module {
        Module(
            title: "Betrokkenheid: behoud hoge aantrekkingskracht rondom afleidingen en in diverse omstandigheden",
            entries: [
                // Elementary (core)
                .init(component: PrebuiltModuleComponents.Engagement.focus_retention_foundation, placement: .elementary),

                // Exchangeable
                .init(component: PrebuiltModuleComponents.Engagement.context_signals_start_stop, placement: .exchangeable),
            ]
        )
    }

    public static func neutralisation() -> Module {
        Module(
            title: "Neutralisatie: (her)associatie omgevingsprikkeling (habituatie)",
            entries: [
                // Elementary (core) — mirrors fase2 bullets
                .init(component: PrebuiltModuleComponents.Neutralisation.desensitization_salience_valence, placement: .elementary),
                .init(component: PrebuiltModuleComponents.Neutralisation.exercise_controlled_dynamic_distraction, placement: .elementary),
                .init(component: PrebuiltModuleComponents.Neutralisation.around_uncontrolled_distractions, placement: .elementary),

                // Exchangeable (optional / swap-ins) — mirrors fase2 callout
                .init(component: PrebuiltModuleComponents.Neutralisation.exercise_controlled_static_distraction, placement: .exchangeable),
            ]
        )
    }

    public static func pressure() -> Module {
        Module(
            title: "Drukwerk: vorming, sturing, management",
            entries: [
                .init(component: PrebuiltModuleComponents.Pressure.leash_habituation_opposition_reflex, placement: .elementary, include: false),
                .init(component: PrebuiltModuleComponents.Pressure.body_spatial_pressure, placement: .exchangeable, include: false),
            ]
        )
    }

    public static func shaping() -> Module {
        Module(
            title: "Vorming gedragskaders (gehoorzaamheid, toegepaste gedragssignalen)",
            entries: [
                .init(component: PrebuiltModuleComponents.Shaping.assisted_shaping_obedience, placement: .exchangeable, include: false),
            ]
        )
    }

    public static func behavior_modification() -> Module {
        Module(
            title: "Herleiding en controle onder prikkelcontext",
            entries: [
                // Elementary (core) — mirrors fase3 bullets
                .init(component: PrebuiltModuleComponents.BehaviorModification.redirection_attention, placement: .elementary),
                .init(component: PrebuiltModuleComponents.BehaviorModification.redirection_on_rising_arousal, placement: .elementary),
                .init(component: PrebuiltModuleComponents.BehaviorModification.redirection_with_potential_pressure, placement: .elementary),

                // Exchangeable (optional / swap-ins) — mirrors fase3 callout
                .init(component: PrebuiltModuleComponents.BehaviorModification.premack_discharge_energy, placement: .exchangeable),
                .init(component: PrebuiltModuleComponents.BehaviorModification.capping_dynamic_to_static, placement: .exchangeable),
                .init(component: PrebuiltModuleComponents.BehaviorModification.exercise_dynamic_static_alternation, placement: .exchangeable),
            ]
        )
    }

    public static func applied_behavior_modification(target: BehaviorProblem) -> Module {
        let _ = target
        return behavior_modification()
    }
}
