import Foundation
import SwiftUI
import plate
import Interfaces
import ViewComponents
import Compositions
import Contacts
import Economics

struct ValuesPaneView: View, @preconcurrency Equatable {
    // observables (passed)
    @ObservedObject var apiPathVm: MailerAPISelectionViewModel
    @ObservedObject var weeklyScheduleVm: WeeklyScheduleViewModel
    @ObservedObject var quotaVm: QuotaViewModel

    // local state object inits
    @StateObject private var localPdfNotifier: NotificationBannerController = NotificationBannerController()
    @StateObject private var combinedPdfNotifier: NotificationBannerController = NotificationBannerController()
    @StateObject private var remotePdfNotifier: NotificationBannerController = NotificationBannerController()

    // passed properties
    @Binding var subject: String
    @Binding var fetchedHtml: String
    @Binding var includeQuoteInCustomMessage: Bool

    @Binding var showSuccessBanner: Bool
    @Binding var successBannerMessage: String
    @Binding var bannerColor: Color
    @Binding var isSendingEmail: Bool

    let anyInvalidConditionsCheck: Bool
    let emptySubjectWarning: Bool
    let finalHtmlContainsRawVariables: Bool

    let clientIdentifier: String

    let sendMailerEmail: () throws -> Void

    static func == (lhs: ValuesPaneView, rhs: ValuesPaneView) -> Bool {
        return lhs.subject                     == rhs.subject &&
               lhs.fetchedHtml                 == rhs.fetchedHtml &&
               lhs.includeQuoteInCustomMessage == rhs.includeQuoteInCustomMessage &&
               lhs.showSuccessBanner           == rhs.showSuccessBanner &&
               lhs.successBannerMessage        == rhs.successBannerMessage &&
               lhs.bannerColor                 == rhs.bannerColor &&
               lhs.isSendingEmail              == rhs.isSendingEmail &&
               lhs.anyInvalidConditionsCheck   == rhs.anyInvalidConditionsCheck &&
               lhs.emptySubjectWarning         == rhs.emptySubjectWarning &&
               lhs.finalHtmlContainsRawVariables == rhs.finalHtmlContainsRawVariables &&
               lhs.clientIdentifier            == rhs.clientIdentifier
    }

