import ViewComponents
import SwiftUI
import Foundation
import Economics
import plate
import Interfaces

struct SelectableTierView: View {
    @State private var selectedCopyableTier: QuotaTierType = .combined

    @StateObject private var shortCopyQuotaNotifier: NotificationBannerController = NotificationBannerController(
        contents: [NotificationBannerControllerContents(title: "copied", style: .success, message: "copied")],
        addingDefaultContents: true
    )

    @StateObject private var copyQuotaNotifier: NotificationBannerController = NotificationBannerController(
        contents: [NotificationBannerControllerContents(title: "copied", style: .success, message: "copied")],
        addingDefaultContents: true
    )

    let quota: CustomQuota
    let clientIdentifier: String

    init(
        quota: CustomQuota,
        clientIdentifier: String
    ) {
        self.quota = quota
        self.clientIdentifier = clientIdentifier
    }

    var body: some View {
        VStack {
            HStack(spacing: 4) {
                ForEach(QuotaTierType.allCases) { tier in
                    Text(tier.rawValue)
                        .font(.caption2)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(
                            selectedCopyableTier == tier
                                ? Color.accentColor.opacity(0.2)
                                : Color.secondary.opacity(0.1)
                        )
                        .cornerRadius(4)
                        .onTapGesture {
                            selectedCopyableTier = tier
                        }
                }
            }

            HStack {
                StandardNotifyingButton(
                    type: .copy,
                    title: "short",
                    action: {
                        do {
                            let table = try quota.shortInputs(for: selectedCopyableTier, clientIdentifier: clientIdentifier) 
                            copyToClipboard(table)
                            shortCopyQuotaNotifier.setAndNotify(to: "copied")
                        } catch {
                            shortCopyQuotaNotifier.message = error.localizedDescription
                        }
                    },
                    notifier: shortCopyQuotaNotifier,
                    notifierPosition: .under
                )

                StandardNotifyingButton(
                    type: .copy,
                    title: "full",
                    action: {
                        do {
                            let table = try quota.quotaSummary(clientIdentifier: clientIdentifier)
                            copyToClipboard(table)
                            copyQuotaNotifier.setAndNotify(to: "copied")
                        } catch {
                            copyQuotaNotifier.message = error.localizedDescription
                        }
                    },
                    notifier: copyQuotaNotifier,
                    notifierPosition: .under
                )
            }
        }
    }
}
