import Foundation
import SwiftUI
import Contacts
import EventKit
import plate
import Economics
import Compositions
import ViewComponents
import Interfaces

struct TemplateFetchResponse: Decodable {
    let success: Bool
    let html: String
}

struct Responder: View {
    // plate
    @EnvironmentObject var vm: MailerViewModel
    @EnvironmentObject var invoiceVm: MailerAPIInvoiceVariablesViewModel

    @StateObject private var weeklyScheduleVm = WeeklyScheduleViewModel()
    @StateObject private var contactsVm = ContactsListViewModel()
    @StateObject private var apiPathVm = MailerAPISelectionViewModel()

    // Economics
    @StateObject private var quotaVm = QuotaViewModel()

    @State private var client = ""
    @State private var email = ""

    var finalEmail: String {
        email
        .commaSeparatedValuesToParsableArgument
    }

    @State private var dog = ""
    @State private var location = ""
    @State private var areaCode: String?
    @State private var street: String?
    @State private var number: String?
    @State private var localLocation = "Alkmaar"
    @State private var local = false

    var finalSubject: String {
        return subject
            .replaceClientDogTemplatePlaceholders(client: client, dog: dog)
    }

    var finalHtml: String {
        return fetchedHtml.htmlClean()
            .replaceClientDogTemplatePlaceholders(client: client, dog: dog)
    }

    private var finalHtmlContainsRawVariables: Bool {
        let ignorances = ["IMAGE_WIDTH"]
        let syntax = PlaceholderSyntax(prepending: "{", appending: "}", repeating: 2)
        return finalHtml
        .containsRawTemplatePlaceholderSyntaxes(
            ignoring: ignorances,
            placeholderSyntaxes: [syntax]
        )
    }

    private var selectedWAMessageReplaced: String {
        return selectedWAMessage.replaced(client: client, dog: dog)
    }

    private var waMessageContainsRawPlaceholders: Bool {
        return selectedWAMessageReplaced
            .containsRawTemplatePlaceholderSyntaxes()
    }

    private var emptySubjectWarning: Bool {
        return subject.isEmpty
    }

    private var emptyEmailWarning: Bool {
        return email.isEmpty
    }

    private var anyInvalidConditionsCheck: Bool {
        if (apiPathVm.selectedRoute == .template) {
            return false
        } else if (apiPathVm.selectedRoute == .custom) {
            return (finalHtmlContainsRawVariables || emptySubjectWarning || emptyEmailWarning)
        } else {
            return false
        }
    }

    func constructMailerCommand(_ includeBinaryName: Bool = false) throws -> String {
        let stateVars = StateVariables(
            invoiceId: invoiceVm.invoiceVariables.invoice_id,
            fetchableCategory: fetchableCategory,
            fetchableFile: fetchableFile,
            finalEmail: finalEmail,
            finalSubject: finalSubject,
            finalHtml: finalHtml,
            includeQuote: includeQuoteInCustomMessage
        )

        let args = MailerArguments(
            client: client,
            email: finalEmail,
            dog: dog,
            route: apiPathVm.selectedRoute,
            endpoint: apiPathVm.selectedEndpoint,
            availabilityJSON: try? weeklyScheduleVm.availabilityJSON(),
            needsAvailability: apiPathVm.endpointNeedsAvailabilityVariable,
            stateVariables: stateVars
        )
        return try args.string(includeBinaryName)
    }

    func updateCommandInViewModel(newValue: String) {
        vm.sharedMailerCommandCopy = newValue
    }

    @State private var searchQuery = ""
    @State private var contacts: [CNContact] = []
    @State private var selectedContact: CNContact?

    var filteredContacts: [CNContact] {
        if searchQuery.isEmpty { return contacts }
        let normalizedQuery = searchQuery.normalizedForClientDogSearch
        return contacts.filter {
            $0.givenName.normalizedForClientDogSearch.contains(normalizedQuery) ||
            $0.familyName.normalizedForClientDogSearch.contains(normalizedQuery) ||
            (($0.emailAddresses.first?.value as String?)?.normalizedForClientDogSearch.contains(normalizedQuery) ?? false)
        }
    }

    @State private var showSuccessBanner = false
    @State private var successBannerMessage = ""

    @State private var isSendingEmail = false

    @State private var bannerColor: Color = .gray
    @State private var httpStatus: Int?

    @State private var fetchableCategory = ""
    @State private var fetchableFile = ""

    @State private var fetchedHtml: String = ""
    @State private var subject: String = ""

    @State private var includeQuoteInCustomMessage = false
    @State private var showErrorPane = false

    @State private var selectedWAMessage: WAMessageTemplate = .called

    private var clientIdentifier: String {
        let c = client.isEmpty ? "{client}" : client
        let d = dog.isEmpty ? "{dog}": dog
        let e = email.isEmpty ? "{email}" : email

        let allEmpty = (client.isEmpty && dog.isEmpty && email.isEmpty)

        let sequence = "\(c) | \(d) (\(e))"
        let fallback = "no contact specified"

        return allEmpty ? fallback : sequence
    }

