import Foundation

public enum PrebuiltModuleComponents {}

public extension PrebuiltModuleComponents {
    enum Preparation {
        public static let training_process_design: ModuleComponent = .init(
            concepts: [
                .training_process,
                .quality_and_quantity_repetitions,
                .duration_and_performance_peaks
            ],
            format: [
                .preparation,
                .comprehension
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 15
                )
            ),
            tagline: "Trainingsproces: ontwerp en structuur",
            caption: "Richtlijnen voor een successvol trainingsproces"
        )

        public static let training_logbook: ModuleComponent = .init(
            concepts: [
                .training_process,
                .training_logbook
            ],
            format: [
                .preparation,
                .comprehension
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 15
                )
            ),
            tagline: "Trainingsproces: logboek, doelstellingen",
            caption: "Definitie van success, progressie bijhouden"
        )
    }
}


public extension PrebuiltModuleComponents {
    enum Equipment {
        public static let equipment_leashing: ModuleComponent = .init(
            concepts: [
                .management
            ],
            format: [
                .equipment
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 15
                )
            ),
            tagline: "Materiaal: lijnen (korthouder, korte lengte, lange lengtes, handvatten)",
            caption: "Gebruik van verscheidene lijnsoorten"
        )

        public static let equipment_mounting: ModuleComponent = .init(
            concepts: [
                .management
            ],
            format: [
                .equipment
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 15
                )
            ),
            tagline: "Materiaal: halsbanden (vlak / martingaal / slip) en tuigen",
            caption: "Gebruik van verscheidene bevestigingen"
        )

        public static let equipment_pouch: ModuleComponent = .init(
            concepts: [
                .management
            ],
            format: [
                .equipment
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 10
                )
            ),
            tagline: "Materiaal: (non-slingerende) voerbuidel",
            caption: "Paraatheid van voer bij voedsel-gerelateerde oefeningen"
        )

        public static let equipment_toys: ModuleComponent = .init(
            concepts: [
                .engagement
            ],
            format: [
                .equipment
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 15
                )
            ),
            tagline: "Materiaal: speelgoed voor speeldrijf",
            caption: "Verschillende opties binnen speelgoed (hardheid, textuur)"
        )
    }
}

public extension PrebuiltModuleComponents {
    enum Management {
        public static let forced_turn_away: ModuleComponent = .init(
            concepts: [
                .forced_lure_or_pressured_turn_away,
                .management,
                .above_threshold,
                .thresholds,
                .turn_away,
                .redirection
            ],
            format: [
                .practice
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 20
                )
            ),
            tagline: "Nood-management: lokmiddel of (weg)draaien wanneer boven drempelwaarde",
            caption: "Een 'uitweg' voor momenten waarop trainen niet meer kan: veilig afstand nemen, escalatie voorkomen, en daarna weer terug naar een trainbare situatie."
        )
    }
}

public extension PrebuiltModuleComponents {
    enum Communication {
        public static let markers_and_overshadowing: ModuleComponent = .init(
            concepts: [
                .markers,
                .overshadowing
            ],
            format: [
                .comprehension,
                .demonstration
            ],
            allocation: .init(
                minutes: .init(
                    low: 15,
                    high: 60
                )
            ),
            tagline: "Begrip markeersignalen en overschaduwing",
            caption: "5 primaire communicatie-signalen voor effectieve communicatie (feedback)"
        )

        public static let classical_conditioning: ModuleComponent = .init(
            concepts: [
                .classical_conditioning
            ],
            format: [
                .comprehension
            ],
            allocation: .init(
                minutes: .init(
                    low: 15,
                    high: 30
                )
            ),
            tagline: "Klassieke conditionering (associatie-principe)",
            caption: "Voorspellende [Prikkel] -> [Gevolg] relatie"
        )

        public static let overshadowing: ModuleComponent = .init(
            concepts: [
                .overshadowing
            ],
            format: [
                .comprehension,
                .demonstration
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 30
                )
            ),
            tagline: "Overschaduwing",
            caption: "Inachtname van overstemmende prikkels (visueel > auditief)"
        )

        public static let thresholds_drive_priority: ModuleComponent = .init(
            concepts: [
                .thresholds
            ],
            format: [
                .comprehension
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 15
                )
            ),
            tagline: "Begrip drempelwaardes: relatieve prioriteit van drijfveren",
            caption: "Inachtname van drempelwaardes tot op waarneming, fixatie, en escalatie"
        )
    }
}

public extension PrebuiltModuleComponents {
    enum Motivation {
        public static let movement_variation_frequency: ModuleComponent = .init(
            concepts: [
                .engagement,
                .movement,
                .reward_variability,
                .contrast,
                .reinforcement_rate
            ],
            format: [
                .comprehension
            ],
            allocation: .init(
                sessions: .init(
                    low: 1,
                    high: 2
                )
            ),
            tagline: "Begrip: beweging, variatie, contrast, frequentie (interesse-behoud)",
            caption: "De kernprincipes van opbouw naar hoge motivatie / drijf"
        )

