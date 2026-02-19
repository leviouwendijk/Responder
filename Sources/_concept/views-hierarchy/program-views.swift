import SwiftUI

import Implementations
@preconcurrency import Contacts
import Compositions

public enum ViewVariables {
    static let program_caption_size: CGFloat = 12
}

public struct ProgramEditorView: View {
    @StateObject private var vm = ProgramEditorViewModel(program: [
        PrebuiltPackage.startersvaardigheden,
        // PrebuiltPackage.hervorming(target: .angst)
    ])

    @State private var exportError: String?
    @State private var exportResultPath: String?

    // Contacts (isolated for now; later can be swapped for shared context)
    @StateObject private var contactsVm = ContactsListViewModel()
    @State private var selectedContact: CNContact?
    @State private var showContactPicker = false

    // Identity (isolated for now; later can be swapped for shared context)
    @State private var clientName: String = ""
    @State private var dogName: String = ""

    // Dog name editing is in this view (subtle; no new sidebar sections)
    @State private var showDogNameEditor = false
    // Client name editing (manual override when contact isn't used / isn't found)
    @State private var showClientNameEditor = false

    public init() {}

    public var body: some View {
        NavigationSplitView {
            // PackageListView(vm: vm)
            PackageListView(
                vm: vm,
                contactLabel: sidebarContactLabel(),
                dogLabel: sidebarDogLabel()
            )
        } detail: {
            if let index = vm.selectedPackageIndex {
                PackageEditorView(package: $vm.program[index])
            } else {
                ContentUnavailableView("Selecteer een pakket", systemImage: "square.stack.3d.up")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                contactToolbarItems()
                dogToolbarItems()

                Button("Export") {
                    do {
                        // let dest = try ProgramExport.export(
                        //     program: vm.program,
                        //     request: .init(
                        //         output: FileManager.default.currentDirectoryPath,
                        //         // title: "Programma-overzicht",
                        //         filename: "programma-overzicht",
                        //         margins: 35,
                        //         estimateBand: vm.estimateBand,
                        //         tallyPlacements: vm.tallyPlacements,
                        //         sessionDuration: vm.sessionDuration
                        //     )
                        // )

                        let dest = try ProgramExport.export(
                            program: vm.program,
                            request: .init(
                                output: FileManager.default.currentDirectoryPath,
                                filename: "programma-overzicht",
                                margins: 35,
                                estimateBand: vm.estimateBand,
                                tallyPlacements: vm.tallyPlacements,
                                sessionDuration: vm.sessionDuration,
                                sessionRate: vm.sessionRate,
                                homeSessions: vm.homeSessions,
                                travelDistanceKm: vm.travelDistanceKm,
                                travelRatePerKm: vm.travelRatePerKm,
                                includePriceInProgram: vm.includePriceInProgram,
                                pricingStrategy: vm.pricingStrategy,
                                midpointMarginPercent: vm.midpointMarginPercent,
                                weightedHighWeightPercent: vm.weightedHighWeightPercent,
                                weightedMarginPercent: vm.weightedMarginPercent,

                                // identity (still isolated in Program tab for now)
                                clientName: effectiveClientName(),
                                dogName: effectiveDogName()
                            )
                        )

                        exportResultPath = dest.path
                    } catch {
                        exportError = error.localizedDescription
                    }
                }
            }
        }
        .alert("Export gelukt", isPresented: Binding(
            get: { exportResultPath != nil },
            set: { if !$0 { exportResultPath = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportResultPath ?? "")
        }
        .alert("Export mislukt", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
        .sheet(item: $vm.swapTarget) { target in
            ComponentLibraryView(
                title: "Wissel component",
                current: target.current,
                onPick: { picked in
                    vm.commitSwap(newComponent: picked)
                },
                onCancel: {
                    vm.swapTarget = nil
                }
            )
        }
        .sheet(isPresented: $showContactPicker) {
            contactPickerSheet()
        }
        .sheet(isPresented: $showClientNameEditor) {
            clientNameEditorSheet()
        }
        .sheet(isPresented: $showDogNameEditor) {
            dogNameEditorSheet()
        }
    }

    // Contacts UI (isolated; later can read/write shared selection state)

    @ViewBuilder
    private func contactToolbarItems() -> some View {
        // Contacts picker
        Button {
            showContactPicker = true
        } label: {
            Image(systemName: selectedContact == nil
                ? "person.text.rectangle"
                : "person.text.rectangle.fill"
            )
        }
        .help(selectedContact == nil ? "Selecteer contact" : "Wijzig contact")

        // Manual override (client name)
        Button {
            showClientNameEditor = true
        } label: {
            let hasName = !(clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Image(systemName: hasName
                ? "person.crop.circle.badge.checkmark"
                : "person.crop.circle.badge.plus"
            )
        }
        .help("Zet clientnaam")

        if selectedContact != nil {
            Button { clearSelectedContact() } label: {
                Image(systemName: "xmark.circle.fill").imageScale(.medium)
            }
            .buttonStyle(.plain)
            .help("Wis contact")
        } else if !(clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
            Button { clientName = "" } label: {
                Image(systemName: "xmark.circle.fill").imageScale(.medium)
            }
            .buttonStyle(.plain)
            .help("Wis clientnaam")
        }
    }

    private func contactPickerSheet() -> some View {
        NavigationStack {
            ContactsListView(
                viewmodel: contactsVm,
                maxListHeight: 520,
                onSelect: { contact in
                    applySelectedContact(contact)
                    showContactPicker = false
                },
                onDeselect: {
                    clearSelectedContact()
                },
                autoScrollToTop: true,
                hideSearchStrictness: false
            )
            .navigationTitle("Selecteer contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") {
                        showContactPicker = false
                    }
                }

                if selectedContact != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Wis") {
                            clearSelectedContact()
                        }
                    }
                }
            }
            .frame(minWidth: 640, minHeight: 640)
        }
    }

    private func clientNameEditorSheet() -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Client")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Clientnaam", text: $clientName)
                        .textFieldStyle(.roundedBorder)
                }

                Text("dev note: dit is los van Contacts. Later kunnen we dit koppelen aan gedeelde state.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle("Clientnaam")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") {
                        showClientNameEditor = false
                    }
                }

                if !(clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Wis") {
                            clientName = ""
                        }
                    }
                }
            }
            .frame(minWidth: 420, minHeight: 220)
        }
    }

    // Dog UI (subtle: a single button; actual editing happens in a sheet)

    @ViewBuilder
    private func dogToolbarItems() -> some View {
        Button {
            showDogNameEditor = true
        } label: {
            Image(systemName: effectiveDogName().isEmpty || effectiveDogName() == "—" ? "pawprint" : "pawprint.fill")
        }
        .help(effectiveDogName().isEmpty || effectiveDogName() == "—" ? "Zet hondnaam" : "Wijzig hondnaam")

        if !(dogName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
            Button {
                dogName = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.medium)
            }
            .buttonStyle(.plain)
            .help("Wis hondnaam")
        }
    }

    private func dogNameEditorSheet() -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hond")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Hondnaam", text: $dogName)
                        .textFieldStyle(.roundedBorder)
                }

                Text("dev note: dit is los van Contacts. Later kunnen we dit koppelen aan gedeelde state.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle("Hondnaam")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") {
                        showDogNameEditor = false
                    }
                }

                if !(dogName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Wis") {
                            dogName = ""
                        }
                    }
                }
            }
            .frame(minWidth: 420, minHeight: 220)
        }
    }

    // Selection → identity mapping (still isolated here)

