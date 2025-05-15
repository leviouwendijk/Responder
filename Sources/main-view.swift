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
    case none
    case quote // issue, follow
    case lead // confirmation, follow
    case affiliate // enum??
    // case onboarding // pre-training
    case service // follow
    case invoice
    case resolution
    case custom
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
    case none
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
}

enum Weekday: String, CaseIterable, Identifiable {
    case mon, tue, wed, thu, fri, sat, sun
    var id: String { rawValue }

    var abbr: String {
        switch self {
            case .mon: return "Ma"
            case .tue: return "Di"
            case .wed: return "Wo"
            case .thu: return "Do"
            case .fri: return "Vr"
            case .sat: return "Zat"
            case .sun: return "Zo"
        }
    }
}

/// Holds one day’s on/off + start/end times
struct DaySchedule {
    var enabled: Bool
    var start:   Date
    var end:     Date

    init(defaultsFor day: Weekday) {
        let cal   = Calendar.current
        let today = Date()
        // helper to avoid repeating `second: 0`
        func at(_ hour: Int, _ minute: Int) -> Date {
            return cal.date(
              bySettingHour: hour,
              minute: minute,
              second: 0,
              of: today
            )!
        }

        switch day {
        case .mon:
            enabled = true
            start   = at(18, 0)
            end     = at(21, 0)
        case .tue:
            enabled = true
            start   = at(10, 0)
            end     = at(21, 0)
        case .wed:
            enabled = true
            start   = at(18, 0)
            end     = at(21, 0)
        case .thu:
            enabled = true
            start   = at(18, 0)
            end     = at(21, 0)
        case .fri:
            enabled = true
            start   = at(10, 0)
            end     = at(21, 0)
        case .sat, .sun:
            enabled = true
            start   = at(18, 0)
            end     = at(21, 0)
        }
    }
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

extension String {
    func htmlClean() -> String {
        return self
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\"", with: "\\\"")
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

    @State private var selectedCategory: MailerCategory = .none
    @State private var selectedFile: MailerFile = .none

    private let validFilesForCategory: [MailerCategory: [MailerFile]] = [
        .quote: [.issue, .follow],  // No confirmation for quotes
        .lead: [.confirmation, .check, .follow], 
        .affiliate: [.food],  // No valid files for affiliate (empty array)
        // .onboarding: [.preTraining], 
        .service: [.follow, .onboarding], 
        .invoice: [.issue, .expired],
        .resolution: [.review],
        .custom: [.template, .message],
        .none: MailerFile.allCases // All options available when no category is selected
    ]

    private func isFileDisabled(_ file: MailerFile) -> Bool {
        guard let allowedFiles = validFilesForCategory[selectedCategory] else {
            return false
        }
        return !allowedFiles.contains(file)
    }

    private func resetFileIfInvalid() {
        guard let allowedFiles = validFilesForCategory[selectedCategory] else { return }
        if !allowedFiles.contains(selectedFile) {
            selectedFile = .none
        }
    }

    private var availableFiles: [MailerFile] {
        validFilesForCategory[selectedCategory] ?? []
    }

    @State private var weeklySchedule = Dictionary(
        uniqueKeysWithValues: Weekday.allCases.map {
            ($0, DaySchedule(defaultsFor: $0))
        }
    )

    /// Builds a `[String:[String:String]]` from your `weeklySchedule`
    private var availabilityDict: [String:[String:String]] {
        var out = [String:[String:String]]()
        let df: DateFormatter = {
            let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
        }()
        for day in Weekday.allCases {
            if let sched = weeklySchedule[day], sched.enabled {
                out[day.rawValue] = [
                    "start": df.string(from: sched.start),
                    "end":   df.string(from: sched.end)
                ]
            }
        }
        return out
    }

    /// Serializes that to a compact JSON string (or `nil` if empty)
    private var availabilityJSON: String? {
        guard !availabilityDict.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: availabilityDict),
              let json = String(data: data, encoding: .utf8)
        else { return nil }
        return json
    }

    private var needsAvailability: Bool {
        selectedCategory.filesRequiringAvailability.contains(selectedFile)
    }

