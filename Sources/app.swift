import Foundation
import SwiftUI
import plate
import Interfaces
import ViewComponents
import Compositions
import Implementations
import Interfaces

@main
struct ResponderApp: App {
    @StateObject private var viewmodel = ResponderViewModel()

    // @State public var errorMessage = ""
    public var errorMessage = ""

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
        // print("ResVM created at \(Unmanaged.passUnretained(viewmodel).toOpaque())")
        do {
            try prepareEnvironment()
        } catch {
            print(error)
            self.errorMessage = error.localizedDescription
        }
    }

    @State private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
            VStack {
                TabView(selection: $selectedTab) {
                    Responder()
                      .environmentObject(viewmodel)
                      .tabItem {
                          Label("Mailer", systemImage: "paperplane.fill")
                      }
                      .onAppear {
                          viewmodel.messagesStore.add(messages: messages)
                      }
                      .tag(0)

                    // QuotaView(viewmodel: viewmodel)
                    QuotaView()
                      .environmentObject(viewmodel)
                      .tabItem {
                          Label("Quota", systemImage: "list.bullet")
                      }
                      .tag(1)

                    PostcodeLookupView()
                      // .environmentObject(viewmodel)
                      .tabItem {
                          Label("Postcode", systemImage: "list.bullet")
                      }
                      .tag(2)

                    MailerStandardOutput()
                      .environmentObject(viewmodel)
                      .tabItem {
                          Label("request_log", systemImage: "terminal.fill")
                      }
                      .tag(3)

                    CodeAndPreviewView()
                      .tabItem {
                          Label("lab", systemImage: "terminal.fill")
                      }
                      .tag(4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                NotificationBanner(
                    type: .error,
                    message: self.errorMessage
                )
                .hide(when: self.errorMessage.isEmpty)

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

