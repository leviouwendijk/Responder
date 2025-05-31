import Foundation
import SwiftUI
import plate

struct MessageMakerView: View {
    @EnvironmentObject var vm: MailerViewModel
    @State private var messageMakerTemplate = ""
    @State private var msgMessage = ""

    @State private var client = ""
    @State private var dog = ""

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            VStack {
                TextField("client", text: $client)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("dog", text: $dog)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .frame(maxWidth: 500)

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
            .frame(maxWidth: 500)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func makeQuickMessage() {
        let arguments = "\"\(client)\" \"\(dog)\" \(messageMakerTemplate)"
        // Execute on a background thread to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let message = try executeMessageMaker(arguments)
                // Prepare success alert on the main thread
                DispatchQueue.main.async {
                    // successBannerMessage = "msg executed successfully"
                    // showSuccessBanner = true

                    msgMessage = message

                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        // withAnimation {
                        //     showSuccessBanner = false
                        // }
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

func executeMessageMaker(_ arguments: String) throws -> String {
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
        // print("msg executed successfully:\n\(outputString)")
        return outputString
    } else {
        print("Error running msg:\n\(errorString)")
        throw NSError(domain: "msg", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorString])
    }
}