    var body: some View {
        VStack {
            if apiPathVm.selectedRoute == .custom {
                VStack(alignment: .leading) {

                    TextField("Subject", text: $subject)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    if (anyInvalidConditionsCheck && emptySubjectWarning) {
                        NotificationBanner(
                            type: .info,
                            message: "Empty subject"
                        )
                    }

                    Text("Template HTML").bold()

                    CodeEditorContainer(text: $fetchedHtml)

                    if (anyInvalidConditionsCheck && finalHtmlContainsRawVariables) {
                        NotificationBanner(
                            type: .warning,
                            message: "Raw html variables still in your message"
                        )
                    }

                    HStack {
                        StandardButton(
                            type: .clear, 
                            title: "Clear HTML", 
                            subtitle: "clears fetched html"
                        ) {
                            fetchedHtml = ""
                        }

                        Spacer()

                        if apiPathVm.selectedRoute == .custom {
                            StandardToggle(
                                style: .switch,
                                isOn: $includeQuoteInCustomMessage,
                                title: "Include quote",
                                subtitle: nil,
                                width: 150
                            )
                        }
                    }
                    .padding()
                }
                .padding()
            } else if apiPathVm.selectedRoute == .quote {
                VStack(alignment: .leading, spacing: 12) {
                    // 1) “Kilometers” field
                    StandardTextField(
                        "kilometers",
                        text: Binding<String>(
                            get:  { quotaVm.customQuotaInputs.travelCost.kilometers },
                            set:  { newValue in
                                quotaVm.customQuotaInputs.travelCost.kilometers = newValue
                            }
                        ),
                        placeholder: "45"
                    )

                    // 2) Prognosis / Local
                    HStack {
                        StandardTextField(
                            "prognosis",
                            text: Binding<String>(
                                get:  { quotaVm.customQuotaInputs.prognosis.count },
                                set:  { newValue in
                                    quotaVm.customQuotaInputs.prognosis.count = newValue
                                }
                            ),
                            placeholder: "5"
                        )
                        StandardTextField(
                            "local",
                            text: Binding<String>(
                                get:  { quotaVm.customQuotaInputs.prognosis.local },
                                set:  { newValue in
                                    quotaVm.customQuotaInputs.prognosis.local = newValue
                                }
                            ),
                            placeholder: "4"
                        )
                    }

                    // 3) Suggestion / Local
                    HStack {
                        StandardTextField(
                            "suggestion",
                            text: Binding<String>(
                                get:  { quotaVm.customQuotaInputs.suggestion.count },
                                set:  { newValue in
                                    quotaVm.customQuotaInputs.suggestion.count = newValue
                                }
                            ),
                            placeholder: "3"
                        )
                        StandardTextField(
                            "local",
                            text: Binding<String>(
                                get:  { quotaVm.customQuotaInputs.suggestion.local },
                                set:  { newValue in
                                    quotaVm.customQuotaInputs.suggestion.local = newValue
                                }
                            ),
                            placeholder: "2"
                        )
                    }

                    // Singular / Local
                    HStack {
                        StandardTextField(
                            "singular",
                            text: Binding<String>(
                                get:  { quotaVm.customQuotaInputs.singular.count },
                                set:  { newValue in
                                    quotaVm.customQuotaInputs.singular.count = newValue
                                }
                            ),
                            placeholder: "1"
                        )
                        StandardTextField(
                            "local",
                            text: Binding<String>(
                                get:  { quotaVm.customQuotaInputs.singular.local },
                                set:  { newValue in
                                    quotaVm.customQuotaInputs.singular.local = newValue
                                }
                            ),
                            placeholder: "0"
                        )
                    }


                    // 4) Base
                    StandardTextField(
                        "base",
                        text: Binding<String>(
                            get:  { quotaVm.customQuotaInputs.base },
                            set:  { newValue in
                                quotaVm.customQuotaInputs.base = newValue
                            }
                        ),
                        placeholder: "350"
                    )

                    // 5) Travel‐cost fields
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Travel Cost Inputs").bold()
                        HStack {
                            StandardTextField(
                                "speed",
                                text: Binding<String>(
                                    get:  { quotaVm.customQuotaInputs.travelCost.speed },
                                    set:  { newValue in
                                        quotaVm.customQuotaInputs.travelCost.speed = newValue
                                    }
                                ),
                                placeholder: "80.0"
                            )
                            StandardTextField(
                                "rate/travel",
                                text: Binding<String>(
                                    get:  { quotaVm.customQuotaInputs.travelCost.rates.travel },
                                    set:  { newValue in
                                        quotaVm.customQuotaInputs.travelCost.rates = TravelCostRatesInputs(
                                            travel: newValue,
                                            time: quotaVm.customQuotaInputs.travelCost.rates.time
                                        )
                                    }
                                ),
                                placeholder: "0.25"
                            )
                            StandardTextField(
                                "rate/time",
                                text: Binding<String>(
                                    get:  { quotaVm.customQuotaInputs.travelCost.rates.time },
                                    set:  { newValue in
                                        quotaVm.customQuotaInputs.travelCost.rates = TravelCostRatesInputs(
                                            travel: quotaVm.customQuotaInputs.travelCost.rates.travel,
                                            time: newValue
                                        )
                                    }
                                ),
                                placeholder: "105"
                            )
                        }
                    }
                    .padding(.top, 8)

                    // 6) Decide what to show:
                    if quotaVm.isLoading {
                        ProgressView("Computing quota…")
                            .padding(.top, 16)
                    }

                    if !(quotaVm.errorMessage.isEmpty) {
                        if quotaVm.hasEmptyInputs {
                            NotificationBanner(
                                type: .info,
                                message: "Enter inputs"
                            )
                        } else {
                            NotificationBanner(
                                type: .warning,
                                message: quotaVm.errorMessage
                            )
                        }
                    }

                    else if let quota = quotaVm.loadedQuota {
                        QuotaTierListView(quota: quota)
                            .padding(.top, 16)

                        HStack(alignment: .center, spacing: 45) {
                            // Spacer()

                            SelectableTierView(
                                quota: quota,
                                clientIdentifier: clientIdentifier
                            )


                            VStack {
                                StandardButton(
                                    type: .execute,
                                    title: "Render Local",
                                    action: {
                                        do {
                                            withAnimation {
                                                localPdfNotifier.show = false
                                            }

                                            try renderTier(quota: quota, for: .local)

                                            localPdfNotifier.message = "quota pdf rendered"
                                            localPdfNotifier.style = .success
                                            withAnimation {
                                                localPdfNotifier.show = true
                                            }

                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                withAnimation { 
                                                    localPdfNotifier.show = false
                                                }
                                            }
                                        } catch {
                                            withAnimation {
                                                localPdfNotifier.show = false
                                            }

                                            localPdfNotifier.message = "render failed: \(error)"
                                            localPdfNotifier.style = .error
                                            withAnimation {
                                                localPdfNotifier.show = true
                                            }

                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                withAnimation { 
                                                    localPdfNotifier.show = false 
                                                }
                                            }
                                        }
                                    }
                                )
                                .disabled((quotaVm.loadedQuota == nil))
                                .padding(.top, 8)

                                NotificationBanner(
                                    type: localPdfNotifier.style,
                                    message: localPdfNotifier.message
                                )
                                .hide(when: localPdfNotifier.hide)
                            }

                            VStack {
                                StandardButton(
                                    type: .execute,
                                    title: "Render Combined",
                                    action: {
                                        do {
                                            withAnimation {
                                                combinedPdfNotifier.show = false
                                            }

                                            try renderTier(quota: quota, for: .combined)

                                            combinedPdfNotifier.message = "quota pdf rendered"
                                            combinedPdfNotifier.style = .success
                                            withAnimation {
                                                combinedPdfNotifier.show = true
                                            }

                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                withAnimation { 
                                                    combinedPdfNotifier.show = false
                                                }
                                            }
                                        } catch {
                                            withAnimation {
                                                combinedPdfNotifier.show = false
                                            }

                                            combinedPdfNotifier.message = "render failed: \(error)"
                                            combinedPdfNotifier.style = .error
                                            withAnimation {
                                                combinedPdfNotifier.show = true
                                            }

                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                withAnimation { 
                                                    combinedPdfNotifier.show = false 
                                                }
                                            }
                                        }
                                    }
                                )
                                .disabled((quotaVm.loadedQuota == nil))
                                .padding(.top, 8)

                                NotificationBanner(
                                    type: combinedPdfNotifier.style,
                                    message: combinedPdfNotifier.message
                                )
                                .hide(when: combinedPdfNotifier.hide)
                            }

                            VStack {
                                StandardButton(
                                    type: .execute,
                                    title: "Render Remote",
                                    action: {
                                        do {
                                            withAnimation {
                                                remotePdfNotifier.show = false
                                            }

                                            try renderTier(quota: quota, for: .remote)

                                            remotePdfNotifier.message = "quota pdf rendered"
                                            remotePdfNotifier.style = .success
                                            withAnimation {
                                                remotePdfNotifier.show = true
                                            }

                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                withAnimation { 
                                                    remotePdfNotifier.show = false
                                                }
                                            }
                                        } catch {
                                            withAnimation {
                                                remotePdfNotifier.show = false
                                            }

                                            remotePdfNotifier.message = "render failed: \(error)"
                                            remotePdfNotifier.style = .error
                                            withAnimation {
                                                remotePdfNotifier.show = true
                                            }

                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                withAnimation { 
                                                    remotePdfNotifier.show = false 
                                                }
                                            }
                                        }
                                    }
                                )
                                .disabled((quotaVm.loadedQuota == nil))
                                .padding(.top, 8)