//     private func applySelectedContact(_ contact: CNContact) {
//         selectedContact = contact

//         let display = contactDisplayName(contact)
//         if !display.isEmpty {
//             clientName = display
//         } else {
//             clientName = ""
//         }
//     }

    private func applySelectedContact(_ contact: CNContact) {
        selectedContact = contact

        let parsed = parseContactIdentity(contact)

        clientName = parsed.client
        dogName = parsed.dog ?? ""
    }

    private func clearSelectedContact() {
        selectedContact = nil
        clientName = ""
        dogName = ""
    }

    private func contactDisplayName(_ c: CNContact) -> String {
        let parsed = parseContactIdentity(c)
        return parsed.client.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "—" : parsed.client
    }

    // private func contactDisplayName(_ c: CNContact) -> String {
    //     let g = c.givenName.trimmingCharacters(in: .whitespacesAndNewlines)
    //     let f = c.familyName.trimmingCharacters(in: .whitespacesAndNewlines)

    //     let name = [g, f].filter { !$0.isEmpty }.joined(separator: " ")
    //     if !name.isEmpty { return name }

    //     if let email = c.emailAddresses.first?.value as String?, !email.isEmpty {
    //         return email
    //     }

    //     return ""
    // }

    private func effectiveClientName() -> String {
        let s = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? "—" : s
    }

    private func effectiveDogName() -> String {
        let s = dogName.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? "—" : s
    }

    private func sidebarContactLabel() -> String {
        if let c = selectedContact {
            let name = contactDisplayName(c).trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty || name == "—" ? "—" : name
        }
        return "—"
    }

    private func sidebarDogLabel() -> String {
        let s = effectiveDogName().trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty || s == "—" ? "—" : s
    }

    // SPLITTING HELPERS FOR NOW
    private func parseContactIdentity(_ c: CNContact) -> (client: String, dog: String?) {
        let given = c.givenName.trimmingCharacters(in: .whitespacesAndNewlines)
        let family = c.familyName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Your convention: "<PERSON> | <DOG>" stored in givenName
        if let (left, right) = splitPipe(given) {
            let client = joinName(left, family)
            let dog = right.trimmingCharacters(in: .whitespacesAndNewlines)
            return (client: client.isEmpty ? fallbackClientName(c) : client,
                    dog: dog.isEmpty ? nil : dog)
        }

        // No pipe: normal contact name, and dog is unknown (defaults to "—" via effectiveDogName()).
        let client = fallbackClientName(c)
        return (client: client, dog: nil)
    }

    private func splitPipe(_ s: String) -> (left: String, right: String)? {
        // Only accept if we have a non-empty left side.
        let parts = s.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }

        let left = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        let right = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !left.isEmpty else { return nil }
        return (left, right)
    }

    private func joinName(_ given: String, _ family: String) -> String {
        if family.isEmpty { return given }
        if given.isEmpty { return family }
        return "\(given) \(family)"
    }

    private func fallbackClientName(_ c: CNContact) -> String {
        let given = c.givenName.trimmingCharacters(in: .whitespacesAndNewlines)
        let family = c.familyName.trimmingCharacters(in: .whitespacesAndNewlines)

        let full = joinName(given, family).trimmingCharacters(in: .whitespacesAndNewlines)
        if !full.isEmpty { return full }

        // Optional: email fallback if you want it
        if let email = c.emailAddresses.first?.value as String? {
            let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
            if !e.isEmpty { return e }
        }

        return "—"
    }
}

private struct BandAnchorsHeader: View {
    let band: ProgramTally.EstimateBand

    var body: some View {
        let excluded = band.excludedAnchor

        HStack(spacing: 8) {
            anchorBox(.low, excluded: excluded)
            anchorBox(.medium, excluded: excluded)
            anchorBox(.high, excluded: excluded)
        }
    }

    @ViewBuilder
    private func anchorBox(
        _ a: ProgramTally.EstimateBand.Anchor,
        excluded: ProgramTally.EstimateBand.Anchor
    ) -> some View {
        let isExcluded = (a == excluded)

        Text(a.title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
            )
            .opacity(isExcluded ? 0.25 : 1.0)
    }
}

