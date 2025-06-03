import Foundation
import SwiftUI
import Contacts
import EventKit
import plate
import Economics

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
        // let pattern = #"\{\{\s*(?!IMAGE_WIDTH\b)[^}]+\s*\}\}"#
        // return finalHtml.range(of: pattern, options: .regularExpression) != nil
        let ignorances = ["IMAGE_WIDTH"]
        let syntax = PlaceholderSyntax(prepending: "{", appending: "}", repeating: 2)
        return finalHtml
            .containsRawTemplatePlaceholderSyntaxes(
                ignoring: ignorances,
                placeholderSyntaxes: [syntax]
            )

            // .containsRawTemplatePlaceholderSyntaxes(ignoring: ignorances)
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
        // if custom/template, be more tolerant about starting mailer
        if (apiPathVm.selectedRoute == .template) {
            return false
        // if custom/.., check the html body for raw variables
        } else if (apiPathVm.selectedRoute == .custom) {
            return (finalHtmlContainsRawVariables || emptySubjectWarning || emptyEmailWarning)
        // otherwise, check for parsing errs in client / dog names in primary templates
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

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

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

    @StateObject private var waMessageNotifier: NotificationBannerController = NotificationBannerController()

    @StateObject private var localPdfNotifier: NotificationBannerController = NotificationBannerController()
    @StateObject private var combinedPdfNotifier: NotificationBannerController = NotificationBannerController()
    @StateObject private var remotePdfNotifier: NotificationBannerController = NotificationBannerController()

    @StateObject private var copyQuotaNotifier: NotificationBannerController = NotificationBannerController(
        contents: [NotificationBannerControllerContents(title: "copied", style: .success, message: "output copied")],
        addingDefaultContents: true
    )

    private var clientIdentifier: String {
        return "\(client) | \(dog) (\(email))"
    }

    var body: some View {
        HStack {
            MailerAPIPathSelectionView(viewModel: apiPathVm)
            .frame(width: 500)

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
                        // TextField("invoice id (integer)", text: $invoiceId)
                        //     .textFieldStyle(RoundedBorderTextFieldStyle())
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

            Divider()

            VStack {
                if apiPathVm.selectedRoute == .custom {
                    VStack(alignment: .leading) {

                        TextField("Subject", text: $subject)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        if (anyInvalidConditionsCheck && emptySubjectWarning) {
                            NotificationBanner(
                                type: .info,
                                message: "Empty subject"
                            )
                        }

                        Text("Template HTML").bold()

                        CodeEditorContainer(text: $fetchedHtml)

                        if (anyInvalidConditionsCheck && finalHtmlContainsRawVariables) {
                            NotificationBanner(
                                type: .warning,
                                message: "Raw html variables still in your message"
                            )
                        }

                        HStack {
                            StandardButton(
                                type: .clear, 
                                title: "Clear HTML", 
                                subtitle: "clears fetched html"
                            ) {
                                fetchedHtml = ""
                            }

                            Spacer()

                            if apiPathVm.selectedRoute == .custom {
                                StandardToggle(
                                    style: .switch,
                                    isOn: $includeQuoteInCustomMessage,
                                    title: "Include quote",
                                    subtitle: nil,
                                    width: 150
                                )
                            }
                        }
                        .padding()
                    }
                    .padding()
                } else if apiPathVm.selectedRoute == .quote {
                    VStack(alignment: .leading, spacing: 12) {
                        // 1) “Kilometers” field
                        StandardTextField(
                            "kilometers",
                            text: Binding<String>(
                                get:  { quotaVm.customQuotaInputs.travelCost.kilometers },
                                set:  { newValue in
                                    quotaVm.customQuotaInputs.travelCost.kilometers = newValue
                                }
                            ),
                            placeholder: "45"
                        )

                        // 2) Prognosis / Local
                        HStack {
                            StandardTextField(
                                "prognosis",
                                text: Binding<String>(
                                    get:  { quotaVm.customQuotaInputs.prognosis.count },
                                    set:  { newValue in
                                        quotaVm.customQuotaInputs.prognosis.count = newValue
                                    }
                                ),
                                placeholder: "5"
                            )
                            StandardTextField(
                                "local",
                                text: Binding<String>(
                                    get:  { quotaVm.customQuotaInputs.prognosis.local },
                                    set:  { newValue in
                                        quotaVm.customQuotaInputs.prognosis.local = newValue
                                    }
                                ),
                                placeholder: "4"
                            )
                        }

                        // 3) Suggestion / Local
                        HStack {
                            StandardTextField(
                                "suggestion",
                                text: Binding<String>(
                                    get:  { quotaVm.customQuotaInputs.suggestion.count },
                                    set:  { newValue in
                                        quotaVm.customQuotaInputs.suggestion.count = newValue
                                    }
                                ),
                                placeholder: "3"
                            )
                            StandardTextField(
                                "local",
                                text: Binding<String>(
                                    get:  { quotaVm.customQuotaInputs.suggestion.local },
                                    set:  { newValue in
                                        quotaVm.customQuotaInputs.suggestion.local = newValue
                                    }
                                ),
                                placeholder: "2"
                            )
                        }

                        // 4) Base
                        StandardTextField(
                            "base",
                            text: Binding<String>(
                                get:  { quotaVm.customQuotaInputs.base },
                                set:  { newValue in
                                    quotaVm.customQuotaInputs.base = newValue
                                }
                            ),
                            placeholder: "350"
                        )

                        // 5) Travel‐cost fields
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Travel Cost Inputs").bold()
                            HStack {
                                StandardTextField(
                                    "speed",
                                    text: Binding<String>(
                                        get:  { quotaVm.customQuotaInputs.travelCost.speed },
                                        set:  { newValue in
                                            quotaVm.customQuotaInputs.travelCost.speed = newValue
                                        }
                                    ),
                                    placeholder: "80.0"
                                )
                                StandardTextField(
                                    "rate/travel",
                                    text: Binding<String>(
                                        get:  { quotaVm.customQuotaInputs.travelCost.rates.travel },
                                        set:  { newValue in
                                            quotaVm.customQuotaInputs.travelCost.rates = TravelCostRatesInputs(
                                                travel: newValue,
                                                time: quotaVm.customQuotaInputs.travelCost.rates.time
                                            )
                                        }
                                    ),
                                    placeholder: "0.25"
                                )
                                StandardTextField(
                                    "rate/time",
                                    text: Binding<String>(
                                        get:  { quotaVm.customQuotaInputs.travelCost.rates.time },
                                        set:  { newValue in
                                            quotaVm.customQuotaInputs.travelCost.rates = TravelCostRatesInputs(
                                                travel: quotaVm.customQuotaInputs.travelCost.rates.travel,
                                                time: newValue
                                            )
                                        }
                                    ),
                                    placeholder: "105"
                                )
                            }
                        }
                        .padding(.top, 8)

                        // 6) Decide what to show:
                        if quotaVm.isLoading {
                            ProgressView("Computing quota…")
                                .padding(.top, 16)
                        }
                        else if let quota = quotaVm.loadedQuota {
                            QuotaTierListView(quota: quota)
                                .padding(.top, 16)

                            HStack(spacing: 45) {
                                Spacer()

                                StandardNotifyingButton(
                                    type: .copy,
                                    title: "settings",
                                    action: {
                                        if let table = quotaVm.loadedQuota?.quotaSummary(clientIdentifier: clientIdentifier) {
                                            copyToClipboard(table)
                                            copyQuotaNotifier.setAndNotify(to: "copied")
                                        } else {
                                            copyQuotaNotifier.setAndNotify(to: "error")
                                        }
                                    },
                                    notifier: copyQuotaNotifier,
                                    notifierPosition: .under
                                )

                                VStack {
                                    StandardButton(
                                        type: .execute,
                                        title: "Render Local",
                                        action: {
                                            do {
                                                withAnimation {
                                                    localPdfNotifier.show = false
                                                }

                                                try renderTier(quota: quota, for: .local)

                                                localPdfNotifier.message = "quota pdf rendered"
                                                localPdfNotifier.style = .success
                                                withAnimation {
                                                    localPdfNotifier.show = true
                                                }

                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                    withAnimation { 
                                                        localPdfNotifier.show = false
                                                    }
                                                }
                                            } catch {
                                                withAnimation {
                                                    localPdfNotifier.show = false
                                                }

                                                localPdfNotifier.message = "render failed: \(error)"
                                                localPdfNotifier.style = .error
                                                withAnimation {
                                                    localPdfNotifier.show = true
                                                }

                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                    withAnimation { 
                                                        localPdfNotifier.show = false 
                                                    }
                                                }
                                            }
                                        }
                                    )
                                    .disabled((quotaVm.loadedQuota == nil))
                                    .padding(.top, 8)

                                    NotificationBanner(
                                        type: localPdfNotifier.style,
                                        message: localPdfNotifier.message
                                    )
                                    .hide(when: localPdfNotifier.hide)
                                }

                                VStack {
                                    StandardButton(
                                        type: .execute,
                                        title: "Render Combined",
                                        action: {
                                            do {
                                                withAnimation {
                                                    combinedPdfNotifier.show = false
                                                }

                                                try renderTier(quota: quota, for: .combined)

                                                combinedPdfNotifier.message = "quota pdf rendered"
                                                combinedPdfNotifier.style = .success
                                                withAnimation {
                                                    combinedPdfNotifier.show = true
                                                }

                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                    withAnimation { 
                                                        combinedPdfNotifier.show = false
                                                    }
                                                }
                                            } catch {
                                                withAnimation {
                                                    combinedPdfNotifier.show = false
                                                }

                                                combinedPdfNotifier.message = "render failed: \(error)"
                                                combinedPdfNotifier.style = .error
                                                withAnimation {
                                                    combinedPdfNotifier.show = true
                                                }

                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                    withAnimation { 
                                                        combinedPdfNotifier.show = false 
                                                    }
                                                }
                                            }
                                        }
                                    )
                                    .disabled((quotaVm.loadedQuota == nil))
                                    .padding(.top, 8)

                                    NotificationBanner(
                                        type: combinedPdfNotifier.style,
                                        message: combinedPdfNotifier.message
                                    )
                                    .hide(when: combinedPdfNotifier.hide)
                                }

                                VStack {
                                    StandardButton(
                                        type: .execute,
                                        title: "Render Remote",
                                        action: {
                                            do {
                                                withAnimation {
                                                    remotePdfNotifier.show = false
                                                }

                                                try renderTier(quota: quota, for: .remote)

                                                remotePdfNotifier.message = "quota pdf rendered"
                                                remotePdfNotifier.style = .success
                                                withAnimation {
                                                    remotePdfNotifier.show = true
                                                }

                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                    withAnimation { 
                                                        remotePdfNotifier.show = false
                                                    }
                                                }
                                            } catch {
                                                withAnimation {
                                                    remotePdfNotifier.show = false
                                                }

                                                remotePdfNotifier.message = "render failed: \(error)"
                                                remotePdfNotifier.style = .error
                                                withAnimation {
                                                    remotePdfNotifier.show = true
                                                }

                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                    withAnimation { 
                                                        remotePdfNotifier.show = false 
                                                    }
                                                }
                                            }
                                        }
                                    )
                                    .disabled((quotaVm.loadedQuota == nil))
                                    .padding(.top, 8)

                                    NotificationBanner(
                                        type: remotePdfNotifier.style,
                                        message: remotePdfNotifier.message
                                    )
                                    .hide(when: remotePdfNotifier.hide)
                                }
                                .padding(.trailing, 40)
                            }
                        }
                        else {
                            NotificationBanner(
                                type: .info,
                                message: "Enter quote values above"
                            )
                            .padding(.top, 16)
                        }
                    }
                    .padding()
                } else {

                    if apiPathVm.endpointNeedsAvailabilityVariable {
                        VStack(alignment: .leading, spacing: 8) {
                            WeeklyScheduleView(viewModel: weeklyScheduleVm)
                        }
                        .padding(.vertical, 8)
                    }
                }

                Spacer()

                if showSuccessBanner {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: bannerColor == .green
                                    ? "checkmark.circle.fill"
                                    : "xmark.octagon.fill")
                            .foregroundColor(.white)
                            Text(successBannerMessage)
                            .foregroundColor(.white)
                        }
                        .padding()
                        .background(bannerColor)
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom))
                    }
                    .animation(.easeInOut, value: showSuccessBanner)
                } else {
                    if isSendingEmail {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Sending...")
                        }
                        .padding(.bottom, 10)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: isSendingEmail)
                    }

                    if apiPathVm.selectedRoute == .invoice && apiPathVm.selectedEndpoint == .expired {
                        NotificationBanner(
                            type: .warning,
                            message: "You are sending an overdue reminder"
                        )
                    }

                    HStack {
                        StandardEscapableButton(
                            type: .execute, 
                            title: "Run mailer", 
                            cancelTitle: "Do not run mailer yet", 
                            subtitle: "Starts mailer background process"
                        ) {
                            do {
                                try sendMailerEmail()
                            } catch {
                                print(error)
                            }
                        }
                        .disabled(
                            isSendingEmail || 
                            anyInvalidConditionsCheck || 
                            apiPathVm.routeOrEndpointIsNil()
                        )
                    }
                    .padding(.top, 10)

                    HStack {
                        NotificationBanner(
                            type: .warning,
                            message: "No endpoint selected"
                        )
                        .hide(when: !apiPathVm.routeOrEndpointIsNil())
                    }
                }
            }
            .frame(minWidth: 500)
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func cleanThisView() {
        clearContact()
        if includeQuoteInCustomMessage {
            includeQuoteInCustomMessage = false
        }
        // invoiceId = ""
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

                // auto‐dismiss banner
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

struct StateVariables {
    let invoiceId: String
    let fetchableCategory: String
    let fetchableFile: String
    let finalEmail: String
    let finalSubject: String
    let finalHtml: String
    let includeQuote: Bool
} 

enum ArgError: Error {
    case missingArgumentComponents
}

struct MailerArguments {
    let client: String
    let email: String
    let dog: String
    let route: MailerAPIRoute?
    let endpoint: MailerAPIEndpoint?
    let availabilityJSON: String?
    let needsAvailability: Bool
    let stateVariables: StateVariables

    func string(_ includeBinaryName: Bool = false) throws -> String {
        guard let r = route, let e = endpoint else {
            throw ArgError.missingArgumentComponents
        }

        var components: [String] = []

        if includeBinaryName {
            components.insert("mailer", at: 0)
        }

        switch r {
        case .invoice:
            components.append("invoice \(stateVariables.invoiceId) --responder")
            if e == .expired {
                components.append("--expired")
            }

        case .template: 
            components.append("template-api \(stateVariables.fetchableCategory) \(stateVariables.fetchableFile)")

        case .custom:
            components.append("custom-message --email \"\(stateVariables.finalEmail)\" --subject \"\(stateVariables.finalSubject)\" --body \"\(stateVariables.finalHtml)\"")

            if  stateVariables.includeQuote {
                components.append(" --quote")
            }

        default:
            components.append(r.rawValue)
            components.append("--client \"\(client)\"")
            components.append("--email \"\(email)\"")
            components.append("--dog \"\(dog)\"")

            if !(e == .issue || e == .confirmation || e == .review) {
                components.append("--\(e.rawValue)")
            }

            if needsAvailability {
                components.append("--availability-json '\(availabilityJSON ?? "")'")
            }
        }

        let compacted = components.compactMap { $0 }
        return compacted.joined(separator: " ")
    }
}

func executeMailer(_ arguments: String) throws {
    do {
        let home = Home.string()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh") // Use Zsh directly
        process.arguments = ["-c", "source ~/dotfiles/.vars.zsh && \(home)/sbm-bin/mailer \(arguments)"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let outputString = String(data: outputData, encoding: .utf8) ?? ""
        let errorString = String(data: errorData, encoding: .utf8) ?? ""

        if process.terminationStatus == 0 {
            print("mailer executed successfully:\n\(outputString)")
        } else {
            print("Error running mailer:\n\(errorString)")
            throw NSError(domain: "mailer", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorString])
        }
    } catch {
        print("Error running commands: \(error)")
        throw error
    }
}

