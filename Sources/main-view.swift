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
        return finalHtml.containsRawTemplatePlaceholderSyntaxes(ignoring: ignorances)
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

    @State private var showWAMessageNotification: Bool = false
    @State private var waMessageNotificationStyle: NotificationBannerType = .info
    @State private var waMessageNotificationContents: String = ""

    @State private var base: String = "350"
    @State private var kilometers: String = ""
    @State private var prognosis: (String, String) = ("5", "4") // count -- local
    @State private var suggestion: (String, String) = ("3", "2")
    @State private var timeRate: String = "105"
    @State private var travelRate: String = "0.25"
    @State private var speed: String = "80"

    // struct PreparedQuotaInputs {
    //     let kilometers: Double
    //     let prognosis: (Int, Int)
    //     let suggestion: (Int, Int)
    //     let base: Double
    // }

    // private var quotaInputs: PreparedQuotaInputs {
    //     return PreparedQuotaInputs(
    //         kilometers: Double(kilometerString) ?? 0.0,
    //         prognosis: (Int(prognosis) ?? 0,Int(prognosisLocal) ?? 0),
    //         suggestion: (Int(suggestion) ?? 0,Int(suggestionLocal) ?? 0),
    //         base: Double(base) ?? 0.0
    //     )
    // }

    // private func tryQuota() throws -> CustomQuota {
    //     return try quota(
    //         kilometers: quotaInputs.kilometers,
    //         prognosis: quotaInputs.prognosis,
    //         suggestion: quotaInputs.suggestion,
    //         base: quotaInputs.base
    //     )
    // }

    @State private var loadedQuota: CustomQuota? = nil
    @State private var isLoadingQuota = false

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
                                    showWAMessageNotification = false
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
                                                showWAMessageNotification = false
                                            }

                                            selectedWAMessageReplaced
                                                .clipboard()

                                            waMessageNotificationContents = "WA message copied"
                                            waMessageNotificationStyle = .success
                                            withAnimation {
                                                showWAMessageNotification = true
                                            }

                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                withAnimation { 
                                                    showWAMessageNotification = false 
                                                }
                                            }
                                        } else {
                                            waMessageNotificationStyle = .error
                                            waMessageNotificationContents = "WA message contains raw placeholders"
                                            withAnimation {
                                                showWAMessageNotification = true
                                            }
                                        }
                                    }
                                    .disabled(selectedWAMessageReplaced.containsRawTemplatePlaceholderSyntaxes())

                                    Spacer()
                                }
                                .frame(maxWidth: 350)

                                // if showWAMessageNotification {
                                    NotificationBanner(
                                        type: waMessageNotificationStyle,
                                        message: waMessageNotificationContents
                                    )
                                    .zIndex(2)
                                    .hide(when: !showWAMessageNotification)
                                // }
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
                            text: $kilometers,
                            placeholder: "45"
                        )
                        .onSubmit {
                            convertQuotaInputs()
                        }

                        // 2) Prognosis / Local
                        HStack {
                            StandardTextField(
                                "prognosis",
                                text: Binding<String>(
                                    get:  { prognosis.0 },
                                    set:  { prognosis.0 = $0 }
                                ),
                                placeholder: "5"
                            )
                            .onSubmit {
                                convertQuotaInputs()
                            }

                            StandardTextField(
                                "local",
                                text: Binding<String>(
                                    get:  { prognosis.1 },
                                    set:  { prognosis.1 = $0 }
                                ),
                                placeholder: "4"
                            )
                            .onSubmit {
                                convertQuotaInputs()
                            }
                        }

                        // 3) Suggestion / Local
                        HStack {
                            StandardTextField(
                                "suggestion",
                                text: Binding<String>(
                                    get:  { suggestion.0 },
                                    set:  { suggestion.0 = $0 }
                                ),
                                placeholder: "3"
                            )
                            .onSubmit {
                                convertQuotaInputs()
                            }

                            StandardTextField(
                                "local",
                                text: Binding<String>(
                                    get:  { suggestion.1 },
                                    set:  { suggestion.1 = $0 }
                                ),
                                placeholder: "2"
                            )
                            .onSubmit {
                                convertQuotaInputs()
                            }
                        }

                        // 4) Base
                        StandardTextField(
                            "base",
                            text: $base,
                            placeholder: "350"
                        )
                        .onSubmit {
                            convertQuotaInputs()
                        }

                        // 5) Travel‐cost fields
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Travel Cost Inputs").bold()

                            HStack {
                                // (b) Speed
                                StandardTextField(
                                    "speed",
                                    text: $speed,
                                    placeholder: "80"
                                )
                                .onSubmit {
                                    convertQuotaInputs()
                                }

                                // (c) Rate/travel
                                StandardTextField(
                                    "rate/travel",
                                    text: $travelRate,
                                    placeholder: "0.25"
                                )
                                .onSubmit {
                                    convertQuotaInputs()
                                }

                                // (d) Rate/time
                                StandardTextField(
                                    "rate/time",
                                    text: $timeRate,
                                    placeholder: "105"
                                )
                                .onSubmit {
                                    convertQuotaInputs()
                                }
                            }
                        }
                        .padding(.top, 8)

                        StandardButton(
                            type: .execute,
                            title: "Compute quota",
                            subtitle: ""
                        ) {
                            convertQuotaInputs()
                        }
                        .padding(.top, 8)

                        // 7) Show spinner / table / “enter values”
                        if quotaVm.isLoading {
                            ProgressView("Computing quota…")
                                .padding(.top, 16)
                        }
                        else if let quota = quotaVm.loadedQuota {
                            QuotaTierListView(quota: quota)
                                .padding(.top, 16)

                            StandardButton(
                                type: .execute,
                                title: "Render PDF",
                                action: {
                                    do {
                                        try render(quota: quota)
                                    } catch {
                                        print(error)
                                    }
                                }
                            )
                            .padding(.top, 8)
                        }
                        else {
                            NotificationBanner(
                                type: .info,
                                message: "Hit Return or tap Recompute above"
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

    private func convertQuotaInputs() {
        let inputs = CustomQuotaInputs(
            base: base,
            prognosis: SessionCountEstimationInputs(
                type: .prognosis,
                count: prognosis.0,
                local: prognosis.1
            ),
            suggestion: SessionCountEstimationInputs(
                type: .suggestion,
                count: suggestion.0,
                local: suggestion.1
            ),
            travelCost: TravelCostInputs(
                kilometers: kilometers,
                speed: speed,
                rates: TravelCostRatesInputs(
                    travel: travelRate,
                    time: timeRate
                ),
                roundTrip: true
            )
        )

        quotaVm.customQuotaInputs = inputs
        // quotaVm.compute()
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