private struct PricingBreakdown: View {
    @ObservedObject var vm: ProgramEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Berekening")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                breakdownCard(
                    title: "Weighted",
                    isActive: vm.pricingStrategy == .weighted_average,
                    debug: vm.pricingDebugWeighted,
                    baseLine: vm.pricingDebugWeighted.formulaLine(
                        strategy: .weighted_average,
                        weightedHighWeightPercent: vm.weightedHighWeightPercent
                    )
                )

                breakdownCard(
                    title: "Midpoint",
                    isActive: vm.pricingStrategy == .midpoint,
                    debug: vm.pricingDebugMidpoint,
                    baseLine: vm.pricingDebugMidpoint.formulaLine(
                        strategy: .midpoint,
                        weightedHighWeightPercent: vm.weightedHighWeightPercent
                    )
                )
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func breakdownCard(
        title: String,
        isActive: Bool,
        debug: ProgramEditorViewModel.PricingDebug,
        baseLine: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(isActive ? "actief" : "niet actief")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Group {
                line("band", debug.bandLine)
                line("base", debug.baseLine)

                line("formule", baseLine)

                line("ceil → sessies", "\(debug.sessionsCeiled) sess")

                Divider().padding(.vertical, 2)

                line("sessiekosten", debug.sessionCostLine(formatMoney: vm.formatMoney))
                line("reis", debug.travelCostLine(formatMoney: vm.formatMoney))
                line("subtotaal", debug.subtotalLine(formatMoney: vm.formatMoney))
                line("marge", debug.marginLine)
                line("markup", debug.markupLine(formatMoney: vm.formatMoney))
                line("totaal", debug.totalLine(formatMoney: vm.formatMoney))

                line(
                    "afronden",
                    debug.roundedTotalLine(
                        toNearest: vm.priceRoundingStep,
                        formatMoney: vm.formatMoney
                    )
                )
            }
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(isActive ? 1.0 : 0.55)
    }

    @ViewBuilder
    private func line(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

public struct PackageListView: View {
    @ObservedObject public var vm: ProgramEditorViewModel
    
    public let contactLabel: String
    public let dogLabel: String

    public init(
        vm: ProgramEditorViewModel,
        contactLabel: String,
        dogLabel: String
    ) {
        self.vm = vm
        self.contactLabel = contactLabel
        self.dogLabel = dogLabel
    }

    // public init(vm: ProgramEditorViewModel) {
    //     self.vm = vm
    // }

    public var body: some View {
        List(selection: $vm.selectedPackageID) {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        sidebarIdentityLine(label: "Contact", value: contactLabel)
                        sidebarIdentityLine(label: "Dog", value: dogLabel)
                    }
                    .padding(.bottom, 4)

                    HStack(alignment: .firstTextBaseline) {

                        Text("Sessies (schatting)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(programSessionsLabel())
                            .font(.subheadline)
                            .monospacedDigit()
                    }


                    VStack(alignment: .leading, spacing: 8) {
                        BandAnchorsHeader(band: vm.estimateBand)

                        ScrollView(.horizontal, showsIndicators: false) {
                            // Picker("Band", selection: $vm.estimateBand) {
                            //     Text("Low–High").tag(ProgramTally.EstimateBand.low_high)
                            //     Text("Low–Medium").tag(ProgramTally.EstimateBand.low_medium)
                            //     Text("Medium–High").tag(ProgramTally.EstimateBand.medium_high)
                            // }
                            Picker("Band", selection: $vm.estimateBand) {
                                Text(ProgramTally.EstimateBand.low_medium.field_label_range_visual)
                                    .tag(ProgramTally.EstimateBand.low_medium)

                                Text(ProgramTally.EstimateBand.low_high.field_label_range_visual)
                                    .tag(ProgramTally.EstimateBand.low_high)

                                Text(ProgramTally.EstimateBand.medium_high.field_label_range_visual)
                                    .tag(ProgramTally.EstimateBand.medium_high)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 2)
                        }
                        .scrollClipDisabled()
                    }

                    MultiSelectList(
                        title: "Tally",
                        all: ModuleComponentPlacement.allCases,
                        selected: $vm.tallyPlacements,
                        label: { placement in
                            switch placement {
                            case .elementary: return "Standaard"
                            case .exchangeable: return "Inwisselbaar"
                            }
                        }
                    )
                }
                .padding(.vertical, 4)
                .padding(.trailing, 6)
            }

            Section("Prijs") {
                VStack(alignment: .leading, spacing: 10) {

                    // Toggle row (same visual language as MultiSelectList rows)
                    Button {
                        vm.includePriceInProgram.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: vm.includePriceInProgram ? "checkmark.circle.fill" : "circle")
                                .imageScale(.medium)

                            Text("Prijs opnemen in programma")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Divider()
                        .padding(.vertical, 2)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Sessie-tarief")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("", value: $vm.sessionRate, format: .number.precision(.fractionLength(2)))
                                .multilineTextAlignment(.trailing)
                                .frame(width: 110)
                        }

                        HStack {
                            Text("Thuis-sessies")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("", value: $vm.homeSessions, format: .number)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 110)
                        }

                        HStack {
                            Text("Reisafstand (km)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("", value: $vm.travelDistanceKm, format: .number.precision(.fractionLength(1)))
                                .multilineTextAlignment(.trailing)
                                .frame(width: 110)
                        }

                        HStack {
                            Text("Tarief per km")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("", value: $vm.travelRatePerKm, format: .number.precision(.fractionLength(2)))
                                .multilineTextAlignment(.trailing)
                                .frame(width: 110)
                        }

                        Divider()
                            .padding(.vertical, 2)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Prijsstrategie")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                Picker("Prijsstrategie", selection: $vm.pricingStrategy) {
                                    Text(PricingStrategy.weighted_average.title)
                                        .tag(PricingStrategy.weighted_average)

                                    Text(PricingStrategy.midpoint.title)
                                        .tag(PricingStrategy.midpoint)
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 2)
                            }
                            .scrollClipDisabled()

                            // Weighted settings (visible, disabled when not selected)
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("high weight (%)")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    TextField(
                                        "",
                                        value: $vm.weightedHighWeightPercent,
                                        format: .number.precision(.fractionLength(0))
                                    )
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 110)
                                }

                                HStack {
                                    Text("marge (%)")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    TextField(
                                        "",
                                        value: $vm.weightedMarginPercent,
                                        format: .number.precision(.fractionLength(0))
                                    )
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 110)
                                }
                            }
                            .disabled(vm.pricingStrategy != .weighted_average)
                            .opacity(vm.pricingStrategy == .weighted_average ? 1.0 : 0.45)

                            // Midpoint settings (visible, disabled when not selected)
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("marge (%)")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    TextField(
                                        "",
                                        value: $vm.midpointMarginPercent,
                                        format: .number.precision(.fractionLength(0))
                                    )
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 110)
                                }
                            }
                            .disabled(vm.pricingStrategy != .midpoint)
                            .opacity(vm.pricingStrategy == .midpoint ? 1.0 : 0.45)
                        }

                        PricingBreakdown(vm: vm)

                        Divider()
                            .padding(.vertical, 2)

                        HStack(alignment: .firstTextBaseline) {
                            Text("Schatting (prijs)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(vm.estimatedTotalCostLabel)
                                    .font(.subheadline)
                                    .monospacedDigit()

                                Text(vm.estimatedTotalCostRoundedLine)
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(!vm.includePriceInProgram)
                    .opacity(vm.includePriceInProgram ? 1.0 : 0.45)
                }
                .padding(.vertical, 4)
                .padding(.trailing, 6)
            }

            // Section("Prijs") {
            //     VStack(alignment: .leading, spacing: 10) {
            //         HStack {
            //             Text("Sessie-tarief")
            //                 .foregroundStyle(.secondary)
            //             Spacer()
            //             TextField("", value: $vm.sessionRate, format: .number.precision(.fractionLength(2)))
            //                 .multilineTextAlignment(.trailing)
            //                 .frame(width: 110)
            //         }

            //         HStack {
            //             Text("Thuis-sessies")
            //                 .foregroundStyle(.secondary)
            //             Spacer()
            //             TextField("", value: $vm.homeSessions, format: .number)
            //                 .multilineTextAlignment(.trailing)
            //                 .frame(width: 110)
            //         }

            //         HStack {
            //             Text("Reisafstand (km)")
            //                 .foregroundStyle(.secondary)
            //             Spacer()
            //             TextField("", value: $vm.travelDistanceKm, format: .number.precision(.fractionLength(1)))
            //                 .multilineTextAlignment(.trailing)
            //                 .frame(width: 110)
            //         }

            //         HStack {
            //             Text("Tarief per km")
            //                 .foregroundStyle(.secondary)
            //             Spacer()
            //             TextField("", value: $vm.travelRatePerKm, format: .number.precision(.fractionLength(2)))
            //                 .multilineTextAlignment(.trailing)
            //                 .frame(width: 110)
            //         }

            //         Divider()
            //             .padding(.vertical, 2)

            //         HStack(alignment: .firstTextBaseline) {
            //             Text("Schatting (band high)")
            //                 .font(.subheadline)
            //                 .foregroundStyle(.secondary)

            //             Spacer()

            //             Text(vm.estimatedTotalCostLabel)
            //                 .font(.subheadline)
            //                 .monospacedDigit()
            //         }
            //     }
            //     .padding(.vertical, 4)
            //     .padding(.trailing, 6)
            // }

            Section("Pakketsamenstelling") {
                ForEach(vm.program) { pkg in
                    PackageRow(
                        title: pkg.title,
                        canMoveUp: canMovePackageUp(pkgID: pkg.id),
                        canMoveDown: canMovePackageDown(pkgID: pkg.id),
                        onMoveUp: { movePackageUp(pkgID: pkg.id) },
                        onMoveDown: { movePackageDown(pkgID: pkg.id) },
                        onDelete: { deletePackageByID(pkg.id) }
                    )
                    .tag(pkg.id)
                    .contextMenu {
                        Button("Verwijder pakket") {
                            deletePackageByID(pkg.id)
                        }
                    }
                }
                .onDelete { offsets in
                    withAnimation {
                        vm.deletePackage(at: offsets)
                    }
                }
            }

            Section("Templates") {
                Button("Startersvaardigheden") {
                    vm.addTemplate(PrebuiltPackage.startersvaardigheden)
                }

                Menu("Hervorming") {
                    ForEach(BehaviorProblem.allCases, id: \.self) { problem in
                        Button(problem.rawValue) {
                            vm.addTemplate(PrebuiltPackage.hervorming(target: problem))
                        }
                    }
                }
            }

            Section("Custom") {
                Button("Nieuw pakket") {
                    vm.addCustomPackage()
                }
            }
        }
        .navigationTitle("Programma")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    deleteSelectedPackage()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(vm.selectedPackageID == nil)
                .help("Verwijder geselecteerd pakket")
            }
        }
        .onDeleteCommand {
            deleteSelectedPackage()
        }
    }

    private func programSessionsLabel(sessionDuration: Int = 60) -> String {
        let r = ProgramTally.sessions(
            program: vm.program.filter { $0.include },
            sessionDuration: sessionDuration,
            band: vm.estimateBand,
            placements: vm.tallyPlacements
        ).rounded

        if r.low == 0 && r.high == 0 { return "—" }
        if r.low == r.high { return "\(r.low)" }
        return "\(r.low)–\(r.high)"
    }

    private func deleteSelectedPackage() {
        guard let id = vm.selectedPackageID else { return }
        deletePackageByID(id)
    }

    private func deletePackageByID(_ id: Package.ID) {
        guard let idx = vm.program.firstIndex(where: { $0.id == id }) else { return }

        _ = withAnimation {
            vm.program.remove(at: idx)
        }

        if vm.program.indices.contains(idx) {
            vm.selectedPackageID = vm.program[idx].id
        } else {
            vm.selectedPackageID = vm.program.last?.id
        }
    }

    private func canMovePackageUp(pkgID: Package.ID) -> Bool {
        guard let idx = vm.program.firstIndex(where: { $0.id == pkgID }) else { return false }
        return idx > 0
    }

    private func canMovePackageDown(pkgID: Package.ID) -> Bool {
        guard let idx = vm.program.firstIndex(where: { $0.id == pkgID }) else { return false }
        return idx + 1 < vm.program.count
    }

    private func movePackageUp(pkgID: Package.ID) {
        guard let idx = vm.program.firstIndex(where: { $0.id == pkgID }) else { return }
        guard idx > 0 else { return }
        withAnimation {
            vm.program.swapAt(idx, idx - 1)
        }
    }

    private func movePackageDown(pkgID: Package.ID) {
        guard let idx = vm.program.firstIndex(where: { $0.id == pkgID }) else { return }
        guard idx + 1 < vm.program.count else { return }
        withAnimation {
            vm.program.swapAt(idx, idx + 1)
        }
    }

    @ViewBuilder
    private func sidebarIdentityLine(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(label):")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value == "—" ? "<none>" : value)
                .font(.subheadline)
                .monospacedDigit()
        }
    }
}