    var body: some View {
        HStack {
            MailerAPIPathSelectionView(viewModel: apiPathVm)
            .frame(width: 500)

            VariablesView(
                contactsVm:        contactsVm,
                apiPathVm:         apiPathVm,
                invoiceVm:         invoiceVm,

                local:              $local,
                selectedContact:    $selectedContact,
                client:             $client,
                dog:                $dog,
                email:              $email,
                location:           $location,
                areaCode:           $areaCode,
                street:             $street,
                number:             $number,
                localLocation:      $localLocation,

                fetchableCategory:  $fetchableCategory,
                fetchableFile:      $fetchableFile,

                subject:            $subject,
                fetchedHtml:        $fetchedHtml,

                selectedWAMessage:  $selectedWAMessage,

                anyInvalidConditionsCheck:   anyInvalidConditionsCheck,
                emptyEmailWarning:           emptyEmailWarning,
                emptySubjectWarning:         emptySubjectWarning,
                finalHtmlContainsRawVariables: finalHtmlContainsRawVariables,
                selectedWAMessageReplaced:     selectedWAMessageReplaced,
                waMessageContainsRawPlaceholders: waMessageContainsRawPlaceholders,

                sendMailerEmail:   { try sendMailerEmail() },
                clearContact:      { clearContact() },
            )
            .equatable()
            .frame(minWidth: 500)


            Divider()

            ValuesPaneView(
                apiPathVm:           apiPathVm,
                weeklyScheduleVm:    weeklyScheduleVm,
                quotaVm:             quotaVm,

                subject:             $subject,
                fetchedHtml:         $fetchedHtml,
                includeQuoteInCustomMessage: $includeQuoteInCustomMessage,

                showSuccessBanner:    $showSuccessBanner,
                successBannerMessage: $successBannerMessage,
                bannerColor:          $bannerColor,
                isSendingEmail:       $isSendingEmail,

                anyInvalidConditionsCheck:    anyInvalidConditionsCheck,
                emptySubjectWarning:          emptySubjectWarning,
                finalHtmlContainsRawVariables: finalHtmlContainsRawVariables,

                clientIdentifier:              clientIdentifier,

                sendMailerEmail:    { try sendMailerEmail() }
            )
            .equatable()
            .frame(minWidth: 500)
        }
        .padding()
    }

    private func cleanThisView() {
        clearContact()
        if includeQuoteInCustomMessage {
            includeQuoteInCustomMessage = false
        }
    }
    
    private func sendMailerEmail() throws {
        vm.mailerOutput = ""

        withAnimation { isSendingEmail = true }

        let arguments = try constructMailerCommand(false)

        let argsWithBinary = try constructMailerCommand(true)
        updateCommandInViewModel(newValue: argsWithBinary)

        DispatchQueue.global(qos: .userInitiated).async {
            let home = Home.string()
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
            proc.arguments = ["-c", "source ~/dotfiles/.vars.zsh && \(home)/sbm-bin/mailer \(arguments)"]

            let outPipe = Pipe(), errPipe = Pipe()
            proc.standardOutput = outPipe
            proc.standardError  = errPipe

            // whenever stdout or stderr arrives, append it to mailerOutput
            func install(_ handle: FileHandle) {
                handle.readabilityHandler = { h in
                    let data = h.availableData
                    guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
                    DispatchQueue.main.async {
                        vm.mailerOutput += str
                    }
                }
            }
            install(outPipe.fileHandleForReading)
            install(errPipe.fileHandleForReading)

            do {
                try proc.run()
            } catch {
                DispatchQueue.main.async {
                    vm.mailerOutput += "launch failed: \(error.localizedDescription)\n"
                }
            }

            proc.waitUntilExit()

            DispatchQueue.main.async {
                // stop spinner
                withAnimation { isSendingEmail = false }

                // banner
                successBannerMessage = proc.terminationStatus == 0
                  ? "mailer completed successfully."
                  : "mailer exited with code \(proc.terminationStatus)."
                showSuccessBanner = true

                // color mechanism:
                // 1) try grab the HTTP status line
                if let codeStr = vm.mailerOutput.firstCapturedGroup(
                     pattern: #"HTTP Status Code:\s*(\d{3})"#,
                     options: .caseInsensitive
                   ),
                   let code = Int(codeStr)
                {
                  httpStatus  = code
                  bannerColor = (200..<300).contains(code) ? .green : .red
                }
                // 2) grab the *last* {...} JSON
                if let jsonRange = vm.mailerOutput.range(
                     of: #"\{[\s\S]*\}"#,
                     options: [.regularExpression, .backwards]
                   )
                {
                  let blob = String(vm.mailerOutput[jsonRange])
                  if let d    = blob.data(using: .utf8),
                     let resp = try? JSONDecoder().decode(APIError.self, from: d)
                  {
                    // override color/message based on server response
                    bannerColor        = resp.success ? .green : .red
                    successBannerMessage = resp.message

                    if resp.success {
                        cleanThisView()
                    }
                  }
                }
                // end of color mechanism

                // also parse / extract html body if it was a template call:
                if (apiPathVm.isTemplateFetch) {
                    if let jsonRange = vm.mailerOutput.range(
                        of: #"\{[\s\S]*\}"#, 
                        options: [.regularExpression, .backwards]
                        )
                    {
                    let blob = String(vm.mailerOutput[jsonRange])
                    if let data = blob.data(using: .utf8),
                        let resp = try? JSONDecoder().decode(TemplateFetchResponse.self, from: data),
                        resp.success
                        {
                            fetchedHtml = resp.html
                        }
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showSuccessBanner = false }
                }
            }
        }
    }

    private func clearContact() {
        client = ""
        email = ""
        dog = ""
        location = ""
        areaCode = ""
        street = ""
        number = ""
        selectedContact = nil
    }
}