    var isCustomCategorySelected: Bool {
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

    private var disabledFileSelected: Bool {
        return isFileDisabled(selectedFile)
    }

    private var anyInvalidConditionsCheck: Bool {
        // if custom/template, be more tolerant about starting mailer
        if (isCustomCategorySelected && selectedFile == .template) {
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

    var mailerCommand: String {
        if selectedCategory == .invoice {
            var cmd = "mailer invoice \(invoiceId) --responder"

            if selectedFile == .expired {
                cmd.append(" --expired")
            }
            return cmd
        } else if isCustomCategorySelected {
            if selectedFile == .template {
                return "mailer template-api \(fetchableCategory) \(fetchableFile)"
            } else {
                var argumentString = ""
                argumentString = "mailer custom-message --email \"\(finalEmail)\" --subject \"\(finalSubject)\" --body \"\(finalHtml)\""
                
                if includeQuoteInCustomMessage {
                    argumentString.append(" --quote")
                }

                return argumentString
            }
        } else {
            let mailerArgs = MailerArguments(
                client: client,
                email: finalEmail,
                dog: dog,
                category: selectedCategory,
                file: selectedFile,
                // date: cliDate,
                // time: cliTime,
                // location: location,
                // areaCode: areaCode,
                // street: street,
                // number: number
                availabilityJSON: availabilityJSON,
                needsAvailability: needsAvailability
            )
            return mailerArgs.string()
        }
    }

    @State private var searchQuery = ""
    @State private var contacts: [CNContact] = []
    @State private var selectedContact: CNContact?

    var filteredContacts: [CNContact] {
        if searchQuery.isEmpty { return contacts }
        let normalizedQuery = searchQuery.normalizedForSearch
        return contacts.filter {
            $0.givenName.normalizedForSearch.contains(normalizedQuery) ||
            $0.familyName.normalizedForSearch.contains(normalizedQuery) ||
            (($0.emailAddresses.first?.value as String?)?.normalizedForSearch.contains(normalizedQuery) ?? false)
        }
    }

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @State private var showSuccessBanner = false
    @State private var successBannerMessage = ""

    // @State private var messageMakerTemplate = ""
    // @State private var msgMessage = ""

    @State private var isSendingEmail = false

    // @State private var mailerOutput = ""
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
                                        // withAnimation(.easeInOut(duration: 0.2)) {
                                          selectedCategory = category
                                          resetFileIfInvalid()
                                        // }
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
                                        // withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedFile = file
                                        // }
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

            // }

            // VStack {
            //     Text("File").bold()

            //     List(mailerFiles, id: \.self) { file in
            //         Button(action: { 
            //             if !isFileDisabled(file) { 
            //                 selectedFile = file 
            //             }
            //         }) {
            //             Text(file.rawValue.capitalized)
            //                 .frame(maxWidth: .infinity, minHeight: 16)
            //                 .padding()
            //                 .background(selectedFile == file ? Color.blue.opacity(0.3) : Color.clear)
            //                 .clipShape(RoundedRectangle(cornerRadius: 8))
            //                 .opacity(isFileDisabled(file) ? 0.5 : 1.0) // Reduce opacity if disabled
            //         }
            //         .contentShape(Rectangle())
            //         .disabled(isFileDisabled(file)) // Disable the button when not allowed
            //     }
            //     .scrollContentBackground(.hidden)

            //     if (disabledFileSelected) {
            //         HStack(spacing: 8) {
            //             Image(systemName: "exclamationmark.triangle.fill")
            //                 .font(.headline)
            //                 .accessibilityHidden(true)

            //             Text("Select a template for this category")
            //             .font(.subheadline)
            //             .bold()
            //         }
            //         .foregroundColor(.black)
            //         .padding(.vertical, 10)
            //         .padding(.horizontal, 16)
            //         .background(Color.yellow)
            //         .cornerRadius(8)
            //         .padding(.horizontal)
            //         .transition(.move(edge: .top).combined(with: .opacity))
            //         .animation(.easeInOut, value: (disabledFileSelected))
            //     }

            // }
            // .frame(width: 140)



            // Output and format control
            VStack {

                VStack {
                    if !( (isCustomCategorySelected && selectedFile == .template) || selectedCategory == .invoice) {
                        HStack {
                            StandardButton(
                                type: .load, 
                                title: "Load contacts"
                            ) {
                                requestContactsAccess()
                            }

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
                    if !( (isCustomCategorySelected && selectedFile == .template) || selectedCategory == .invoice) {
                        // Contact Search Bar
                        TextField("Search Contacts", text: $searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        if (anyInvalidConditionsCheck && contactExtractionError) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.headline)
                                    .accessibilityHidden(true)

                                Text("ContactExtractionError: client or dog name is invalid")
                                .font(.subheadline)
                                .bold()
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(Color.red)
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.easeInOut, value: (anyInvalidConditionsCheck && contactExtractionError))
                        }

                        // Contact List
                        List(filteredContacts, id: \.identifier) { contact in
                            Button(action: {
                                clearContact()

                                selectedContact = contact

                                let split = splitClientDog(contact.givenName)
                                client = split.name
                                dog = split.dog
                                email = contact.emailAddresses.first?.value as String? ?? ""
                                
                                if let postalAddress = contact.postalAddresses.first?.value {
                                    location = postalAddress.city
                                    street = postalAddress.street
                                    areaCode = postalAddress.postalCode
                                }
                            }) {
                                HStack {
                                    Text("\(contact.givenName) \(contact.familyName)")
                                        .font(selectedContact?.identifier == contact.identifier ? .headline : .body)
                                    Spacer()
                                    Text(contact.emailAddresses.first?.value as String? ?? "")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden) 
                        .frame(height: 200)
                        .padding()
                    }

                    Text("Mailer Arguments").bold()
                    
                    if isCustomCategorySelected && selectedFile == .template {
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
                            // Button("Clear contact") {
                            //     clearContact()
                            // }

                            StandardButton(
                                type: .clear, 
                                title: "Clear contact", 
                                subtitle: "clears contact fields"
                            ) {
                                clearContact()
                            }


                            Spacer()

                            if selectedFile == .message {
                                // Button("Memo") {
                                //     email = "casper@hondenmeesters.nl, shusha@hondenmeesters.nl, levi@hondenmeesters.nl"
                                //     if fetchedHtml.isEmpty {
                                //         fetchedHtml = htmlDoc
                                //     }
                                // }

                                // StandardButton(
                                //     type: .load, 
                                //     title: "Memo", 
                                //     subtitle: "sets memo emails"
                                // ) {
                                //     email = "casper@hondenmeesters.nl, shusha@hondenmeesters.nl, levi@hondenmeesters.nl"

                                //     if fetchedHtml.isEmpty {
                                //         fetchedHtml = htmlDoc
                                //     }
                                // }

                                // .padding()

                                // Toggle("Include quote", isOn: $includeQuoteInCustomMessage)

                                StandardToggle(
                                    style: .switch,
                                    isOn: $includeQuoteInCustomMessage,
                                    title: "Include quote",
                                    subtitle: nil,
                                    width: 150
                                )
                                // .padding()
                            }
                        }
                        .frame(maxWidth: 350)

                    }
                }
                .padding()

                // VStack {
                //     Button(action: {
                //         NSPasteboard.general.clearContents()
                //         NSPasteboard.general.setString(mailerCommand, forType: .string)
                //     }) {
                //         Text(mailerCommand)
                //             .bold()
                //             .padding()
                //             .background(Color.gray.opacity(0.2))
                //             .cornerRadius(5)
                //     }
                //     .buttonStyle(PlainButtonStyle())
                // }
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

                        // .disabled(true) // testing the disabled view of std buttons

                        // Button("clear html") {
                        //     fetchedHtml = ""
                        // }
                        .padding()
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Week-/time availability").bold()

                        // grid two-column: day + controls
                        ForEach(Weekday.allCases) { day in
                          HStack(spacing: 12) {
                            Toggle(day.abbr, isOn: Binding(
                              get: { weeklySchedule[day]!.enabled },
                              set: { weeklySchedule[day]!.enabled = $0 }
                            ))
                            .toggleStyle(.switch)

                            if weeklySchedule[day]!.enabled {
                              DatePicker("", selection: Binding(
                                get: { weeklySchedule[day]!.start },
                                set: { weeklySchedule[day]!.start = $0 }
                              ), displayedComponents: .hourAndMinute)
                              .labelsHidden()
                              .datePickerStyle(.compact)

                              DatePicker("", selection: Binding(
                                get: { weeklySchedule[day]!.end },
                                set: { weeklySchedule[day]!.end = $0 }
                              ), displayedComponents: .hourAndMinute)
                              .labelsHidden()
                              .datePickerStyle(.compact)
                            }
                          }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Spacer()

                // **Queue Management Buttons**
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
                        // Button(action: sendMailerEmail) {
                        //     Label("Start mailer process", systemImage: "paperplane.fill")
                        // }
                        // .buttonStyle(.borderedProminent)
                        // .disabled(isSendingEmail || anyInvalidConditionsCheck || disabledFileSelected)

                        StandardButton(
                            type: .execute, 
                            title: "Run mailer", 
                            subtitle: "Starts mailer background process"
                        ) {
                            sendMailerEmail()
                        }
                        .disabled(isSendingEmail || anyInvalidConditionsCheck || disabledFileSelected)

                    }
                    .padding(.top, 10)
                }
            }
            .frame(width: 700)
            
        }
        .padding()
        .onAppear {
            fetchContacts()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: mailerCommand) { oldValue, newValue in
            vm.sharedMailerCommandCopy = newValue
        }
    }

    func replaceTemplateVariables(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "{{name}}", with: (client.isEmpty ? "{{name}}" : client))
            .replacingOccurrences(of: "{{client}}", with: (client.isEmpty ? "{{client}}" : client))
            .replacingOccurrences(of: "{{dog}}", with: (dog.isEmpty ? "{{dog}}" : dog))
            // .replacingOccurrences(of: "{{email}}", with: email)
    }