private struct PackageRow: View {
    public let title: String
    public let canMoveUp: Bool
    public let canMoveDown: Bool
    public let onMoveUp: () -> Void
    public let onMoveDown: () -> Void
    public let onDelete: () -> Void

    public var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onMoveUp()
            } label: {
                Text("↑")
            }
            .buttonStyle(.plain)
            .disabled(!canMoveUp)

            Button {
                onMoveDown()
            } label: {
                Text("↓")
            }
            .buttonStyle(.plain)
            .disabled(!canMoveDown)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .help("Verwijder pakket")
        }
    }
}

// private struct PackageRow: View {
//     public let title: String
//     public let canMoveUp: Bool
//     public let canMoveDown: Bool
//     public let onMoveUp: () -> Void
//     public let onMoveDown: () -> Void

//     public var body: some View {
//         HStack(spacing: 8) {
//             Text(title)
//                 .frame(maxWidth: .infinity, alignment: .leading)

//             Button("↑") { onMoveUp() }
//                 .buttonStyle(.plain)
//                 .disabled(!canMoveUp)

//             Button("↓") { onMoveDown() }
//                 .buttonStyle(.plain)
//                 .disabled(!canMoveDown)
//         }
//     }
// }

@MainActor
public extension ProgramEditorViewModel {
    func addCustomPackage() {
        let p = Package(
            title: "Nieuw pakket",
            modules: [
                Module(entries: [])
            ]
        )

        program.append(p)
        selectedPackageID = p.id
    }
}

// MARK: - Package editor

public struct PackageEditorView: View {
    @Binding public var package: Package

    public init(package: Binding<Package>) {
        self._package = package
    }

    // public var body: some View {
    //     VStack(alignment: .leading, spacing: 12) {
    //         HStack(spacing: 12) {
    //             TextField("Pakket titel", text: $package.title)
    //                 .textFieldStyle(.roundedBorder)
    //                 .font(.title3)

    //             Spacer()

    //             Button {
    //                 withAnimation {
    //                     package.modules.append(Module(entries: []))
    //                 }
    //             } label: {
    //                 Label("Nieuw module", systemImage: "plus")
    //             }
    //             .buttonStyle(.bordered)
    //         }
    //         .padding(.horizontal)
    //         .padding(.top, 8)

    //         VStack(alignment: .leading, spacing: 16) {
    //             ForEach($package.modules) { $m in
    //                 let id = m.id
    //                 let idx = package.modules.firstIndex(where: { $0.id == id }) ?? 0

