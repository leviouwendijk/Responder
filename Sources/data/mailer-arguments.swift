import Foundation
import Interfaces
import plate

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