        public static let food_drive_chase_game: ModuleComponent = .init(
            concepts: [
                .engagement,
                .movement,
                .reward_variability,
                .reinforcement_rate,
                .food_chase,
                .food_drive
            ],
            format: [
                .practice,
                .exercise
            ],
            allocation: .init(
                sessions: .init(
                    low: 1,
                    high: 3
                )
            ),
            tagline: "Oefening voedseldrijf: (voer)jaagspel",
            caption: "Toepassing van motivatieprincipes, gelijktijdige belading (terminerend) beloningssignaal"
        )

        public static let play_drive_tug_development: ModuleComponent = .init(
            concepts: [
                .engagement,
                .tugging,
                .outing
            ],
            format: [
                .practice,
                .exercise
            ],
            allocation: .init(
                sessions: .init(
                    low: 1,
                    high: 3
                )
            ),
            tagline: "Speeldrijf: ontwikkeling van interactief trekspel",
            caption: "Toepassing van motivatieprincipes, gelijktijdige belading (terminerend) beloningssignaal"
        )

        public static let demo_chase: ModuleComponent = .init(
            concepts: [
                .food_chase
            ],
            format: [
                .demonstration
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 15
                )
            ),
            tagline: "Demo: (voer)jaagspel, markeersignalen, gedragssignalen",
            caption: "Voorbeeld van eindresultaat bij (voer)jaagspel"
        )

        public static let demo_tug: ModuleComponent = .init(
            concepts: [
                .tugging
            ],
            format: [
                .demonstration
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 15
                )
            ),
            tagline: "Demo: trekspel, markeersignalen, gedragssignalen",
            caption: "Voorbeeld van eindresultaat bij trekspel"
        )
    }
}

public extension PrebuiltModuleComponents {
    enum Neutralisation {
        public static let desensitization_salience_valence: ModuleComponent = .init(
            concepts: [
                .desensitization,
                .salience,
                .valence,
                .re_association,
                .habituation
            ],
            format: [
                .comprehension
            ],
            allocation: .init(
                minutes: .init(
                    low: 10,
                    high: 30
                )
            ),
            tagline: "Begrip: desensitisatie / desensibilisatie",
            caption: "Afname van saillantie (opmerkbaarheid), ombuiging van valentie (neutralizeer appetitieve of afstotende waarde)"
        )

        public static let exercise_controlled_dynamic_distraction: ModuleComponent = .init(
            concepts: [
                .controlled_dynamic_distraction,
                .social_distraction,
                .redirection,
                .attention_retention
            ],
            format: [
                .exercise,
                .practice
            ],
            allocation: .init(
                sessions: .init(
                    low: 1,
                    high: 3
                )
            ),
            tagline: "Oefening: dynamische afleiding met tweede (vertrouwde) persoon",
            caption: "Wegroepen van versterkend naar non-versterkende afleiding"
        )

        public static let exercise_controlled_static_distraction: ModuleComponent = .init(
            concepts: [
                .recall,
                .controlled_static_distraction,
                .attention_retention
            ],
            format: [
                .exercise,
                .practice
            ],
            allocation: .init(
                minutes: .init(
                    low: 10,
                    high: 30
                )
            ),
            tagline: "Oefening: afroepen bij statische (vertrouwde) afleiding",
            caption: "Bevordering van betrokkenheid rondom non-versterkende afleidingen"
        )
        
        public static let around_uncontrolled_distractions: ModuleComponent = .init(
            concepts: [
                .movement,
                .pressure_work,
                .reinforcement_rate,
                .reward_variability,
                .around_distractions,
                .arousal
            ],
            format: [
                .comprehension,
                .practice
            ],
            allocation: .init(
                minutes: .init(
                    low: 10,
                    high: 45
                )
            ),
            tagline: "(Weg)beweging, druk en beloningsfrequentie rondom (vertrouwde) afleidingen",
            caption: "Verhouding tegenover onbeheerste (mogelijk-versterkende) afleidingen, middels betrekking en mogelijk drukwerk"
        )
    }
}

public extension PrebuiltModuleComponents {
    enum Pressure {
        public static let leash_habituation_opposition_reflex: ModuleComponent = .init(
            concepts: [
                .pressure_work,
                .leash_habituation,
                .opposition_reflex
            ],
            format: [
                .comprehension,
                .practice
            ],
            allocation: .init(
                minutes: .init(
                    low: 10,
                    high: 45
                )
            ),
            tagline: "Drukwerk: lijn-gewenning en opposite-reflex",
            caption: "Inzetbaarheid van lijn als sturend middel (gebruik bij vorming, management)"
        )

        public static let body_spatial_pressure: ModuleComponent = .init(
            concepts: [
                .pressure_work,
                .body_pressure,
                .spatial_pressure
            ],
            format: [
                .comprehension,
                .practice
            ],
            allocation: .init(
                minutes: .init(
                    low: 15,
                    high: 60
                )
            ),
            tagline: "Lichaams- en ruimtelijke druk: vorming en geleiding",
            caption: "Begeleiding via lichaamstaal om ruimtegebruik en positie te sturen"
        )
    }
}