    private func requestContactsAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                fetchContacts()
            } else {
                print("Access denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    private func fetchContacts() {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)

        var fetchedContacts: [CNContact] = []
        try? store.enumerateContacts(with: request) { contact, _ in
            fetchedContacts.append(contact)
        }

        DispatchQueue.main.async {
            contacts = fetchedContacts
        }
    }

    // change this according to view params (Responder / Picker diffs)
    private func cleanThisView() {
        // clearQueue() // unique to Responder
        clearContact()
        if includeQuoteInCustomMessage {
            includeQuoteInCustomMessage = false
        }
        invoiceId = ""
    }
    
    private func sendMailerEmail() {
        vm.mailerOutput = ""

        withAnimation { isSendingEmail = true }

        var arguments = ""

        if selectedCategory == .invoice {
            arguments = "invoice \(invoiceId) --responder"

            if selectedFile == .expired {
                arguments.append(" --expired")
            }
        } else if selectedCategory == .custom {
            if selectedFile == .template {
                arguments = "template-api \(fetchableCategory) \(fetchableFile)"
            } else {
                arguments = "custom-message --email \"\(finalEmail)\" --subject \"\(finalSubject)\" --body \"\(finalHtml)\""
                
                if includeQuoteInCustomMessage {
                    arguments.append(" --quote")
                }

                // arguments = "custom-message --email \"\(finalEmail)\" --subject \"\(finalSubject)\" --body \"\(finalHtml)\""
            }
        } else {
            let data = MailerArguments(
                client: client,
                email: finalEmail,
                dog: dog,
                category: selectedCategory,
                file: selectedFile,
                availabilityJSON: availabilityJSON,
                needsAvailability: needsAvailability
            )
            arguments = data.string(false)
        }
        // let arguments = data.string(false)

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
                if selectedCategory == .custom && selectedFile == .template {
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

struct Client {
    let name: String
    let dog: String
}

func splitClientDog(_ givenName: String) -> Client {
    var name = "ERR"
    var dog = "ERR"

    let split = givenName.components(separatedBy: " | ")

    if split.count == 2 {
        name = String(split[0]).trimTrailing()
        dog = String(split[1]).trimTrailing()
    } else {
        print("Invalid input format: expected 'ClientName | DogName'")
    }

    return Client(name: name, dog: dog)
}


struct MailerArguments {
    let client: String
    let email: String
    let dog: String
    let category: MailerCategory
    let file: MailerFile
    // let date: String
    // let time: String
    // let location: String
    // let areaCode: String?
    // let street: String?
    // let number: String?
    let availabilityJSON: String?
    let needsAvailability: Bool

    // func string(_ local: Bool,_ localLocation: String) -> String {
    func string(_ includeBinaryName: Bool = true) -> String {
        if includeBinaryName {
            let components: [String] = [
                "mailer",
                "\(category.rawValue)",
                "--client \"\(client)\"",
                "--email \"\(email)\"",
                "--dog \"\(dog)\"",
                file == .none || file == .issue || file == .confirmation || file == .review ? nil : "--\(file.rawValue)",
                needsAvailability ? "--availability-json '\(availabilityJSON ?? "")'": nil,
                // "--date \"\(date)\"",
                // "--time \"\(time)\"",
                // "--location \"\(local ? localLocation : location)\""
                ""
            ]
            .compactMap { $0 } 

            // if let areaCode = areaCode, !areaCode.isEmpty, !local {
            //     components.append("--area-code \"\(areaCode)\"")
            // }
            // if let street = street, !street.isEmpty, !local {
            //     components.append("--street \"\(street)\"")
            // }
            // if let number = number, !number.isEmpty, !local {
            //     components.append("--number \"\(number)\"")
            // }

            return components.joined(separator: " ")
        } else {
            let components: [String] = [
                "\(category.rawValue)",
                "--client \"\(client)\"",
                "--email \"\(email)\"",
                "--dog \"\(dog)\"",
                file == .none || file == .issue || file == .confirmation || file == .review ? nil : "--\(file.rawValue)",
                needsAvailability ? "--availability-json '\(availabilityJSON ?? "")'": nil,
                ""
            ]
            .compactMap { $0 } 

            return components.joined(separator: " ")
        }
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


// Replace '|' with space, split by whitespace, remove empty parts, and join back
extension String {
    var normalizedForSearch: String {
        return self.folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "|", with: " ")
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()
    }
}

extension String {
    func wrapJsonForCLI() -> String {
        return "'[\(self)]'"
    }
}

// struct ContentView: View {
//     var body: some View {
//         ResponderView()
//     }
// }

// @main
// struct ResponderApp: App {
//     var body: some Scene {
//         WindowGroup {
//             ContentView()
//         }
//     }
// }
