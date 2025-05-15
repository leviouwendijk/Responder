import SwiftUI

@main
struct ResponderApp: App {
    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    @StateObject private var mailerViewModel = MailerViewModel()
    @State private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                Responder()
                  .environmentObject(mailerViewModel)
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
