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

enum MailerCategory: String, RawRepresentable, CaseIterable {
    // case none
    case quote // issue, follow
    case lead // confirmation, follow
    case affiliate // enum??
    // case onboarding // pre-training
    case service // follow
    case invoice
    case resolution
    case custom
    case template
}

extension MailerCategory {
    var filesRequiringAvailability: Set<MailerFile> {
        switch self {
            case .lead:       return [.confirmation, .check, .follow]
            case .service:    return [.follow]
            default:          return []
        }
    }
}

enum MailerFile: String, RawRepresentable, CaseIterable {
    // case none
    case confirmation
    case issue 
    case follow
    case expired 
    // case preTraining
    case onboarding
    case review
    case check
    case food
    case template
    case message
    case fetch
}

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
        // 1. Split on commas
        .split(separator: ",")
        // 2. Trim whitespace/newlines around each piece
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        // 3. Drop any empty strings (in case of trailing commas or double-commas)
        .filter { !$0.isEmpty }
        // 4. Join back together with a single space
        .joined(separator: " ")
    }

    @State private var dog = ""
    @State private var location = ""
    @State private var areaCode: String?
    @State private var street: String?
    @State private var number: String?
    @State private var localLocation = "Alkmaar"
    @State private var local = false

    @State private var invoiceId = ""

    private let mailerCategories = MailerCategory.allCases
    private let mailerFiles = MailerFile.allCases

    @State private var selectedCategory: MailerCategory? = nil
    @State private var selectedFile: MailerFile? = nil

    private let validFilesForCategory: [MailerCategory: [MailerFile]] = [
        .quote: [.issue, .follow],  // No confirmation for quotes
        .lead: [.confirmation, .check, .follow], 
        .affiliate: [.food],  // No valid files for affiliate (empty array)
        // .onboarding: [.preTraining], 
        .service: [.follow, .onboarding], 
        .invoice: [.issue, .expired],
        .resolution: [.review],
        .custom: [.message],
        .template: [.fetch]
    ]

    // private func resetFileIfInvalid() {
    //     guard
    //       let category = selectedCategory,
    //       let file     = selectedFile,
    //       let allowed  = validFilesForCategory[category],
    //       !allowed.contains(file)
    //     else { return }

    //     selectedFile = nil
    // }

    private var availableFiles: [MailerFile] {
        guard let category = selectedCategory else { return [] }
        return validFilesForCategory[category] ?? []
    }

    private func isFileDisabled(_ file: MailerFile) -> Bool {
        guard
          let category = selectedCategory,
          let allowed  = validFilesForCategory[category]
        else { return true }   // disable everything if no category
        return !allowed.contains(file)
    }

    private var disabledFileSelected: Bool {
        selectedFile.map { isFileDisabled($0) } ?? false
    }

    private var needsAvailability: Bool {
        guard
          let category = selectedCategory,
          let file     = selectedFile
        else { return false }
        return category.filesRequiringAvailability.contains(file)
    }

    // @State private var weeklySchedule = Dictionary(
    //     uniqueKeysWithValues: MailerAPIWeekday.allCases.map {
    //         ($0, MailerAPIDaySchedule(defaultsFor: $0))
    //     }
    // )

    /// Builds a `[String:[String:String]]` from your `weeklySchedule`
    // private var availabilityDict: [String:[String:String]] {
    //     var out = [String:[String:String]]()
    //     let df: DateFormatter = {
    //         let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    //     }()
    //     for day in MailerAPIWeekday.allCases {
    //         if let sched = weeklySchedule[day], sched.enabled {
    //             out[day.rawValue] = [
    //                 "start": df.string(from: sched.start),
    //                 "end":   df.string(from: sched.end)
    //             ]
    //         }
    //     }
    //     return out

    // }

    @StateObject private var weeklyScheduleVm = WeeklyScheduleViewModel()
    @StateObject private var contactsVm = ContactsListViewModel()

    private var availabilityDict: [String: [String:String]] {
        return weeklyScheduleVm.availabilityContent.time_range()
    }

    private var availabilityJSON: String? {
        guard !availabilityDict.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: availabilityDict),
              let json = String(data: data, encoding: .utf8)
        else { return nil }
        return json
    }


    var isCustomCategorySelected: Bool {
        return (selectedCategory == .custom)
    }

    var isTemplateCategorySelected: Bool {
        return (selectedCategory == .custom)
    }

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
        if (isTemplateCategorySelected) {
            return false
        // if custom/.., check the html body for raw variables
        } else if (isCustomCategorySelected) {
            return (finalHtmlContainsRawVariables || contactExtractionError || emptySubjectWarning || emptyEmailWarning)
        // otherwise, check for parsing errs in client / dog names in primary templates
        } else {
            if contactExtractionError {
                return true
            // if all that clears, do not raise invalid marker
            } else {
                return false
            }
        }
    }

    // var mailerCommand: String {
    //     return (try? constructMailerCommand()) ?? ""
    // }

    func constructMailerCommand(_ includeBinaryName: Bool = false) throws -> String {
        let stateVars = StateVariables(
            invoiceId: invoiceId,
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
            category: selectedCategory,
            file: selectedFile,
            availabilityJSON: availabilityJSON,
            needsAvailability: needsAvailability,
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

    @EnvironmentObject var vm: MailerViewModel

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
            // SwipeFadeContainer(threshold: 80, animationDuration: 0.25) {
            VStack {
                HStack {
                    VStack {
                        // Text("Category").bold()
                        SectionTitle(title: "Category", width: 150)

                        ScrollView {
                            VStack(spacing: 5) {
                                ForEach(mailerCategories, id: \.self) { category in
                                    SelectableRow(
                                        title: category.rawValue.capitalized,
                                        isSelected: selectedCategory == category,
                                        animationDuration: 0.3
                                    ) {
                                        if selectedCategory == category {
                                            selectedCategory = nil
                                        } else {
                                            selectedCategory = category
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                    .frame(width: 150)

                    VStack {
                        SectionTitle(title: "File", width: 150)

                        ScrollView {
                            VStack(spacing: 5) {
                                ForEach(availableFiles, id: \.self) { file in
                                    SelectableRow(
                                        title: file.rawValue.capitalized,
                                        isSelected: selectedFile == file
                                    ) {
                                        if selectedFile == file {
                                            selectedFile = nil
                                        } else {
                                            selectedFile = file
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }

                        // if (disabledFileSelected) {
                        //     HStack(spacing: 8) {
                        //         Image(systemName: "exclamationmark.triangle.fill")
                        //             .font(.headline)
                        //             .accessibilityHidden(true)

                        //         Text("Select a template for this category")
                        //         .font(.subheadline)
                        //         .bold()
                        //     }
                        //     .foregroundColor(.black)
                        //     .padding(.vertical, 10)
                        //     .padding(.horizontal, 16)
                        //     .background(Color.yellow)
                        //     .cornerRadius(8)
                        //     .padding(.horizontal)
                        //     .transition(.move(edge: .top).combined(with: .opacity))
                        //     .animation(.easeInOut, value: (disabledFileSelected))
                        // }

                    }
                    .frame(width: 150)
                }

                if disabledFileSelected {
                    NotificationBanner(
                        type: .info,
                        message: "No template selected"
                    )
                }

                if selectedCategory == .invoice {
                    NotificationBanner(
                        type: .error,
                        message: "these are not quotes casper!"
                    )
                }
            }

            VStack {
                VStack {
                    if !(selectedCategory == .template || selectedCategory == .invoice) {
                        HStack {
                            // StandardButton(
                            //     type: .load, 
                            //     title: "Load contacts"
                            // ) {
                            //     do {
                            //         try await requestContactsAccess()
                            //     } catch {
                            //         print(error)
                            //     }
                            // }

                            // Button("Load Contacts") {
                            //     requestContactsAccess()
                            // }

                            Spacer()

                            // Toggle("Local Location", isOn: $local)

                            StandardToggle(
                                style: .switch,
                                isOn: $local,
                                title: "Local Location",
                                subtitle: nil
                            )

                            // .padding()
                        }

                    }
                }
                .frame(maxWidth: 350)

                Divider()

                VStack(alignment: .leading) {
                    if !(selectedCategory == .template || selectedCategory == .invoice) {

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
                        // ) { contact in

                        //     // if contactsVm.selectedContactId == nil {
                        //     //     clearContact()
                        //     // }

                        //     clearContact()
                        //     selectedContact = contact
                        //     let split = try splitClientDog(from: contact.givenName)
                        //     client = split.name
                        //     dog    = split.dog
                        //     email  = contact.emailAddresses.first?.value as String? ?? ""
                        //     if let addr = contact.postalAddresses.first?.value {
                        //         location = addr.city
                        //         street   = addr.street
                        //         areaCode = addr.postalCode
                        //     }
                        // }
                        .frame(maxWidth: 350)
                    }

                    Text("Mailer Arguments").bold()
                    
                    if selectedCategory == .template {
                        HStack {
                            TextField("Category", text: $fetchableCategory)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Text("/")

                            TextField("File", text: $fetchableFile)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    } else if selectedCategory == .invoice {
                        TextField("invoice id (integer)", text: $invoiceId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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

                            if selectedFile == .message {
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
                if isCustomCategorySelected {
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

                        // TextEditor(text: $fetchedHtml)
                        // .font(.system(.body, design: .monospaced))
                        // .border(Color.gray)
                        // .frame(minHeight: 300)

                        // .frame(minWidth: 300)

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

                    if needsAvailability {
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

                    if selectedCategory == .invoice && selectedFile == .expired {
                        NotificationBanner(
                            type: .warning,
                            message: "You are sending an overdue reminder"
                        )
                    }

                    HStack {
                        StandardButton(
                            type: .execute, 
                            title: "Run mailer", 
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
                            disabledFileSelected ||
                            selectedCategory == nil ||
                            selectedFile == nil
                        )

                    }
                    .padding(.top, 10)
                }
            }
            .frame(minWidth: 500)
            
        }
        .padding()
        // .onAppear {
        //     fetchContacts()
        // }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }

        // .onChange(of: mailerCommand) { oldValue, newValue in
        //     vm.sharedMailerCommandCopy = newValue
        // }
    }

    func replaceTemplateVariables(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "{{name}}", with: (client.isEmpty ? "{{name}}" : client))
            .replacingOccurrences(of: "{{client}}", with: (client.isEmpty ? "{{client}}" : client))
            .replacingOccurrences(of: "{{dog}}", with: (dog.isEmpty ? "{{dog}}" : dog))
            // .replacingOccurrences(of: "{{email}}", with: email)
    }

    // private func requestContactsAccess() {
    //     let store = CNContactStore()
    //     store.requestAccess(for: .contacts) { granted, error in
    //         if granted {
    //             fetchContacts()
    //         } else {
    //             print("Access denied: \(error?.localizedDescription ?? "Unknown error")")
    //         }
    //     }
    // }

    // private func fetchContacts() {
    //     let store = CNContactStore()
    //     let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey] as [CNKeyDescriptor]
    //     let request = CNContactFetchRequest(keysToFetch: keys)

    //     var fetchedContacts: [CNContact] = []
    //     try? store.enumerateContacts(with: request) { contact, _ in
    //         fetchedContacts.append(contact)
    //     }

    //     DispatchQueue.main.async {
    //         contacts = fetchedContacts
    //     }
    // }

    // change this according to view params (Responder / Picker diffs)
    private func cleanThisView() {
        // clearQueue() // unique to Responder
        clearContact()
        if includeQuoteInCustomMessage {
            includeQuoteInCustomMessage = false
        }
        invoiceId = ""
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
                if selectedCategory == .template {
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

// struct Client {
//     let name: String
//     let dog: String
// }

// func splitClientDog(_ givenName: String) -> Client {
//     var name = "ERR"
//     var dog = "ERR"

//     let split = givenName.components(separatedBy: " | ")

//     if split.count == 2 {
//         name = String(split[0]).trimTrailing()
//         dog = String(split[1]).trimTrailing()
//     } else {
//         print("Invalid input format: expected 'ClientName | DogName'")
//     }

//     return Client(name: name, dog: dog)
// }

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
    let category: MailerCategory?
    let file: MailerFile?
    let availabilityJSON: String?
    let needsAvailability: Bool
    let stateVariables: StateVariables

    func string(_ includeBinaryName: Bool = false) throws -> String {
        guard let cat = category, let f = file else {
            throw ArgError.missingArgumentComponents
        }

        var components: [String] = []

        if includeBinaryName {
            components.insert("mailer", at: 0)
        }

        switch cat {
        case .invoice:
            components.append("invoice \(stateVariables.invoiceId) --responder")
            if f == .expired {
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
            components.append(cat.rawValue)
            components.append("--client \"\(client)\"")
            components.append("--email \"\(email)\"")
            components.append("--dog \"\(dog)\"")

            if !(f == .issue || f == .confirmation || f == .review) {
                components.append("--\(f.rawValue)")
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
