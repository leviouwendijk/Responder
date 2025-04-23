import SwiftUI
import Contacts
import EventKit
import plate

enum MailerCategory: String, RawRepresentable, CaseIterable {
    case none
    case quote // issue, follow
    case lead // confirmation, follow
    case affiliate // enum??
    // case onboarding // pre-training
    case service // follow
    case resolution
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
    // case preTraining
    case onboarding
    case review
    case check
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
              second: 0,       // ← this was missing
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

struct ResponderView: View {
    @State private var client = ""
    @State private var email = ""
    @State private var dog = ""
    @State private var location = ""
    @State private var areaCode: String?
    @State private var street: String?
    @State private var number: String?
    @State private var localLocation = "Alkmaar"
    @State private var local = false

    private let mailerCategories = MailerCategory.allCases
    private let mailerFiles = MailerFile.allCases

    @State private var selectedCategory: MailerCategory = .none
    @State private var selectedFile: MailerFile = .none

    private let validFilesForCategory: [MailerCategory: [MailerFile]] = [
        .quote: [.issue, .follow],  // No confirmation for quotes
        .lead: [.confirmation, .check, .follow], 
        .affiliate: [],  // No valid files for affiliate (empty array)
        // .onboarding: [.preTraining], 
        .service: [.follow, .onboarding], 
        .resolution: [.review],
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

    var mailerCommand: String {
        let mailerArgs = MailerArguments(
            client: client,
            email: email,
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

    @State private var messageMakerTemplate = ""
    @State private var msgMessage = ""

    @State private var isSendingEmail = false

    var body: some View {
        HStack {
            VStack {
                Text("Category").bold()
                List(mailerCategories, id: \.self) { category in
                    Button(action: { 
                        selectedCategory = category
                        resetFileIfInvalid()
                    }) {
                        Text("\(category.rawValue.capitalized)")
                            .frame(maxWidth: .infinity, minHeight: 40) 
                            .padding()
                            .background(selectedCategory == category ? Color.blue.opacity(0.3) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8)) 
                    }
                    .contentShape(Rectangle()) 
                }
                .scrollContentBackground(.hidden)
            }
            .frame(width: 140)

            VStack {
                Text("File").bold()
                List(mailerFiles, id: \.self) { file in
                    Button(action: { 
                        if !isFileDisabled(file) { 
                            selectedFile = file 
                        }
                    }) {
                        Text(file.rawValue.capitalized)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .padding()
                            .background(selectedFile == file ? Color.blue.opacity(0.3) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .opacity(isFileDisabled(file) ? 0.5 : 1.0) // Reduce opacity if disabled
                    }
                    .contentShape(Rectangle())
                    .disabled(isFileDisabled(file)) // Disable the button when not allowed
                }
                .scrollContentBackground(.hidden)
            }
            .frame(width: 140)



            // Output and format control
            VStack {
                HStack {
                    Spacer()
                    Button("Load Contacts") {
                        requestContactsAccess()
                    }
                    .padding()
                    Spacer()
                    Toggle("Local Location", isOn: $local)
                    .padding()
                }

                VStack(alignment: .leading) {
                    // Contact Search Bar
                    TextField("Search Contacts", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

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

                    Text("Mailer Arguments").bold()
                    
                    TextField("Client", text: $client)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Dog", text: $dog)
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
                }
                .padding()

                VStack {
                    // Button(action: {
                    //     NSPasteboard.general.clearContents()
                    //     NSPasteboard.general.setString(formattedOutput, forType: .string)
                    // }) {
                    //     Text(formattedOutput)
                    //         .bold()
                    //         .padding()
                    //         .background(Color.gray.opacity(0.2))
                    //         .cornerRadius(5)
                    // }
                    // .buttonStyle(PlainButtonStyle()) 

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(mailerCommand, forType: .string)
                    }) {
                        Text(mailerCommand)
                            .bold()
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(width: 400)

            Divider()

            VStack {
                VStack {
                    TextField("`sr`, `na`, `no-answer`", text: $messageMakerTemplate)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        makeQuickMessage()
                    }

                    HStack {
                        Button(action: makeQuickMessage) {
                            Label("make msg", systemImage: "apple.terminal.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: clearMsgMessage) {
                            Label("clear message", systemImage: "apple.terminal.fill")
                        }
                        .buttonStyle(.bordered)
                    }

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(msgMessage, forType: .string)
                    }) {
                        Text(msgMessage)
                            .bold()
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())

                }

                Spacer()

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

                Spacer()

                // **Queue Management Buttons**
                if showSuccessBanner {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text(successBannerMessage)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.green)
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

                    HStack {
                        Button(action: sendMailerEmail) {
                            Label("Send mailer mail", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSendingEmail)
                    }
                    .padding(.top, 10)
                }
            }
            .frame(width: 400)
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

    private func sendMailerEmail() {
        withAnimation {
            isSendingEmail = true
        }
        
        let data = MailerArguments(
            client: client,
            email: email,
            dog: dog,
            category: selectedCategory,
            file: selectedFile,
            availabilityJSON: availabilityJSON,
            needsAvailability: needsAvailability
        )
        let arguments = data.string(false)
        // Execute on a background thread to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try executeMailer(arguments)
                // Prepare success alert on the main thread
                DispatchQueue.main.async {
                    successBannerMessage = "The email was sent successfully."
                    showSuccessBanner = true

                    clearContact()

                    withAnimation {
                        isSendingEmail = false
                    }

                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showSuccessBanner = false
                        }
                    }
                }
            } catch {
                // Prepare failure alert on the main thread
                DispatchQueue.main.async {
                    alertTitle = "Error"
                    alertMessage = "There was an error sending the confirmation email:\n\(error.localizedDescription) \(arguments)"
                    showAlert = true
                    withAnimation {
                        isSendingEmail = false
                    }
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

    private func makeQuickMessage() {
        let arguments = "\"\(client)\" \"\(dog)\" \(messageMakerTemplate)"
        // Execute on a background thread to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let message = try executeMessageMaker(arguments)
                // Prepare success alert on the main thread
                DispatchQueue.main.async {
                    successBannerMessage = "msg executed successfully"
                    showSuccessBanner = true

                    msgMessage = message

                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation {
                            showSuccessBanner = false
                        }
                    }
                }
            } catch {
                // Prepare failure alert on the main thread
                DispatchQueue.main.async {
                    alertTitle = "Error"
                    alertMessage = "Problem with execution of msg:\n\(error.localizedDescription) \(arguments)"
                    showAlert = true
                }
            }
        }
    }

    private func clearMsgMessage() {
        msgMessage = ""
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

func executeMessageMaker(_ arguments: String) throws -> String {
    do {
        let home = Home.string()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh") // Use Zsh directly
        process.arguments = ["-c", "source ~/dotfiles/.vars.zsh && \(home)/sbm-bin/msg \(arguments)"]
        
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
            print("msg executed successfully:\n\(outputString)")
            return outputString
        } else {
            print("Error running msg:\n\(errorString)")
            throw NSError(domain: "msg", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorString])
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

struct ContentView: View {
    var body: some View {
        ResponderView()
    }
}

@main
struct ResponderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
