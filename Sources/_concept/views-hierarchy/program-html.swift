import Foundation
import HTML
import CSS
import Constructors

public struct DocDataBox: Sendable {
    public var dateLabel: String
    public var clientName: String
    public var dogName: String
    public var estimatedSessions: (low: Int, high: Int)?
    public var includedPackages: [String]?

    public init(
        dateLabel: String,
        clientName: String,
        dogName: String,
        estimatedSessions: (low: Int, high: Int)? = nil,
        includedPackages: [String]? = nil
    ) {
        self.dateLabel = dateLabel
        self.clientName = clientName
        self.dogName = dogName
        self.estimatedSessions = estimatedSessions
        self.includedPackages = includedPackages
    }

    public func html() -> HTMLFragment {
        var contentNodes: [any HTMLNode] = [
            docDataLine(label: "Datum:", value: dateLabel),
            docDataLine(label: "Client:", value: clientName),
            docDataLine(label: "Hond:", value: dogName),
        ]

        if let sessions = estimatedSessions {
            contentNodes.append(
                docDataLine(
                    label: "Sessies:",
                    value: "\(sessions.low)–\(sessions.high)"
                )
            )
        }

        if let packages = includedPackages, !packages.isEmpty {
            let titleLabel = "Pakketsamenstelling:"

            contentNodes.append(
                docDataPackageLine(label: titleLabel, value: packages.first!)
            )

            for pkg in packages.dropFirst() {
                contentNodes.append(
                    docDataPackageLine(label: "", value: pkg)
                )
            }
        }

        return [
            HTML.div(["class": "ph-docdata-box"]) {
                contentNodes
            }
        ]
    }

    private func docDataLine(label: String, value: String) -> any HTMLNode {
        HTML.div(["class": "ph-docdata-line"]) {
            HTML.span(["class": "ph-docdata-label"]) { HTML.text(label) }
            HTML.span(["class": "ph-docdata-value"]) { HTML.text(value) }
        }
    }

    private func docDataPackageLine(label: String, value: String) -> any HTMLNode {
        HTML.div(["class": "ph-docdata-line ph-docdata-package-line"]) {
            HTML.span(["class": "ph-docdata-label"]) { HTML.text(label) }
            HTML.span(["class": "ph-docdata-value"]) { HTML.text(value) }
        }
    }
}

public enum ProgramHTML {
    public static func build(
        program: [Package],
        title: String = "Programma",
        overview: DocDataBox? = nil
    ) -> HTMLDocument {
        HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(title)

                    HTML.style {
                        ProgramHTMLStyles.blocks()
                    }
                }

