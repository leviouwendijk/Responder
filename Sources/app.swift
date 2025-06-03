import SwiftUI
import plate

@main
struct ResponderApp: App {
    @StateObject private var mailerViewModel = MailerViewModel()
    @StateObject private var invoiceVm = MailerAPIInvoiceVariablesViewModel()

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

                    MailerStandardOutput()
                      .environmentObject(mailerViewModel)
                      .tabItem {
                        Label("stdout", systemImage: "terminal.fill")
                      }
                      .tag(1)
                }

                BuildInformationSwitch(
                    alignment: .center,
                    display: [
                        [.version],
                        [.latestVersion],
                        [.name],
                        [.author]
                    ],
                    prefixStyle: .long
                )
            }
        }
    }
}

