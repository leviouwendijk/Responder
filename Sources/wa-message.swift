import Foundation
import plate
import SwiftUI 

struct WAMessageRow: View {
    let template: WAMessageTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(template.rawValue)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(template.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: 200, alignment: .leading)
    }
}

enum WAMessageTemplate: String, Hashable, CaseIterable {
    case called
    case calledVariation
    case repeatedCalls
    case follow

    var subtitle: String {
        switch self {
            case .called:
                return "we tried to call once, call us"

            case .calledVariation:
                return "do you need us check"

            case .repeatedCalls:
                return "we tried calling more than once, last message"

            case .follow:
                return "gauge if contact requires our help"
        }
    }

    var message: String {
        switch self {
        case .called:
            return """
            Hey {client},

            We hebben geprobeerd je te bellen over {dog} naar aanleiding van je bericht.

            Heb je onze hulp nodig? Bel ons even, dan kijken we of je hierbij kunnen helpen.

            —Casper | Hondenmeesters
            """

        case .calledVariation:
            return """
            Hey {client},

            We hebben je geprobeerd te bellen, maar kregen helaas geen gehoor. 

            Heb je nog hulp nodig met {dog}?

            —Casper | Hondenmeesters
            """

        case .repeatedCalls:
            return """
            Hey {client},

            We hebben een aantal pogingen gedaan om je te bereiken over {dog}, maar helaas zonder succes. 

            Heb jij onze hulp nog nodig voor {dog}?

            —Casper | Hondenmeesters
            """

        case .follow:
            return """
            Hey {client},

            We hebben je al even niet van je gehoord. 

            Heb je nog hulp nodig voor {dog}?

            —Casper | Hondenmeesters
            """
        }
    }

    public func replaced(client: String, dog: String) -> String {
        let syntax = PlaceholderSyntax(prepending: "{", appending: "}", repeating: 1)
        return self.message
            .replaceClientDogTemplatePlaceholders(client: client, dog: dog, placeholderSyntax: syntax)
    }
}
