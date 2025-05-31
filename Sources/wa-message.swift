import Foundation
import plate
import SwiftUI 

struct WAMessageRow: View {
    let template: WAMessageTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(template.title)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(template.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(minWidth: 200, alignment: .leading)
        .padding(.vertical, 4)
    }
}

struct WAMessageDropdown: View {
    @Binding var selected: WAMessageTemplate
    @State private var isExpanded: Bool = false

    let labelWidth: CGFloat
    let maxListHeight: CGFloat

    init(
        selected: Binding<WAMessageTemplate>,
        labelWidth: CGFloat = 200,
        maxListHeight: CGFloat = 200
    ) {
        self._selected = selected
        self.labelWidth = labelWidth
        self.maxListHeight = maxListHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selected.title)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Text(selected.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 6)
                .frame(minWidth: labelWidth, alignment: .leading)
            }
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.6), lineWidth: 2)
            )

            if isExpanded {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(WAMessageTemplate.allCases, id: \.self) { template in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selected = template
                                        isExpanded = false
                                    }
                                }) {
                                    WAMessageRow(template: template)
                                    // VStack(alignment: .leading, spacing: 2) {
                                    //     Text(template.title)
                                    //         .lineLimit(1)
                                    //         .truncationMode(.tail)

                                    //     Text(template.subtitle)
                                    //         .font(.caption)
                                    //         .foregroundColor(.secondary)
                                    //         .lineLimit(1)
                                    //         .truncationMode(.tail)
                                    // }
                                }
                                .padding(.vertical, 2)
                                .disabled((template == selected))
                            }
                        }
                    }
                    .frame(maxHeight: maxListHeight)
                }
                // .background(
                //     RoundedRectangle(cornerRadius: 8)
                //         .fill(Color(NSColor.windowBackgroundColor))
                //         .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                // )
                .offset(y: 44)
                .zIndex(1)
                .fixedSize(horizontal: false, vertical: true)
                // .padding(.vertical, 10)
                .padding(.top, 6)
            }
        }
    }
}

enum WAMessageTemplate: String, Hashable, CaseIterable {
    case called
    case calledVariation
    case repeatedCalls
    case follow

    var title: String {
        switch self {
            case .called:
                return "Called"

            case .calledVariation:
                return "Called -- Variation"

            case .repeatedCalls:
                return "Repeated Calls"

            case .follow:
                return "Generic Follow-up"
        }
    }


    var subtitle: String {
        switch self {
            case .called:
                return "Call attempt, \"do you need us?\"--check, prompt to call us"

            case .calledVariation:
                return "Call attempt, \"do you need us?\"--check"

            case .repeatedCalls:
                return "Repeated call attempts, \"do you need us?\"--check"

            case .follow:
                return "\"do you need us?\"--check"
        }
    }

    var message: String {
        switch self {
        case .called:
            return """
            Hey {client},

            Ik heb je gebeld, maar kon je niet bereiken. 

            Wil je weten of wij je kunnen helpen met het gedrag van {dog}? Bel mij dan even terug.
            
            Je kan me bereiken op dit nummer (+316 23 62 13 90).

            —Casper | Hondenmeesters
            """

        case .calledVariation:
            return """
            Hey {client},

            Ik heb je gebeld, maar kon je niet bereiken. 

            Heb je geen hulp meer nodig voor {dog}?

            —Casper | Hondenmeesters
            """

        case .repeatedCalls:
            return """
            Hey {client},

            Ik heb je enkele keren gebeld, maar kon je daarmee niet bereiken.

            Heb je geen hulp meer nodig met het gedrag van {dog}?

            —Casper | Hondenmeesters
            """

        case .follow:
            return """
            Hey {client},

            We hebben al even niet van je gehoord. 

            Heb je geen hulp meer nodig voor {dog}?

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