    //                 ModuleBoxView(
    //                     moduleIndex: idx,
    //                     moduleCount: package.modules.count,
    //                     module: $m,
    //                     onDeleteModule: {
    //                         guard let i = package.modules.firstIndex(where: { $0.id == id }) else { return }
    //                         _ = withAnimation {
    //                             package.modules.remove(at: i)
    //                         }
    //                     },
    //                     onMoveUp: {
    //                         guard let i = package.modules.firstIndex(where: { $0.id == id }) else { return }
    //                         guard i > 0 else { return }
    //                         withAnimation {
    //                             package.modules.swapAt(i, i - 1)
    //                         }
    //                     },
    //                     onMoveDown: {
    //                         guard let i = package.modules.firstIndex(where: { $0.id == id }) else { return }
    //                         guard i + 1 < package.modules.count else { return }
    //                         withAnimation {
    //                             package.modules.swapAt(i, i + 1)
    //                         }
    //                     }
    //                 )
    //                 .padding(.horizontal)
    //             }
    //         }
    //         .padding(.vertical, 8)

    //         Spacer(minLength: 0)
    //     }
    //     .navigationTitle(package.title)
    // }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                TextField("Pakket titel", text: $package.title)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)

                Spacer()

                Button {
                    withAnimation {
                        package.modules.append(Module(entries: []))
                    }
                } label: {
                    Label("Nieuw module", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()
                .padding(.horizontal)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach($package.modules) { $m in
                        let id = m.id
                        let idx = package.modules.firstIndex(where: { $0.id == id }) ?? 0

                        ModuleBoxView(
                            moduleIndex: idx,
                            moduleCount: package.modules.count,
                            module: $m,
                            onDeleteModule: {
                                guard let i = package.modules.firstIndex(where: { $0.id == id }) else { return }
                                _ = withAnimation {
                                    package.modules.remove(at: i)
                                }
                            },
                            onMoveUp: {
                                guard let i = package.modules.firstIndex(where: { $0.id == id }) else { return }
                                guard i > 0 else { return }
                                withAnimation {
                                    package.modules.swapAt(i, i - 1)
                                }
                            },
                            onMoveDown: {
                                guard let i = package.modules.firstIndex(where: { $0.id == id }) else { return }
                                guard i + 1 < package.modules.count else { return }
                                withAnimation {
                                    package.modules.swapAt(i, i + 1)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
        }
        .navigationTitle(package.title)
    }
}

public struct ModuleBoxView: View {
    public let moduleIndex: Int
    public let moduleCount: Int

    @Binding public var module: Module

    public let onDeleteModule: () -> Void
    public let onMoveUp: () -> Void
    public let onMoveDown: () -> Void

    @State private var editTargetID: ModuleEntry.ID?

    public init(
        moduleIndex: Int,
        moduleCount: Int,
        module: Binding<Module>,
        onDeleteModule: @escaping () -> Void,
        onMoveUp: @escaping () -> Void,
        onMoveDown: @escaping () -> Void
    ) {
        self.moduleIndex = moduleIndex
        self.moduleCount = moduleCount
        self._module = module
        self.onDeleteModule = onDeleteModule
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
    }

    public var body: some View {
        let split = splitEntries(module.entries)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                TextField(
                    "Module \(moduleIndex + 1)",
                    text: Binding(
                        get: { module.title ?? "" },
                        set: { module.title = $0.isEmpty ? nil : $0 }
                    )
                )
                .textFieldStyle(.plain)
                .font(.headline)
                .frame(minWidth: 220)
                .layoutPriority(1)

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    Button { onMoveUp() } label: {
                        Image(systemName: "chevron.up")
                            .imageScale(.medium)
                    }
                    .buttonStyle(.bordered)
                    .frame(width: 36)
                    .disabled(moduleIndex == 0)
                    .help("Module omhoog")

                    Button { onMoveDown() } label: {
                        Image(systemName: "chevron.down")
                            .imageScale(.medium)
                    }
                    .buttonStyle(.bordered)
                    .frame(width: 36)
                    .disabled(moduleIndex + 1 >= moduleCount)
                    .help("Module omlaag")

                    Button { onDeleteModule() } label: {
                        Image(systemName: "trash")
                            .imageScale(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(width: 36)
                    .help("Verwijder module")

                    Button {
                        withAnimation {
                            module.entries.append(
                                ModuleEntry(
                                    component: .empty(),
                                    placement: .exchangeable,
                                    include: true
                                )
                            )
                            normalizeEntriesOrderIfNeeded(animated: false)
                        }
                    } label: {
                        Image(systemName: "plus")
                            .imageScale(.medium)
                    }
                    .buttonStyle(.bordered)
                    .frame(width: 36)
                    .help("Nieuw item")
                }
                .controlSize(.regular)
            }

            Divider()

            // List {
            //     Section("Standaard") {
            //         ForEach(split.elementaryIndices, id: \.self) { i in
            //             ModuleEntrySummaryRow(
            //                 entry: $module.entries[i],
            //                 onEdit: {
            //                     editTargetID = module.entries[i].id
            //                 },
            //                 onDelete: {
            //                     deleteEntryByIndex(i)
            //                 }
            //             )
            //             .onChange(of: module.entries[i].placement) { _, _  in
            //                 normalizeEntriesOrderIfNeeded(animated: true)
            //             }
            //         }
            //         .onMove { from, to in
            //             moveWithinElementary(from: from, to: to)
            //         }
            //         .onDelete { offsets in
            //             deleteByOffsets(offsets, in: split.elementaryIndices)
            //         }
            //     }

            //     Section("Inwisselbaar") {
            //         ForEach(split.exchangeableIndices, id: \.self) { i in
            //             ModuleEntrySummaryRow(
            //                 entry: $module.entries[i],
            //                 onEdit: {
            //                     editTargetID = module.entries[i].id
            //                 },
            //                 onDelete: {
            //                     deleteEntryByIndex(i)
            //                 }
            //             )
            //             .onChange(of: module.entries[i].placement) { _, _ in
            //                 normalizeEntriesOrderIfNeeded(animated: true)
            //             }
            //         }
            //         .onMove { from, to in
            //             moveWithinExchangeable(from: from, to: to)
            //         }
            //         .onDelete { offsets in
            //             deleteByOffsets(offsets, in: split.exchangeableIndices)
            //         }
            //     }
            // }
            // .listStyle(.plain)
            // .frame(minHeight: 120)
            // .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Standaard")

                VStack(alignment: .leading, spacing: 0) {
                    if split.elementaryIndices.isEmpty {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(split.elementaryIndices, id: \.self) { i in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                // Reorder controls (within elementary only)
                                VStack(spacing: 4) {
                                    Button { moveElementaryUp(i) } label: {
                                        Image(systemName: "chevron.up")
                                            .imageScale(.small)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!canMoveElementaryUp(i))
                                    .help("Omhoog")

                                    Button { moveElementaryDown(i) } label: {
                                        Image(systemName: "chevron.down")
                                            .imageScale(.small)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!canMoveElementaryDown(i))
                                    .help("Omlaag")
                                }
                                .frame(width: 18)

                                ModuleEntrySummaryRow(
                                    entry: $module.entries[i],
                                    onEdit: { editTargetID = module.entries[i].id },
                                    onDelete: { deleteEntryByIndex(i) }
                                )
                            }
                            .onChange(of: module.entries[i].placement) { _, _  in
                                normalizeEntriesOrderIfNeeded(animated: true)
                            }

                            Divider()
                        }
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                sectionHeader("Inwisselbaar")

                VStack(alignment: .leading, spacing: 0) {
                    if split.exchangeableIndices.isEmpty {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(split.exchangeableIndices, id: \.self) { i in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                // Reorder controls (within exchangeable only)
                                VStack(spacing: 4) {
                                    Button { moveExchangeableUp(i) } label: {
                                        Image(systemName: "chevron.up")
                                            .imageScale(.small)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!canMoveExchangeableUp(i))
                                    .help("Omhoog")

                                    Button { moveExchangeableDown(i) } label: {
                                        Image(systemName: "chevron.down")
                                            .imageScale(.small)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!canMoveExchangeableDown(i))
                                    .help("Omlaag")
                                }
                                .frame(width: 18)

                                ModuleEntrySummaryRow(
                                    entry: $module.entries[i],
                                    onEdit: { editTargetID = module.entries[i].id },
                                    onDelete: { deleteEntryByIndex(i) }
                                )
                            }
                            .onChange(of: module.entries[i].placement) { _, _ in
                                normalizeEntriesOrderIfNeeded(animated: true)
                            }

                            Divider()
                        }
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: Binding(
            get: { editTargetID != nil },
            set: { if !$0 { editTargetID = nil } }
        )) {
            if let id = editTargetID,
               let index = module.entries.firstIndex(where: { $0.id == id }) {
                ModuleEntryEditSheet(entry: $module.entries[index])
            } else {
                Text("Geen item geselecteerd")
                    .padding(20)
            }
        }
        .onAppear {
            normalizeEntriesOrderIfNeeded(animated: false)
        }
    }

    // MARK: - Split + normalize

    private struct Split {
        let elementaryIndices: [Int]
        let exchangeableIndices: [Int]
    }

    private func splitEntries(_ entries: [ModuleEntry]) -> Split {
        var elementary: [Int] = []
        var exchangeable: [Int] = []
        elementary.reserveCapacity(entries.count)
        exchangeable.reserveCapacity(entries.count)

        for i in entries.indices {
            switch entries[i].placement {
            case .elementary:
                elementary.append(i)
            case .exchangeable:
                exchangeable.append(i)
            }
        }

        return .init(elementaryIndices: elementary, exchangeableIndices: exchangeable)
    }

    private func normalizeEntriesOrderIfNeeded(animated: Bool) {
        let current = module.entries
        let elementary = current.filter { $0.placement == .elementary }
        let exchangeable = current.filter { $0.placement == .exchangeable }
        let normalized = elementary + exchangeable

        // Avoid infinite loops / useless updates
        guard normalized.map(\.id) != current.map(\.id) else { return }

        if animated {
            withAnimation(.snappy(duration: 0.22)) {
                module.entries = normalized
            }
        } else {
            module.entries = normalized
        }
    }

    // MARK: - Delete helpers

    private func deleteEntryByIndex(_ i: Int) {
        guard module.entries.indices.contains(i) else { return }
        _ = withAnimation {
            module.entries.remove(at: i)
        }
    }

    private func deleteByOffsets(_ offsets: IndexSet, in mappedIndices: [Int]) {
        let actual = offsets
            .map { mappedIndices[$0] }
            .sorted(by: >)

        withAnimation {
            for i in actual {
                if module.entries.indices.contains(i) {
                    module.entries.remove(at: i)
                }
            }
        }
    }

    // MARK: - Move helpers (within each placement band)

    private func moveWithinElementary(from: IndexSet, to: Int) {
        normalizeEntriesOrderIfNeeded(animated: false)

        let elementaryCount = module.entries.filter { $0.placement == .elementary }.count
        guard elementaryCount > 0 else { return }

        let base = 0
        let actualFrom = IndexSet(from.map { base + $0 })
        let actualTo = base + to

        withAnimation {
            module.entries.move(fromOffsets: actualFrom, toOffset: actualTo)
        }
    }

    private func moveWithinExchangeable(from: IndexSet, to: Int) {
        normalizeEntriesOrderIfNeeded(animated: false)

        let elementaryCount = module.entries.filter { $0.placement == .elementary }.count
        let exchangeableCount = module.entries.count - elementaryCount
        guard exchangeableCount > 0 else { return }

        let base = elementaryCount
        let actualFrom = IndexSet(from.map { base + $0 })
        let actualTo = base + to

        withAnimation {
            module.entries.move(fromOffsets: actualFrom, toOffset: actualTo)
        }
    }

    // MOD: helpers for the non-List view:
    private func canMoveElementaryUp(_ i: Int) -> Bool {
        let indices = splitEntries(module.entries).elementaryIndices
        guard let pos = indices.firstIndex(of: i) else { return false }
        return pos > 0
    }

    private func canMoveElementaryDown(_ i: Int) -> Bool {
        let indices = splitEntries(module.entries).elementaryIndices
        guard let pos = indices.firstIndex(of: i) else { return false }
        return pos + 1 < indices.count
    }

    private func canMoveExchangeableUp(_ i: Int) -> Bool {
        let indices = splitEntries(module.entries).exchangeableIndices
        guard let pos = indices.firstIndex(of: i) else { return false }
        return pos > 0
    }

    private func canMoveExchangeableDown(_ i: Int) -> Bool {
        let indices = splitEntries(module.entries).exchangeableIndices
        guard let pos = indices.firstIndex(of: i) else { return false }
        return pos + 1 < indices.count
    }

    private func moveElementaryUp(_ i: Int) {
        normalizeEntriesOrderIfNeeded(animated: false)

        let indices = splitEntries(module.entries).elementaryIndices
        guard let pos = indices.firstIndex(of: i), pos > 0 else { return }

        let a = indices[pos]
        let b = indices[pos - 1]

        withAnimation {
            module.entries.swapAt(a, b)
        }
    }

    private func moveElementaryDown(_ i: Int) {
        normalizeEntriesOrderIfNeeded(animated: false)

        let indices = splitEntries(module.entries).elementaryIndices
        guard let pos = indices.firstIndex(of: i), pos + 1 < indices.count else { return }

        let a = indices[pos]
        let b = indices[pos + 1]

        withAnimation {
            module.entries.swapAt(a, b)
        }
    }

    private func moveExchangeableUp(_ i: Int) {
        normalizeEntriesOrderIfNeeded(animated: false)

        let indices = splitEntries(module.entries).exchangeableIndices
        guard let pos = indices.firstIndex(of: i), pos > 0 else { return }

        let a = indices[pos]
        let b = indices[pos - 1]

        withAnimation {
            module.entries.swapAt(a, b)
        }
    }

    private func moveExchangeableDown(_ i: Int) {
        normalizeEntriesOrderIfNeeded(animated: false)

        let indices = splitEntries(module.entries).exchangeableIndices
        guard let pos = indices.firstIndex(of: i), pos + 1 < indices.count else { return }

        let a = indices[pos]
        let b = indices[pos + 1]

        withAnimation {
            module.entries.swapAt(a, b)
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

public struct ModuleEntrySummaryRow: View {
    @Binding public var entry: ModuleEntry
    public var onEdit: () -> Void
    public var onDelete: () -> Void

    public init(
        entry: Binding<ModuleEntry>,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self._entry = entry
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            includeCheckbox()

            placementPicker()

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    FormatChips(formats: entry.component.format)

                    Text(entry.component.displayTagline)
                        .font(.body)
                        .lineLimit(2)
                }

                if let caption = entry.component.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.system(size: ViewVariables.program_caption_size))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let allocation = allocationLine() {
                    Text(allocation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit()
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .imageScale(.medium)
                }
                .buttonStyle(.bordered)
                .help("Verwijder")

                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .imageScale(.medium)
                }
                .buttonStyle(.bordered)
                .help("Bewerk")
            }
        }
        .padding(.vertical, 2)
    }

    private func allocationLine(sessionDuration: Int = 60) -> String? {
        guard let alloc = entry.component.allocation else { return nil }
        let s = alloc.summary(sessionDuration: sessionDuration)
        if let sess = s.sessionsText {
            return "Tijd: \(s.minutesText) (\(sess))"
        }
        return "Tijd: \(s.minutesText)"
    }

    private func includeCheckbox() -> some View {
        Button {
            entry.include.toggle()
        } label: {
            Image(systemName: entry.include ? "checkmark.square.fill" : "square")
                .imageScale(.medium)
        }
        .buttonStyle(.plain)
        .frame(width: 22, alignment: .leading)
        .accessibilityLabel(entry.include ? "Inbegrepen" : "Niet inbegrepen")
    }

    private func placementPicker() -> some View {
        Picker("", selection: $entry.placement) {
            Text("Standaard").tag(ModuleComponentPlacement.elementary)
            Text("Inwisselbaar").tag(ModuleComponentPlacement.exchangeable)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Format chips

private struct FormatChips: View {
    public let formats: Set<LessonFormat>

    public var body: some View {
        let ordered = formats
            .map { $0.data.title }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        if ordered.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 6) {
                ForEach(ordered, id: \.self) { t in
                    Text(t)
                        .font(.caption2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

public struct ModuleEntryPreviewCard: View {
    @Binding public var entry: ModuleEntry

    public init(entry: Binding<ModuleEntry>) {
        self._entry = entry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                includeIndicator()

                placementIndicator()

                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 8) {
                        FormatChips(formats: entry.component.format)

                        Text(entry.component.displayTagline)
                            .font(.body)
                            .lineLimit(2)
                    }

                    if let caption = entry.component.caption, !caption.isEmpty {
                        Text(caption)
                            .font(.system(size: ViewVariables.program_caption_size))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }

                    if let details = entry.component.details, !details.isEmpty {
                        Text(details)
                            .font(.system(size: ViewVariables.program_caption_size))
                            .foregroundStyle(.secondary)
                            .lineLimit(4)
                    }

                    let meta = metaLine()
                    if !meta.isEmpty {
                        Text(meta)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func includeIndicator() -> some View {
        Image(systemName: entry.include ? "checkmark.square.fill" : "square")
            .imageScale(.medium)
            .frame(width: 22, alignment: .leading)
            .accessibilityLabel(entry.include ? "Inbegrepen" : "Niet inbegrepen")
    }

    private func placementIndicator() -> some View {
        Text(entry.placement == .elementary ? "Standaard" : "Inwisselbaar")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .fixedSize()
    }

    private func metaLine() -> String {
        let concepts = entry.component.concepts
            .map { $0.title_nl }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        let conceptsText: String? = concepts.isEmpty ? nil : "Concepten: " + concepts.joined(separator: ", ")

        let allocationText: String? = {
            guard let alloc = entry.component.allocation else { return nil }
            let s = alloc.summary(sessionDuration: 60)
            if let sess = s.sessionsText { return "Tijd: \(s.minutesText) (\(sess))" }
            return "Tijd: \(s.minutesText)"
        }()

        return [
            allocationText,
            conceptsText
        ]
        .compactMap { $0?.isEmpty == false ? $0 : nil }
        .joined(separator: " • ")
    }
}

public struct ModuleEntryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding public var entry: ModuleEntry

    public init(entry: Binding<ModuleEntry>) {
        self._entry = entry
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                ModuleEntryPreviewCard(entry: $entry)

                allocationEditor()

                // MultiSelectGrid(
                //     title: "Format",
                //     all: LessonFormat.allCases,
                //     selected: $entry.component.format,
                //     label: { $0.rawValue }
                // )

                // MultiSelectGrid(
                //     title: "Concepts",
                //     all: LessonConcept.allCases,
                //     selected: $entry.component.concepts,
                //     label: { $0.rawValue }
                // )

                MultiSelectList(
                    title: "Format",
                    all: LessonFormat.allCases,
                    selected: $entry.component.format,
                    label: { $0.data.title }
                )

                MultiSelectList(
                    title: "Concepts",
                    all: LessonConcept.allCases,
                    selected: $entry.component.concepts,
                    label: { $0.title_nl }
                )

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Tagline", text: bindingString($entry.component.tagline))

                    TextField("Caption", text: bindingString($entry.component.caption))

                    TextField("Details", text: bindingString($entry.component.details), axis: .vertical)
                        .lineLimit(3...10)
                }
                .textFieldStyle(.roundedBorder)

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(minWidth: 560, minHeight: 520)
            .navigationTitle("Lesonderdeel bewerken")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func allocationEditor() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Tijd allocatie", isOn: Binding(
                get: { entry.component.allocation != nil },
                set: { enabled in
                    if enabled {
                        if entry.component.allocation == nil {
                            entry.component.allocation = SessionAllocation(
                                minutes: MinuteRange(low: 60, medium: nil, high: 60)
                            )
                        }
                    } else {
                        entry.component.allocation = nil
                    }
                }
            ))
            .toggleStyle(.checkbox)

            if entry.component.allocation != nil {
                HStack(spacing: 12) {
                    IntField(
                        title: "Minuten (laag)",
                        value: Binding(
                            get: { entry.component.allocation?.minutes.low ?? 60 },
                            set: { newValue in
                                guard entry.component.allocation != nil else { return }
                                entry.component.allocation?.minutes.low = newValue

                                // keep medium within [low, high]
                                if let m = entry.component.allocation?.minutes.medium {
                                    let lo = entry.component.allocation?.minutes.low ?? newValue
                                    let hi = entry.component.allocation?.minutes.high ?? lo
                                    entry.component.allocation?.minutes.medium = max(lo, min(hi, m))
                                }
                            }
                        )
                    )

                    IntField(
                        title: "Minuten (medium)",
                        value: Binding(
                            get: {
                                guard let m = entry.component.allocation?.minutes.medium else {
                                    return entry.component.allocation?.minutes.effectiveMedium() ?? 60
                                }
                                return m
                            },
                            set: { newValue in
                                guard entry.component.allocation != nil else { return }
                                let lo = entry.component.allocation?.minutes.low ?? 0
                                let hi = entry.component.allocation?.minutes.high ?? lo
                                entry.component.allocation?.minutes.medium = max(lo, min(hi, newValue))
                            }
                        )
                    )

                    IntField(
                        title: "Minuten (hoog)",
                        value: Binding(
                            get: {
                                let lo = entry.component.allocation?.minutes.low ?? 60
                                return entry.component.allocation?.minutes.high ?? lo
                            },
                            set: { newValue in
                                guard entry.component.allocation != nil else { return }
                                let lo = entry.component.allocation?.minutes.low ?? 0
                                entry.component.allocation?.minutes.high = max(lo, newValue)

                                // keep medium within [low, high]
                                if let m = entry.component.allocation?.minutes.medium {
                                    let hi = entry.component.allocation?.minutes.high ?? max(lo, newValue)
                                    entry.component.allocation?.minutes.medium = max(lo, min(hi, m))
                                }
                            }
                        )
                    )

                    Button {
                        // allow clearing explicit medium; downstream uses effectiveMedium()
                        entry.component.allocation?.minutes.medium = nil
                    } label: {
                        Text("Reset medium")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Zet medium terug naar automatisch (midden van laag/hoog)")

                    Spacer()

                    if let alloc = entry.component.allocation {
                        let r = alloc.minutes
                        Text(sessionsPreview(minutes: r, sessionDuration: 60))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func sessionsPreview(minutes: MinuteRange, sessionDuration: Int = 60) -> String {
        let s = minutes.session_range(session_duration: sessionDuration)

        let lo = formatSessions(s.low)
        let mid = formatSessions(s.effectiveMedium())
        let hi = formatSessions(s.high)

        if nearlyEqual(s.low, s.high) {
            return "\(lo) sess @ \(sessionDuration) min"
        }

        // show tri when it actually differs
        if nearlyEqual(s.low, s.effectiveMedium()) || nearlyEqual(s.effectiveMedium(), s.high) {
            return "\(lo)–\(hi) sess @ \(sessionDuration) min"
        }

        return "\(lo) / \(mid) / \(hi) sess @ \(sessionDuration) min"
    }

    private func bindingString(_ v: Binding<String?>) -> Binding<String> {
        Binding<String>(
            get: { v.wrappedValue ?? "" },
            set: { v.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

public struct IntField: View {
    public let title: String
    @Binding public var value: Int

    private let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.allowsFloats = false
        f.minimum = 0
        return f
    }()

    public init(title: String, value: Binding<Int>) {
        self.title = title
        self._value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("", value: $value, formatter: formatter)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
        }
    }
}

// MARK: - Multi select
public struct MultiSelectGrid<Item: Hashable>: View {
    public let title: String
    public let all: [Item]
    @Binding public var selected: Set<Item>
    public let spacing: CGFloat
    public let label: (Item) -> String

    public init(
        title: String,
        all: [Item],
        selected: Binding<Set<Item>>,
        spacing: CGFloat = 6,
        label: @escaping (Item) -> String
    ) {
        self.title = title
        self.all = all
        self._selected = selected
        self.spacing = spacing
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let columns: [GridItem] = [
                GridItem(.adaptive(minimum: 90), spacing: spacing, alignment: .leading)
            ]

            LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
                ForEach(all, id: \.self) { item in
                    let isOn = selected.contains(item)

                    Text(label(item))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isOn ? AnyShapeStyle(.primary.opacity(0.15)) : AnyShapeStyle(.ultraThinMaterial))
                        .clipShape(Capsule())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Capsule())
                        .onTapGesture {
                            toggle(item)
                        }
                }
            }
        }
    }

    private func toggle(_ item: Item) {
        if selected.contains(item) {
            selected.remove(item)
        } else {
            selected.insert(item)
        }
    }
}

public struct MultiSelectList<Item: Hashable>: View {
    public let title: String
    public let all: [Item]
    @Binding public var selected: Set<Item>
    public let label: (Item) -> String

    public init(
        title: String,
        all: [Item],
        selected: Binding<Set<Item>>,
        label: @escaping (Item) -> String
    ) {
        self.title = title
        self.all = all
        self._selected = selected
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(all, id: \.self) { item in
                        let isOn = selected.contains(item)

                        Button {
                            toggle(item)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                    .imageScale(.medium)

                                Text(label(item))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider()
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .frame(maxHeight: 180)
        }
    }

    private func toggle(_ item: Item) {
        if selected.contains(item) {
            selected.remove(item)
        } else {
            selected.insert(item)
        }
    }
}

// MARK: - Component library (kept for later)

public struct ComponentLibraryView: View {
    public let title: String
    public let current: ModuleComponent
    public let onPick: (ModuleComponent) -> Void
    public let onCancel: () -> Void

    public init(
        title: String,
        current: ModuleComponent,
        onPick: @escaping (ModuleComponent) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.current = current
        self.onPick = onPick
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            List {
                Section("Huidig") {
                    Text(current.tagline ?? "—")
                }

                Section("Opties") {
                    ForEach(allComponents(), id: \.self) { component in
                        Button {
                            onPick(component)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(component.tagline ?? "—")
                                Text(summary(component))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") { onCancel() }
                }
            }
        }
    }

    private func summary(_ c: ModuleComponent) -> String {
        let concepts = c.concepts.map(\.rawValue).sorted().joined(separator: ", ")
        let formats = c.format.map(\.rawValue).sorted().joined(separator: ", ")
        if concepts.isEmpty && formats.isEmpty { return "" }
        if formats.isEmpty { return concepts }
        if concepts.isEmpty { return formats }
        return "\(concepts) • \(formats)"
    }

    private func allComponents() -> [ModuleComponent] {
        return [
            PrebuiltModuleComponents.Communication.markers_and_overshadowing,
            PrebuiltModuleComponents.Communication.thresholds_drive_priority,
            PrebuiltModuleComponents.Communication.classical_conditioning,
            PrebuiltModuleComponents.Communication.overshadowing,
            PrebuiltModuleComponents.Equipment.equipment_toys,
            PrebuiltModuleComponents.BehaviorModification.premack_discharge_energy,
            PrebuiltModuleComponents.BehaviorModification.capping_dynamic_to_static
        ]
    }
}
