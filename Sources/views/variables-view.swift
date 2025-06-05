import Foundation
import SwiftUI
import plate
import Interfaces
import ViewComponents
import Compositions
import Contacts

struct VariablesView: View, @preconcurrency Equatable {
    @ObservedObject var contactsVm: ContactsListViewModel
    @ObservedObject var apiPathVm: MailerAPISelectionViewModel
    @ObservedObject var invoiceVm: MailerAPIInvoiceVariablesViewModel

    @StateObject private var waMessageNotifier: NotificationBannerController = NotificationBannerController()

    @Binding var local: Bool
    @Binding var selectedContact: CNContact?
    @Binding var client: String
    @Binding var dog: String
    @Binding var email: String
    @Binding var location: String
    @Binding var areaCode: String?
    @Binding var street: String?
    @Binding var number: String?
    @Binding var localLocation: String

    @Binding var fetchableCategory: String
    @Binding var fetchableFile: String

    @Binding var subject: String
    @Binding var fetchedHtml: String

    @Binding var selectedWAMessage: WAMessageTemplate

    let anyInvalidConditionsCheck: Bool
    let emptyEmailWarning: Bool
    let emptySubjectWarning: Bool
    let finalHtmlContainsRawVariables: Bool
    let selectedWAMessageReplaced: String
    let waMessageContainsRawPlaceholders: Bool

    let sendMailerEmail: () throws -> Void
    let clearContact: () -> Void

    static func == (lhs: VariablesView, rhs: VariablesView) -> Bool {
        return lhs.local                                       == rhs.local &&
               lhs.selectedContact == rhs.selectedContact       &&
               lhs.client                                      == rhs.client &&
               lhs.dog                                         == rhs.dog &&
               lhs.email                                       == rhs.email &&
               lhs.location                                    == rhs.location &&
               lhs.areaCode                                    == rhs.areaCode &&
               lhs.street                                      == rhs.street &&
               lhs.number                                      == rhs.number &&
               lhs.localLocation                               == rhs.localLocation &&
               lhs.fetchableCategory                           == rhs.fetchableCategory &&
               lhs.fetchableFile                               == rhs.fetchableFile &&
               lhs.subject                                     == rhs.subject &&
               lhs.fetchedHtml                                 == rhs.fetchedHtml &&
               lhs.selectedWAMessage                           == rhs.selectedWAMessage &&
               lhs.anyInvalidConditionsCheck                   == rhs.anyInvalidConditionsCheck &&
               lhs.emptyEmailWarning                           == rhs.emptyEmailWarning &&
               lhs.emptySubjectWarning                         == rhs.emptySubjectWarning &&
               lhs.finalHtmlContainsRawVariables               == rhs.finalHtmlContainsRawVariables &&
               lhs.selectedWAMessageReplaced                   == rhs.selectedWAMessageReplaced &&
               lhs.waMessageContainsRawPlaceholders            == rhs.waMessageContainsRawPlaceholders
    }

