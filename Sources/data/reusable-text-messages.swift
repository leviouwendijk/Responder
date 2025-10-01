import Foundation
import plate
import Structures

let messages = [
    ReusableTextMessageObject(
        key: "called_variation_i",
        object: ReusableTextMessage(
            title: "Called -- Variation I",
            details: "Call attempt, \"do you need us?\"--check, prompt to call us",
            content: .init(
                subject: "",
                message: """
                Hey {client},
                
                Ik heb je gebeld, maar kon je niet bereiken. 
                
                Graag spreek ik je over {dog}. Bel mij even terug wanneer het jou uitkomt.
                
                Je kan me bereiken op dit nummer (+316 23 62 13 90).
                
                —Casper | Hondenmeesters
                """
            )
        )
    ),
    ReusableTextMessageObject(
        key: "losing",
        object: ReusableTextMessage(
            title: "Losing",
            details: "Call attempt, \"do you need us?\"--check",
            content: .init(
                subject: "",
                message: """
                Hey {client},
                
                Ik heb je gebeld, maar kon je niet bereiken. 
                
                Heb je geen hulp meer nodig voor {dog}?
                
                —Casper | Hondenmeesters
                """
            )
        )
    ),
    ReusableTextMessageObject(
        key: "repeated_calls",
        object: ReusableTextMessage(
            title: "Repeated Calls",
            details: "Repeated call attempts, \"do you need us?\"--check",
            content: .init(
                subject: "",
                message: """
                Hey {client},
                
                Ik heb je enkele keren gebeld, maar kon je daarmee niet bereiken.
                
                Heb je geen hulp meer nodig met het gedrag van {dog}?
                
                —Casper | Hondenmeesters
                """
            )
        )
    ),
    ReusableTextMessageObject(
        key: "repeated_calls_variation_i",
        object: ReusableTextMessage(
            title: "Repeated Calls - Variation I",
            details: "Repeated call attempts, \"do you need us?\"--check",
            content: .init(
                subject: "",
                message: """
                Hey {client},
                
                Ik heb je enkele keren gebeld, maar kon je daarmee niet bereiken.
                
                Als je onze hulp nog nodig hebt, laat het ons dan even weten.
                
                —Casper | Hondenmeesters
                """
            )
        )
    ),
    ReusableTextMessageObject(
        key: "follow",
        object: ReusableTextMessage(
            title: "Generic Follow-up",
            details: "\"do you need us?\"--check",
            content: .init(
                subject: "",
                message: """
                Hey {client},
                
                We hebben al even niet van je gehoord. 
                
                Heb je geen hulp meer nodig voor {dog}?
                
                —Casper | Hondenmeesters
                """
            )
        )
    ),
    ReusableTextMessageObject(
        key: "contract",
        object: ReusableTextMessage(
            title: "Contractual agreement",
            details: "\"confirm agreement to chosen service\"",
            content: .init(
                subject: "",
                message: """
                Beste {client},
                
                Graag ontvangen wij je schriftelijke bevestiging van het volgende ("ik ga akkoord" volstaat):
                
                Afname van het volgende aanbod:
                
                    Dienst: {deliverable}
                    Details: {detail}
                    Prijs (incl. btw): € {price}
                
                    Conform onze algemene voorwaarden (https://hondenmeesters.nl/algemene-voorwaarden.html) en privacy beleid (https://hondenmeesters.nl/privacy-beleid.html).
                
                Bevestig eenvoudig door “Akkoord” te antwoorden.  
                
                Mocht je vragen of aanmerkingen hebben, leg deze dan gerust aan ons voor.
                
                Hartelijke groet,
                Het Hondenmeesters Team
                """
            )
        )
    ),
]