                HTML.body {
                    HTML.div(["class": "ph-sheet"]) {
                        renderHeader(title: title)

                        if let overview {
                            HTML.section(["class": "ph-overview"]) {
                                overview.html()
                            }
                        }

                        for pkg in program {
                            renderPackage(pkg)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Header

    private static func renderHeader(title: String) -> any HTMLNode {
        HTML.div(["class": "ph-doc-header"]) {
            HTML.div(["class": "ph-header-top"]) {
                HTML.div(["class": "ph-brand"]) {
                    HTML.div(["class": "ph-brand-name"]) { HTML.text("HONDENMEESTERS") }
                }

                HTML.div(["class": "ph-company-info"]) {
                    HTML.p {
                        HTML.text("Hondenmeesters V.O.F.")
                    }
                }
            }

            HTML.hr(["class": "ph-header-divider"])

            HTML.div(["class": "ph-header-bottom"]) {
                HTML.div(["class": "ph-header-left"]) {
                    HTML.div(["class": "ph-subtitle-main"]) {
                        HTML.text("Programma-overzicht")
                    }
                }

                HTML.div(["class": "ph-header-right"]) {
                    HTML.div(["class": "ph-doc-title-inline"]) {
                        HTML.text(title)
                    }
                }
            }
        }
    }

    private static func renderPackage(_ pkg: Package) -> HTMLFragment {
        return [
            HTML.section(["class": "ph-package"]) {
                HTML.div(["class": "ph-package-title"]) {
                    HTML.text(pkg.title)
                }

                HTML.div(["class": "ph-package-body"]) {
                    for m in pkg.modules {
                        renderModule(m)
                    }
                }
            }
        ]
    }

    // private static func renderPackage(_ pkg: Package) -> HTMLFragment {
    //     var nodes: HTMLFragment = []

    //     nodes.append(
    //         HTML.div(["class": "ph-package-title"]) {
    //             HTML.text(pkg.title)
    //         }
    //     )

    //     for m in pkg.modules {
    //         nodes.append(contentsOf: renderModule(m))
    //     }

    //     return nodes
    // }

    private static func renderModule(_ module: Module) -> HTMLFragment {
        let header: String = module.title ?? "Module"

        return [
            HTML.div(["class": "ph-box ph-box--module"]) {
                HTML.div(["class": "ph-box__head"]) {
                    HTML.div(["class": "ph-box__head-text"]) {
                        HTML.div(["class": "ph-box__title"]) { HTML.text(header) }
                    }
                }

                HTML.div(["class": "ph-box__body"]) {
                    renderEntries(module.entries)
                }
            }
        ]
    }

    private static func renderEntries(_ entries: [ModuleEntry]) -> HTMLFragment {
        let visible = entries.filter { $0.include }

        let elementary = visible.filter { $0.placement == .elementary }
        let exchangeable = visible.filter { $0.placement == .exchangeable }

        var nodes: HTMLFragment = []

        nodes.append(
            HTML.div(["class": "ph-component-list"]) {
                for e in elementary {
                    renderEntry(e, kind: .included)
                }
            }
        )

        if !exchangeable.isEmpty {
            nodes.append(
                HTML.div(["class": "ph-exchangeable-box"]) {
                    HTML.div(["class": "ph-exchangeable-title"]) {
                        HTML.text("Mogelijke aanvullingen of inwisselingen")
                    }

                    HTML.div(["class": "ph-component-list ph-component-list--exchangeable"]) {
                        for e in exchangeable {
                            renderEntry(e, kind: .exchangeable)
                        }
                    }
                }
            )
        }

        return nodes
    }

    private enum EntryKind {
        case included
        case exchangeable
    }

    private static func renderEntry(
        _ entry: ModuleEntry,
        kind: EntryKind
    ) -> any HTMLNode {
        let c = entry.component

        // var chips: [String] = c.format
        //     .map { $0.data.title }
        //     .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        // let (maybeLabel, titleText): (String?, String) =
        //     splitTaglineIfCustom(tagline: c.tagline, fallback: c.displayTagline)

        // if let label = maybeLabel, !label.isEmpty {
        //     chips.insert(label, at: 0)
        // }

        let titleText: String = {
            if let t = c.tagline, !t.isEmpty {
                return t
            }
            return c.displayTagline
        }()

        let chips: [String] = c.format
            .map { $0.data.title }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }


        let rowClass = (kind == .exchangeable)
            ? "ph-component-row ph-component-row--exchangeable"
            : "ph-component-row"

        return HTML.div(["class": rowClass]) {
            HTML.div(["class": "ph-component-main"]) {
                if !chips.isEmpty {
                    HTML.div(["class": "ph-component-chips"]) {
                        for t in chips {
                            HTML.span(["class": "ph-chip"]) { HTML.text(t) }
                        }
                    }
                }

                HTML.div(["class": "ph-component-title"]) {
                    HTML.text(titleText)
                }
            }

            if let caption = c.caption, !caption.isEmpty {
                HTML.div(["class": "ph-component-subtitle"]) {
                    HTML.text(caption)
                }
            }
        }
    }

    // MARK: - Tagline splitting rule

    private static func splitTaglineIfCustom(tagline: String?, fallback: String) -> (label: String?, title: String) {
        guard let tagline, !tagline.isEmpty else {
            return (nil, fallback)
        }

        guard let i = tagline.firstIndex(of: ":") else {
            return (nil, tagline)
        }

        let left = tagline[..<i].trimmingCharacters(in: .whitespacesAndNewlines)
        let right = tagline[tagline.index(after: i)...].trimmingCharacters(in: .whitespacesAndNewlines)

        if left.isEmpty {
            return (nil, right.isEmpty ? fallback : right)
        }

        if right.isEmpty {
            return (String(left), String(left))
        }

        return (String(left), String(right))
    }
}

public enum ProgramHTMLStyles {
    @CSSBuilder
    public static func blocks() -> [CSSBlock] {
        CSS.rule("*", CSS.decl("box-sizing", "border-box"))

        CSS.rule(
            "body",
            CSS.decl("margin", "0"),
            CSS.decl("color", "#16181d"),
            CSS.decl("font-family", "-apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif"),
            CSS.decl("font-size", "13px"),
            CSS.decl("line-height", "1.35")
        )

        CSS.rule(
            ".ph-sheet",
            CSS.decl("max-width", "900px"),
            CSS.decl("margin", "24px auto"),
            CSS.decl("padding", "22px")
        )

        // Header
        CSS.rule(".ph-doc-header", CSS.decl("margin-bottom", "16px"))

        CSS.rule(
            ".ph-header-top",
            CSS.decl("display", "flex"),
            CSS.decl("justify-content", "space-between"),
            CSS.decl("align-items", "flex-start")
        )

        CSS.rule(
            ".ph-brand-name",
            CSS.decl("font-size", "14px"),
            CSS.decl("font-weight", "700"),
            CSS.decl("letter-spacing", "1.2px")
        )

        CSS.rule(
            ".ph-company-info",
            CSS.decl("font-size", "12px"),
            CSS.decl("font-weight", "200"),
            CSS.decl("color", "gray"),
            CSS.decl("text-align", "right"),
            CSS.decl("line-height", "1.5"),
            CSS.decl("margin", "0")
        )

        CSS.rule(".ph-company-info p", CSS.decl("margin", "0"))

        CSS.rule(
            ".ph-header-divider",
            CSS.decl("border", "0"),
            CSS.decl("border-top", "0.5px solid black"),
            CSS.decl("margin", "10px 0 12px")
        )

        CSS.rule(
            ".ph-header-bottom",
            CSS.decl("display", "flex"),
            CSS.decl("justify-content", "space-between"),
            CSS.decl("align-items", "flex-start"),
            CSS.decl("gap", "24px")
        )

        CSS.rule(
            ".ph-subtitle-main",
            CSS.decl("letter-spacing", "1.0px"),
            CSS.decl("font-size", "13px"),
            CSS.decl("font-weight", "300"),
            CSS.decl("white-space", "nowrap")
        )

        CSS.rule(
            ".ph-doc-title-inline",
            CSS.decl("font-size", "13px"),
            CSS.decl("font-weight", "400"),
            CSS.decl("opacity", "0.9"),
            CSS.decl("text-align", "right")
        )

        // Overview doc data (restored)
        CSS.rule(
            ".ph-overview",
            CSS.decl("padding", "12px 14px"),
            CSS.decl("background", "#ffffff"),
            CSS.decl("border", "1px solid #ececf2"),
            CSS.decl("border-radius", "12px"),
            CSS.decl("margin", "0 0 14px")
        )

        CSS.rule(
            ".ph-docdata-box",
            CSS.decl("border", "1px solid #ececf2"),
            CSS.decl("border-radius", "10px"),
            CSS.decl("background", "#fbfbfd"),
            CSS.decl("padding", "10px 12px"),
            CSS.decl("font-size", "12px"),
            CSS.decl("width", "100%"),
            CSS.decl("margin", "0"),
            CSS.decl("white-space", "normal")
        )

        CSS.rule(
            ".ph-docdata-line",
            CSS.decl("display", "flex"),
            CSS.decl("justify-content", "space-between"),
            CSS.decl("align-items", "center"),
            CSS.decl("margin", "4px 0")
        )

        CSS.rule(
            ".ph-docdata-package-line .ph-docdata-label",
            CSS.decl("min-width", "140px"),
            CSS.decl("flex-shrink", "0"),
            CSS.decl("white-space", "nowrap")
        )

        CSS.rule(
            ".ph-docdata-package-line .ph-docdata-value",
            CSS.decl("white-space", "nowrap"),
            CSS.decl("overflow", "hidden"),
            CSS.decl("text-overflow", "ellipsis")
        )

        CSS.rule(
            ".ph-docdata-label",
            CSS.decl("font-weight", "500"),
            CSS.decl("flex-shrink", "0")
        )

        CSS.rule(
            ".ph-docdata-value",
            CSS.decl("font-weight", "300"),
            CSS.decl("word-break", "break-word")
        )

        // Package title
        CSS.rule(
            ".ph-package-title",
            CSS.decl("margin", "14px 0 8px"),
            CSS.decl("font-size", "12px"),
            CSS.decl("font-weight", "600"),
            CSS.decl("color", "#374151"),
            CSS.decl("letter-spacing", "0.2px")
        )

        // Box
        CSS.rule(
            ".ph-box",
            CSS.decl("border", "1px solid #ececf2"),
            CSS.decl("border-radius", "12px"),
            CSS.decl("background", "#ffffff"),
            CSS.decl("overflow", "hidden"),
            CSS.decl("margin", "0 0 14px")
        )

        CSS.rule(
            ".ph-box__head",
            CSS.decl("padding", "12px 14px"),
            CSS.decl("border-bottom", "1px solid #ececf2")
        )

        CSS.rule(
            ".ph-box__title",
            CSS.decl("font-weight", "700"),
            CSS.decl("font-size", "14px"),
            CSS.decl("margin", "0")
        )

        CSS.rule(".ph-box__body", CSS.decl("padding", "12px 14px"))

        // Component list
        CSS.rule(
            ".ph-component-list",
            CSS.decl("display", "flex"),
            CSS.decl("flex-direction", "column")
        )

        CSS.rule(
            ".ph-component-row",
            CSS.decl("padding", "8px 0"),
            CSS.decl("border-top", "1px solid #ececf2")
        )

        CSS.rule(
            ".ph-component-row:first-child",
            CSS.decl("border-top", "0"),
            CSS.decl("padding-top", "0")
        )

        // -----------------------------
        // FIX 1: chips/title “gap” due to variable-length chip group
        // - Make main line wrap
        // - Make chips wrapper layout-neutral so chips + title share same flex line flow
        // -----------------------------
        // CSS.rule(
        //     ".ph-component-main",
        //     CSS.decl("display", "flex"),
        //     CSS.decl("flex-wrap", "wrap"),
        //     CSS.decl("align-items", "baseline"),
        //     CSS.decl("column-gap", "8px"),
        //     CSS.decl("row-gap", "6px"),
        //     CSS.decl("min-width", "0")
        // )

        CSS.rule(
            ".ph-component-main",
            CSS.decl("display", "flex"),
            CSS.decl("flex-direction", "column"),
            CSS.decl("gap", "6px")
        )

        // CSS.rule(
        //     ".ph-component-chips",
        //     CSS.decl("display", "contents")
        // )

        // CSS.rule(
        //     ".ph-component-chips",
        //     CSS.decl("display", "flex"),
        //     CSS.decl("flex-wrap", "wrap"),
        //     CSS.decl("gap", "6px")
        // )

        // CSS.rule(
        //     ".ph-chip",
        //     CSS.decl("display", "inline-block"),
        //     CSS.decl("padding", "2px 7px"),
        //     CSS.decl("border", "1px solid #ececf2"),
        //     CSS.decl("border-radius", "999px"),
        //     CSS.decl("background", "#fbfbfd"),
        //     CSS.decl("font-size", "11px"),
        //     CSS.decl("line-height", "1.2"),
        //     CSS.decl("color", "#374151"),
        //     CSS.decl("white-space", "nowrap")
        // )

        CSS.rule(
            ".ph-component-chips",
            CSS.decl("display", "flex"),
            CSS.decl("flex-wrap", "wrap"),
            CSS.decl("gap", "6px"),
            CSS.decl("align-items", "center")
        )

        CSS.rule(
            ".ph-chip",
            CSS.decl("display", "inline-flex"),
            CSS.decl("align-items", "center"),
            CSS.decl("justify-content", "center"),
            CSS.decl("flex", "0 0 auto"),

            CSS.decl("padding", "2px 7px"),
            CSS.decl("border-radius", "999px"),

            // ONE stroke, no double-render seams
            CSS.decl("border", "0"),
            CSS.decl("background", "#fbfbfd"),
            CSS.decl("box-shadow", "inset 0 0 0 1px #ececf2"),

            CSS.decl("outline", "0"),
            CSS.decl("filter", "none"),

            CSS.decl("font-size", "11px"),
            CSS.decl("line-height", "1.1"),
            CSS.decl("color", "#374151"),
            CSS.decl("white-space", "nowrap")
        )

        // CSS.rule(
        //     ".ph-component-title",
        //     CSS.decl("font-size", "13px"),
        //     CSS.decl("font-weight", "400"),
        //     CSS.decl("color", "#16181d"),
        //     CSS.decl("min-width", "0"),
        //     CSS.decl("flex", "1 1 260px")
        // )

        CSS.rule(
            ".ph-component-title",
            CSS.decl("font-size", "13px"),
            CSS.decl("font-weight", "400"),
            CSS.decl("color", "#16181d")
        )

        // Caption: more prominent
        CSS.rule(
            ".ph-component-subtitle",
            CSS.decl("margin-top", "4px"),
            CSS.decl("font-size", "12.5px"),
            CSS.decl("font-weight", "400"),
            CSS.decl("color", "#374151")
        )

        // -----------------------------
        // FIX 2: exchangeable area should read like original “inner callout box”
        // -----------------------------
        CSS.rule(
            ".ph-exchangeable-box",
            CSS.decl("margin-top", "12px"),
            CSS.decl("padding", "10px 12px"),
            CSS.decl("border", "1px solid #ececf2"),
            CSS.decl("border-radius", "10px"),
            CSS.decl("background", "#ffffff")
        )

        CSS.rule(
            ".ph-exchangeable-title",
            CSS.decl("margin", "0 0 6px"),
            CSS.decl("font-weight", "700"),
            CSS.decl("font-size", "12px"),
            CSS.decl("color", "#374151")
        )

        CSS.rule(
            ".ph-component-list--exchangeable .ph-component-row",
            CSS.decl("border-top", "1px solid #ececf2"),
            CSS.decl("padding", "7px 0")
        )

        CSS.rule(
            ".ph-component-list--exchangeable .ph-component-row:first-child",
            CSS.decl("border-top", "0"),
            CSS.decl("padding-top", "0")
        )

        CSS.rule(
            ".ph-component-row--exchangeable",
            CSS.decl("border-top", "1px solid #ececf2")
        )

        CSS.media(
            "print",
            CSS.rule(".ph-sheet", CSS.decl("margin", "0")),
            CSS.rule(".ph-sheet", CSS.decl("padding", "0"))
        )

        // ---------------------------------------------
        // PACKAGE WRAPPER (spacing + stronger title + multi-page safe rail)
        // ---------------------------------------------

        CSS.rule(
            ".ph-package",
            CSS.decl("margin", "28px 0 22px") // more top breathing room between packages
        )

        CSS.rule(
            ".ph-package:first-of-type",
            CSS.decl("margin-top", "18px") // don't over-push the very first package
        )

        // Make the title read like a section header, not a random label.
        CSS.rule(
            ".ph-package-title",
            CSS.decl("margin", "0 0 10px"),
            CSS.decl("font-size", "13px"),
            CSS.decl("font-weight", "750"),
            CSS.decl("letter-spacing", "0.6px"),
            CSS.decl("text-transform", "uppercase"),
            CSS.decl("color", "#111827")
        )

        // Optional: a subtle divider under the title to separate it from the first module box
        CSS.rule(
            ".ph-package-title",
            CSS.decl("padding-bottom", "8px"),
            CSS.decl("border-bottom", "1px solid #ececf2")
        )

        // Multi-page safe “rail” for the package contents
        CSS.rule(
            ".ph-package-body",
            CSS.decl("margin-top", "10px"),
            CSS.decl("border-left", "3px solid #ececf2"),
            CSS.decl("padding-left", "14px"),
            CSS.decl("-webkit-box-decoration-break", "clone"),
            CSS.decl("box-decoration-break", "clone")
        )

        // Ensure modules stack and keep your existing spacing rules
        CSS.rule(
            ".ph-package-body .ph-box",
            CSS.decl("margin", "0 0 14px")
        )

        CSS.rule(
            ".ph-package-body .ph-box:last-child",
            CSS.decl("margin-bottom", "0")
        )
    }
}
