import SwiftUI
import plate
import Economics

struct QuotaTierListView: View {
    let quota: CustomQuota

    private var tiers: [QuotaTierContent] {
        quota.tiers()
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
                            [
                                ("prognosis", content.price.prognosis),
                                ("suggestion", content.price.suggestion),
                                ("base", content.price.base)
                            ]
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
                            [
                                ("prognosis", content.cost.prognosis),
                                ("suggestion", content.cost.suggestion),
                                ("base", content.cost.base)
                            ]
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
                            [
                                ("prognosis", content.base.prognosis),
                                ("suggestion", content.base.suggestion),
                                ("base", content.base.base)
                            ]
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

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(valuesFor(tiers.first!).map { $0.0 }.indices), id: \.self) { rowIndex in
                HStack(spacing: 4) {
                    // 1) Row label (“prognosis”, “suggestion”, “base”)
                    Text(valuesFor(tiers.first!)[rowIndex].0)
                        .font(.subheadline)
                        .frame(width: rowLabelWidth, alignment: .leading)
                        .foregroundStyle(textColor)

                    // 2) For each tier, show that tier’s matching value
                    ForEach(tiers, id: \.tier) { content in
                        let entry = valuesFor(content)[rowIndex]
                        let str = String(format: "%.2f", entry.1)
                        let displayed = (entry.0 == "prognosis") ? "(\(str))" : str
                        Text(displayed)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(textColor)
                    }
                }
            }
        }
    }
}

/// A small helper to render a label + numeric value side by side.
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
