import SwiftUI
import plate

@main
struct ResponderApp: App {
    @StateObject private var mailerViewModel = MailerViewModel()
    @StateObject private var invoiceVm = MailerAPIInvoiceVariablesViewModel()

    let buildSpecification = BuildSpecification(
      version: BuildVersion(major: 2, minor: 2, patch: 1),
      name: "Responder",
      author: "Levi Ouwendijk",
      description: ""
    )

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    @State private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
            VStack {
                TabView(selection: $selectedTab) {
                    Responder()
                      .environmentObject(mailerViewModel)
                      .environmentObject(invoiceVm)
                      .tabItem {
                        Label("Responder", systemImage: "paperplane.fill")
                      }
                      .tag(0)

                    MessageMakerView()
                      .environmentObject(mailerViewModel)
                      .tabItem {
                        Label("WA", systemImage: "message.fill")
                      }
                      .tag(1)

                    MailerStandardOutput()
                      .environmentObject(mailerViewModel)
                      .tabItem {
                        Label("stdout", systemImage: "terminal.fill")
                      }
                      .tag(2)
                }

                BuildInformation(
                    specification: buildSpecification,
                    alignment: .center,
                    display: [.version]
                )
            }
        }
    }
}