public extension PrebuiltModuleComponents {
    enum Engagement {
        public static let focus_retention_foundation: ModuleComponent = .init(
            concepts: [
                .engagement
            ],
            format: [
                .practice
            ],
            allocation: .init(
                minutes: .init(
                    low: 15,
                    high: 60
                )
            ),
            tagline: "Oefening: activatie bij aandacht (vrij van signalering gevormd)",
            caption: "Fundering van focus-verkrijging, naast focus-behoud (motivatieprincipes)"
        )

        public static let context_signals_start_stop: ModuleComponent = .init(
            concepts: [
                .management
            ],
            format: [
                .comprehension
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 15
                )
            ),
            tagline: "Gebruik van context-signalen (start, stop)",
            caption: "Omvatting van focus-behoud periode op beheersbaar signaal"
        )
    }
}

public extension PrebuiltModuleComponents {
    enum Shaping {
        public static let assisted_shaping_obedience: ModuleComponent = .init(
            concepts: [
                .obedience,
                .assisted_shaping
            ],
            format: [
                .practice
            ],
            allocation: .init(
                minutes: .init(
                    low: 15,
                    high: 60
                )
            ),
            tagline: "Gehoorzaamheid: geassisteerd vormen",
            caption: "Gedragsvorming middels lokmiddel ('gemaakte' bewegingsvormen)"
        )
    }
}

public extension PrebuiltModuleComponents {
    enum BehaviorModification {
        public static let redirection_attention: ModuleComponent = .init(
            concepts: [
                .redirection,
                .attention_retention,

                // “statische afleiding in huis” but in the probleemsituatie:
                .uncontrolled_static_distraction,

                // applying under threshold constraints
                .below_threshold,
                .near_or_at_threshold,
                .thresholds
            ],
            format: [
                .practice,
                .exercise
            ],
            allocation: .init(
                minutes: .init(
                    low: 10,
                    high: 45
                )
            ),
            tagline: "Herleiding en aandachtshakeling bij statische (aansporende) prikkeling",
            caption: "Betrokkenheid rondom afleidingen die (mogelijk-escalerende) reacties oproepen"
        )

        public static let redirection_on_rising_arousal: ModuleComponent = .init(
            concepts: [
                .redirection,
                .arousal,
                .thresholds,
                .near_or_at_threshold,

                .uncontrolled_dynamic_distraction
            ],
            format: [
                .practice,
                .exercise
            ],
            allocation: .init(
                minutes: .init(
                    low: 10,
                    high: 45
                )
            ),
            tagline: "Herleiding bij dynamische / opbouwende (aansporende) prikkeling",
            caption: "Herleiding met interval tijdens 'opbouw' om stijgende opwinding af te kunnen laten vloeien"
        )

        public static let redirection_with_potential_pressure: ModuleComponent = .init(
            concepts: [
                .redirection,
                .pressure_work,
                .social_distraction,

                .near_or_at_threshold,
                .below_threshold,
                .thresholds
            ],
            format: [
                .comprehension,
                .practice
            ],
            allocation: .init(
                minutes: .init(
                    low: 10,
                    high: 45
                )
            ),
            tagline: "Herleiding met mogelijke incorporatie druk en/of (sociale) correctie",
            caption: "Herleiding met mogelijke ondersteuning van onderdrukking richting dysfunctionele reacties (nabij of op, niet over drempelwaarde)"
        )

        public static let exercise_dynamic_static_alternation: ModuleComponent = .init(
            concepts: [
                .redirection,
                .attention_retention,

                .uncontrolled_dynamic_distraction,
                .uncontrolled_static_distraction,

                .arousal,
                .thresholds,
                .near_or_at_threshold
            ],
            format: [
                .exercise,
                .practice
            ],
            allocation: .init(
                sessions: .init(
                    low: 1,
                    high: 3
                )
            ),
            tagline: "Oefening: dynamisch-statisch afwisseling in prikkelcontext",
            caption: "Geleidelijk toewerken van actieve herleiding naar (passievere) statische posties en postie-behoud"
        )

        public static let premack_discharge_energy: ModuleComponent = .init(
            concepts: [
                .premack_principle
            ],
            format: [
                .comprehension,
                .practice,
                .demonstration
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 60
                )
            ),
            tagline: "Premack: afvloeiing van energie en opwinding bij reuring (weg van opwellende prikkel)",
            caption: "Gebruik van hoog-waarschijnlijk gedrag om lager-waarschijnlijk gedrag te versterken"
        )

        public static let capping_dynamic_to_static: ModuleComponent = .init(
            concepts: [
                .capping,
                .premack_principle
            ],
            format: [
                .comprehension,
                .practice,
                .demonstration
            ],
            allocation: .init(
                minutes: .init(
                    low: 5,
                    high: 30
                )
            ),
            tagline: "Capping: overgang dynamische beweging naar statische positie",
            caption: "Verhoging van mate controle bij gehoorzaamheid"
        )
    }
}
