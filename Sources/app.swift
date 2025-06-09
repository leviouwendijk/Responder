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

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
        print("ResVM created at \(Unmanaged.passUnretained(viewmodel).toOpaque())")
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
                      .tag(0)

                    // QuotaView(viewmodel: viewmodel)
                    QuotaView()
                      .environmentObject(viewmodel)
                      .tabItem {
                          Label("Quota", systemImage: "list.bullet")
                      }
                      .tag(1)

                    MailerStandardOutput()
                      .environmentObject(viewmodel)
                      .tabItem {
                          Label("stdout", systemImage: "terminal.fill")
                      }
                      .tag(2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

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