    var body: some View {
        VStack {
            VStack {
                if !(apiPathVm.selectedRoute == .template || apiPathVm.selectedRoute == .invoice) {
                    HStack {

                        Spacer()

                        StandardToggle(
                            style: .switch,
                            isOn: $local,
                            title: "Local Location",
                            subtitle: nil
                        )
                    }
                }
            }
            .frame(maxWidth: 350)

            Divider()

            VStack(alignment: .leading) {
                if !(apiPathVm.selectedRoute == .template || apiPathVm.selectedRoute == .invoice) {
                    ContactsListView(
                        viewModel: contactsVm,
                        maxListHeight: 200,
                        onSelect: { contact in
                            clearContact()
                            selectedContact = contact
                            let split = try splitClientDog(from: contact.givenName)
                            client = split.name
                            dog    = split.dog
                            email  = contact.emailAddresses.first?.value as String? ?? ""
                            if let addr = contact.postalAddresses.first?.value {
                                location = addr.city
                                street   = addr.street
                                areaCode = addr.postalCode
                            }

                            // extra clearance logic, wa related:
                            if !selectedWAMessageReplaced.containsRawTemplatePlaceholderSyntaxes() {
                                // showWAMessageNotification = false
                                waMessageNotifier.show = false
                            }

                        },
                        onDeselect: {
                            clearContact()
                        }
                    )
                    .frame(maxWidth: 350)
                }

                Text("Mailer Arguments").bold()
                
                if apiPathVm.selectedRoute == .template {
                    HStack {
                        TextField("route", text: $fetchableCategory)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Text("/")

                        TextField("endpoint", text: $fetchableFile)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                do {
                                    try sendMailerEmail()
                                } catch {
                                    print(error)
                                }
                            }
                    }
                } else if apiPathVm.selectedRoute == .invoice {

                    VStack {
                        HStack {
                            ThrowingEscapableButton(
                                type: .load,
                                title: "Get data",
                                action: invoiceVm.getCurrentInvoiceRender
                            )
                            
                            ThrowingEscapableButton(
                                type: .load,
                                title: "Render invoice",
                                action: invoiceVm.renderDataFromInvoiceId
                            )

                        }

                        MailerAPIInvoiceVariablesView(viewModel: invoiceVm)
                    }
                } else {
                    TextField("Client (variable: \"{{name}}\"", text: $client)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Email (accepts comma-separated values)", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    if (anyInvalidConditionsCheck && emptyEmailWarning) {
                        NotificationBanner(
                            type: .info,
                            message: "No email specified"
                        )
                    }
                    
                    TextField("Dog (variable: \"{{dog}}\"", text: $dog)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Location", text: Binding(
                        get: { local ? localLocation : location },
                        set: { location = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Area Code", text: Binding(
                        get: { local ? "" : (areaCode ?? "") },
                        set: { areaCode = local ? nil : ($0.isEmpty ? nil : $0) }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Street", text: Binding(
                        get: { local ? "" : (street ?? "") },
                        set: { street = local ? nil : ($0.isEmpty ? nil : $0) }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Number", text: Binding(
                        get: { local ? "" : (number ?? "") },
                        set: { number = local ? nil : ($0.isEmpty ? nil : $0) }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    VStack {
                        HStack {
                            StandardButton(
                                type: .clear, 
                                title: "Clear contact", 
                                subtitle: "clears contact fields"
                            ) {
                                clearContact()
                            }

                            Spacer()
                        }
                        .frame(maxWidth: 350)

                        VStack {
                            // SectionTitle(title: "WhatsApp Message")
                            Divider()

                            HStack {
                                WAMessageDropdown(selected: $selectedWAMessage)

                                StandardButton(
                                    type: .execute, 
                                    title: "WA message", 
                                    subtitle: ""
                                ) {
                                    if !waMessageContainsRawPlaceholders {
                                        withAnimation {
                                            waMessageNotifier.show = false
                                        }

                                        selectedWAMessageReplaced
                                            .clipboard()

                                        waMessageNotifier.message = "WA message copied"
                                        waMessageNotifier.style = .success
                                        withAnimation {
                                            waMessageNotifier.show = true
                                        }

                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            withAnimation { 
                                                waMessageNotifier.show = false
                                            }
                                        }
                                    } else {
                                        waMessageNotifier.style = .error
                                        waMessageNotifier.message = "WA message contains raw placeholders"
                                        withAnimation {
                                            waMessageNotifier.show = true
                                        }
                                    }
                                }
                                .disabled(selectedWAMessageReplaced.containsRawTemplatePlaceholderSyntaxes())

                                Spacer()
                            }
                            .frame(maxWidth: 350)

                            NotificationBanner(
                                type: waMessageNotifier.style,
                                message: waMessageNotifier.message
                            )
                            .zIndex(2)
                            .hide(when: waMessageNotifier.hide)
                        }
                    }
                }
            }
            .frame(minHeight: 600)
            .padding()
        }
        .frame(width: 400)
    }
}
