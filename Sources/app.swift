import SwiftUI
import plate

@main
struct ResponderApp: App {
    // @StateObject private var mailerViewModel: MailerViewModel
    // @StateObject private var variableStore: VariableStore
    // @StateObject private var invoiceVm: MailerAPIInvoiceVariablesViewModel

    @StateObject private var mailerViewModel = MailerViewModel()
    @StateObject private var invoiceVm = MailerAPIInvoiceVariablesViewModel()

    init() {
        // _mailerViewModel = StateObject(wrappedValue: MailerViewModel())

        // let vs = VariableStore()
        // _variableStore   = StateObject(wrappedValue: vs)
        // _invoiceVm       = StateObject(wrappedValue: MailerAPIInvoiceVariablesViewModel(store: vs))

        NSWindow.allowsAutomaticWindowTabbing = false
    }

    @State private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
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
        }
    }
}
