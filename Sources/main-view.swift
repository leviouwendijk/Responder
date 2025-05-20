import SwiftUI
import Contacts
import EventKit
import plate

let htmlDoc = """
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
    </head>
    <body>

    ...

    </body>
</html>
"""

extension String {
    /// Returns the first capture‐group for `pattern`, or nil.
    func firstCapturedGroup(
      pattern: String,
      options: NSRegularExpression.Options = []
    ) -> String? {
      guard let re = try? NSRegularExpression(pattern: pattern, options: options)
      else { return nil }
      let ns = self as NSString
      let full = NSRange(location: 0, length: ns.length)
      guard let m = re.firstMatch(in: self, options: [], range: full),
            m.numberOfRanges >= 2
      else { return nil }
      return ns.substring(with: m.range(at: 1))
    }
}

struct TemplateFetchResponse: Decodable {
    let success: Bool
    let html: String
}

struct Responder: View {
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

    @EnvironmentObject var vm: MailerViewModel
    @EnvironmentObject var invoiceVm: MailerAPIInvoiceVariablesViewModel

    @StateObject private var weeklyScheduleVm = WeeklyScheduleViewModel()
    @StateObject private var contactsVm = ContactsListViewModel()
    @StateObject private var apiPathVm = MailerAPISelectionViewModel()

    var finalSubject: String {
        return replaceTemplateVariables(subject)
    }

    var finalHtml: String {
        return replaceTemplateVariables(fetchedHtml.htmlClean())
    }

    private var finalHtmlContainsRawVariables: Bool {
        let pattern = #"\{\{\s*(?!IMAGE_WIDTH\b)[^}]+\s*\}\}"#
        return finalHtml.range(of: pattern, options: .regularExpression) != nil
    }

    private var contactExtractionError: Bool {
        return (client == "ERR" || dog == "ERR")
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
            return (finalHtmlContainsRawVariables || contactExtractionError || emptySubjectWarning || emptyEmailWarning)
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
                            TextField("Category", text: $fetchableCategory)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Text("/")

                            TextField("File", text: $fetchableFile)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
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

                        HStack {
                            StandardButton(
                                type: .clear, 
                                title: "Clear contact", 
                                subtitle: "clears contact fields"
                            ) {
                                clearContact()
                            }

                            Spacer()

                            if apiPathVm.selectedEndpoint == .messageSend {
                                StandardToggle(
                                    style: .switch,
                                    isOn: $includeQuoteInCustomMessage,
                                    title: "Include quote",
                                    subtitle: nil,
                                    width: 150
                                )
                            }
                        }
                        .frame(maxWidth: 350)
                    }
                }
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

                        CodeEditor(text: $fetchedHtml)

                        if (anyInvalidConditionsCheck && finalHtmlContainsRawVariables) {
                            NotificationBanner(
                                type: .warning,
                                message: "Raw html variables still in your message"
                            )
                        }

                        StandardButton(
                            type: .clear, 
                            title: "Clear HTML", 
                            subtitle: "clears fetched html"
                        ) {
                            fetchedHtml = ""
                        }

                        .padding()
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
                            cancelTitle: "Cancel running mailer", 
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
                            // disabledFileSelected ||
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

    func replaceTemplateVariables(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "{{name}}", with: (client.isEmpty ? "{{name}}" : client))
            .replacingOccurrences(of: "{{client}}", with: (client.isEmpty ? "{{client}}" : client))
            .replacingOccurrences(of: "{{dog}}", with: (dog.isEmpty ? "{{dog}}" : dog))
            // .replacingOccurrences(of: "{{email}}", with: email)
    }

    // change this according to view params (Responder / Picker diffs)
    private func cleanThisView() {
        // clearQueue() // unique to Responder
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

                // cleanThisView()

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