                                NotificationBanner(
                                    type: remotePdfNotifier.style,
                                    message: remotePdfNotifier.message
                                )
                                .hide(when: remotePdfNotifier.hide)
                            }
                            .padding(.trailing, 40)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    else {
                        NotificationBanner(
                            type: .info,
                            message: "Enter quote values above"
                        )
                        .padding(.top, 16)
                    }
                }
                .padding()
            } else {

                if apiPathVm.endpointNeedsAvailabilityVariable {
                    VStack(alignment: .leading, spacing: 8) {
                        WeeklyScheduleView(viewModel: weeklyScheduleVm)
                    }
                    .padding(.vertical, 8)
                }
            }

            Spacer()

            if showSuccessBanner {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: bannerColor == .green
                                ? "checkmark.circle.fill"
                                : "xmark.octagon.fill")
                        .foregroundColor(.white)
                        Text(successBannerMessage)
                        .foregroundColor(.white)
                    }
                    .padding()
                    .background(bannerColor)
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

                if apiPathVm.selectedRoute == .invoice && apiPathVm.selectedEndpoint == .expired {
                    NotificationBanner(
                        type: .warning,
                        message: "You are sending an overdue reminder"
                    )
                }

                HStack {
                    StandardEscapableButton(
                        type: .execute, 
                        title: "Run mailer", 
                        cancelTitle: "Do not run mailer yet", 
                        subtitle: "Starts mailer background process"
                    ) {
                        do {
                            try sendMailerEmail()
                        } catch {
                            print(error)
                        }
                    }
                    .disabled(
                        isSendingEmail || 
                        anyInvalidConditionsCheck || 
                        apiPathVm.routeOrEndpointIsNil()
                    )
                }
                .padding(.top, 10)

                HStack {
                    NotificationBanner(
                        type: .warning,
                        message: "No endpoint selected"
                    )
                    .hide(when: !apiPathVm.routeOrEndpointIsNil())
                }
            }
        }
        .frame(minWidth: 500)
    }
}
