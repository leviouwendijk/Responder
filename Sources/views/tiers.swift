import SwiftUI
import plate
import Economics
import ViewComponents

struct QuotaTierListView: View {
    let quota: CustomQuota

    @State private var tiers: [QuotaTierContent]? = nil
    @State private var message: String = ""

    var body: some View {
        Group {
            if let t = tiers {
                QuotaTierListSubView(tiers: t)
                    .padding(.top, 16)
            } else {
                VStack {
                    // NotificationBanner(type: .info,
                    //         message: "Loading tiers…")
                    NotificationBanner(type: .warning,
                            message: message)
                }
                .onAppear {
                    do {
                        self.tiers = try quota.tiers()
                    } catch {
                        self.message = error.localizedDescription
                    }
                }
            }
        }
    }
}

struct QuotaTierListSubView: View {
    let tiers: [QuotaTierContent]

    init(
        tiers: [QuotaTierContent]
    ) {
        self.tiers = tiers
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ─── HEADER ROW ──────────────────────────────────────────────────
                HStack(spacing: 0) {
                    // 1st cell is empty, to align with row labels below
                    Text("")
                        .frame(width: 80, alignment: .leading)

                    ForEach(tiers, id: \.tier) { content in
                        Text(content.tier.rawValue.capitalized)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                // ─── PRICE BLOCK ────────────────────────────────────────────────
                VStack(spacing: 4) {
                    // “Price” as a spanning header
                    HStack {
                        Text("Price")
                            .font(.subheadline)
                            .bold()
                        Spacer()
                    }
                    .padding(.vertical, 4)

                    Divider()
                    .padding(.vertical, 4)

                    TableBlock(
                        rowLabelWidth: 80,
                        tiers: tiers,
                        valuesFor: { content in
                            content.levels.viewableTuples(of: .price)
                        },
                        textColor: .primary
                    )
                }

                // ─── COST BLOCK ─────────────────────────────────────────────────
                VStack(spacing: 4) {
                    HStack {
                        Text("Cost")
                            .font(.subheadline)
                            .bold()
                        Spacer()
                    }
                    .padding(.vertical, 4)

                    Divider()
                    .padding(.vertical, 4)

                    TableBlock(
                        rowLabelWidth: 80,
                        tiers: tiers,
                        valuesFor: { content in
                            content.levels.viewableTuples(of: .cost)
                        },
                        textColor: .secondary
                    )
                }

                // ─── BASE BLOCK ─────────────────────────────────────────────────
                VStack(spacing: 4) {
                    HStack {
                        Text("Base")
                            .font(.subheadline)
                            .bold()
                        Spacer()
                    }
                    .padding(.vertical, 4)

                    Divider()
                    .padding(.vertical, 4)

                    TableBlock(
                        rowLabelWidth: 80,
                        tiers: tiers,
                        valuesFor: { content in
                            content.levels.viewableTuples(of: .base)
                        },
                        textColor: .secondary
                    )
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
    }
}

private struct TableBlock: View {
    let rowLabelWidth: CGFloat
    let tiers: [QuotaTierContent]
    let valuesFor: (QuotaTierContent) -> [(String, Double)]
    let textColor: Color

    private var allRows: [String]            // row names, e.g. ["prognosis", "suggestion", …]
    private var tierValueMatrix: [[Double]]  // tierValueMatrix[rowIndex][tierIndex]
    private var isPrognosisRow: [Bool]       // true if the “String” is “prognosis”

    init(
        rowLabelWidth: CGFloat,
        tiers: [QuotaTierContent],
        valuesFor: @escaping (QuotaTierContent) -> [(String, Double)],
        textColor: Color
    ) {
        self.rowLabelWidth = rowLabelWidth
        self.tiers = tiers
        self.valuesFor = valuesFor
        self.textColor = textColor

        let firstTuples = valuesFor(tiers.first!)
        self.allRows = firstTuples.map { $0.0 }
        self.isPrognosisRow = firstTuples.map { $0.0 == "prognosis" }

        var matrix: [[Double]] = Array(
            repeating: [Double](),
            count: firstTuples.count
        )
        for (tierIndex, tierContent) in tiers.enumerated() {
            let tuples = valuesFor(tierContent) // e.g. [("prognosis", 12.34), ("suggestion", 8.90), …]
            for rowIndex in 0 ..< tuples.count {
                let value = tuples[rowIndex].1
                if tierIndex == 0 {
                    matrix[rowIndex].append(value)
                } else {
                    matrix[rowIndex].append(value)
                }
            }
        }
        self.tierValueMatrix = matrix
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(allRows.indices, id: \.self) { rowIndex in
                HStack(spacing: 4) {
                let label = allRows[rowIndex]
                Text(label)
                .font(.subheadline)
                .frame(width: rowLabelWidth,
                        alignment: .leading)
                .foregroundStyle(textColor)

                    ForEach(Array(tiers.indices), id: \.self) { tierIndex in
                        let rawValue = tierValueMatrix[rowIndex][tierIndex]
                        let str      = String(format: "%.2f", rawValue)
                        let displayed = isPrognosisRow[rowIndex]
                        ? "(\(str))"
                        : str

                        Text(displayed)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(textColor)
                    }
                }
            }
        }
    }
}

private struct StatView: View {
    let label: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.2f", value))
                .font(.body)
                .bold()
        }
    }
}
