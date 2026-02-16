import Foundation
import Interfaces

public enum ProgramExport {
    public struct Request: Sendable {
        public var output: String

        public var title: String
        public var filename: String
        public var margins: Double
        public var debugHTML: Bool

        public var estimateBand: ProgramTally.EstimateBand
        public var tallyPlacements: Set<ModuleComponentPlacement>
        public var sessionDuration: Int

        // Pricing
        public var sessionRate: Double
        public var homeSessions: Int
        public var travelDistanceKm: Double
        public var travelRatePerKm: Double

        public var includePriceInProgram: Bool

        public init(
            output: String = "",
            title: String = "Pakketsamenstelling",
            filename: String = "programma-overzicht",
            margins: Double = 35,
            debugHTML: Bool = false,
            estimateBand: ProgramTally.EstimateBand = .low_high,
            tallyPlacements: Set<ModuleComponentPlacement> = [.elementary],
            sessionDuration: Int = 60,
            sessionRate: Double = 300,
            homeSessions: Int = 0,
            travelDistanceKm: Double = 0,
            travelRatePerKm: Double = 2.50,
            includePriceInProgram: Bool = true,
        ) {
            self.output = output
            self.title = title
            self.filename = filename
            self.margins = margins
            self.debugHTML = debugHTML
            self.estimateBand = estimateBand
            self.tallyPlacements = tallyPlacements
            self.sessionDuration = sessionDuration
            self.sessionRate = sessionRate
            self.homeSessions = homeSessions
            self.travelDistanceKm = travelDistanceKm
            self.travelRatePerKm = travelRatePerKm
            self.includePriceInProgram = includePriceInProgram
        }
    }

    public static func export(program: [Package], request: Request = .init()) throws -> URL {
        let includedProgram = program.filter { $0.include }

        let overview = makeOverview(program: includedProgram, request: request)

        let html = ProgramHTML.build(
            program: includedProgram,
            title: request.title,
            overview: overview
        ).render()

        let dest = try resolveDestination(request: request)

        try FileManager.default.createDirectory(
            at: dest.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if request.debugHTML {
            do {
                let debugHTML = dest
                    .deletingPathExtension()
                    .appendingPathExtension("debug.html")
                try html.write(to: debugHTML, atomically: true, encoding: .utf8)
            } catch {
                // ignore
            }
        }

        let cssMargins = CSSMargins(request.margins)
        let css = CSSPageSetting(margins: cssMargins)

        do {
            try html.weasyPDF(css: css, destination: dest.path)
        } catch {
            logPDFExportFailure(
                error: error,
                destination: dest,
                request: request,
                htmlBytes: html.utf8.count
            )
            throw error
        }

        return dest
    }

    private static let euroFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "nl_NL")
        f.currencyCode = "EUR"
        return f
    }()

    private static func formatEUR(_ value: Double) -> String {
        euroFormatter.string(from: NSNumber(value: value)) ?? "€ \(String(format: "%.2f", value))"
    }

    private static func makeOverview(program: [Package], request: Request) -> DocDataBox {
        // Placeholders for now (you said hardcode)
        let clientName = "—"
        let dogName = "—"

        let dateLabel: String = {
            let f = DateFormatter()
            f.locale = Locale(identifier: "nl_NL")
            f.dateFormat = "d MMMM yyyy"
            return f.string(from: Date())
        }()

        let sessions = ProgramTally.sessions(
            program: program,
            sessionDuration: request.sessionDuration,
            band: request.estimateBand,
            placements: request.tallyPlacements
        )

        let estimatedSessions: (low: Int, high: Int)? = {
            let r = sessions.rounded
            if r.low == 0 && r.high == 0 { return nil }
            return (low: r.low, high: r.high)
        }()

        let includedPackages = program.map(\.title)

        // Pricing:
        // - session tally uses the estimate band HIGH
        // - plus travel: homeSessions * travelDistanceKm * travelRatePerKm
        let pricedSessionsHigh = sessions.rounded.high
        let sessionCost = Double(pricedSessionsHigh) * max(0, request.sessionRate)

        let travelCost = Double(max(0, request.homeSessions))
            * max(0, request.travelDistanceKm)
            * max(0, request.travelRatePerKm)

        let totalPrice = sessionCost + travelCost

        let priceLabel: String? = {
            guard request.includePriceInProgram else { return nil }
            if pricedSessionsHigh == 0 && request.homeSessions == 0 { return nil }
            return formatEUR(totalPrice)
        }()

        return DocDataBox(
            dateLabel: dateLabel,
            clientName: clientName,
            dogName: dogName,
            estimatedSessions: estimatedSessions,
            includedPackages: includedPackages,
            priceLabel: priceLabel,
            // adding for dot spread
            estimateBand: request.estimateBand
        )
    }

    private static func resolveDestination(request: Request) throws -> URL {
        let output = normalizePath(request.output)

        // Default to ~/Desktop when output is empty OR resolves to "/" (e.g. currentDirectoryPath in apps)
        if output.isEmpty || output == "/" {
            return try defaultDestinationOnDesktop(request: request)
        }

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: output, isDirectory: &isDir) {
            if isDir.boolValue {
                return URL(fileURLWithPath: output, isDirectory: true)
                    .appendingPathComponent("\(request.filename).pdf")
                    .standardizedFileURL
            } else {
                return forcePDFExtension(URL(fileURLWithPath: output, isDirectory: false))
                    .standardizedFileURL
            }
        }

        let endsWithSlash = output.hasSuffix("/") || output.hasSuffix("\\")
        let outURL = URL(fileURLWithPath: output, isDirectory: endsWithSlash)

        if endsWithSlash {
            return outURL
                .appendingPathComponent("\(request.filename).pdf")
                .standardizedFileURL
        }

        let last = outURL.lastPathComponent
        if last.contains(".") {
            return forcePDFExtension(outURL).standardizedFileURL
        } else {
            return URL(fileURLWithPath: output, isDirectory: true)
                .appendingPathComponent("\(request.filename).pdf")
                .standardizedFileURL
        }
    }

    /// HOME/Desktop
    private static func defaultDestinationOnDesktop(request: Request) throws -> URL {
        let desktop = try FileManager.default.url(
            for: .desktopDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return desktop
            .appendingPathComponent("\(request.filename).pdf")
            .standardizedFileURL
    }

    private static func forcePDFExtension(_ url: URL) -> URL {
        if url.pathExtension.lowercased() == "pdf" {
            return url
        }

        if url.pathExtension.isEmpty {
            return url.appendingPathExtension("pdf")
        } else {
            return url.deletingPathExtension().appendingPathExtension("pdf")
        }
    }

    private static func normalizePath(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if trimmed.hasPrefix("~") {
            return (trimmed as NSString).expandingTildeInPath
        }

        return trimmed
    }

    // MARK: - Logging

    private static func logPDFExportFailure(
        error: Error,
        destination: URL,
        request: Request,
        htmlBytes: Int
    ) {
        let ns = error as NSError

        let destPath = destination.path
        let destDir = destination.deletingLastPathComponent().path

        var dirIsDir: ObjCBool = false
        let dirExists = FileManager.default.fileExists(atPath: destDir, isDirectory: &dirIsDir)
        let destExists = FileManager.default.fileExists(atPath: destPath)

        let dirWritable = FileManager.default.isWritableFile(atPath: destDir)
        let destWritableIfExists = FileManager.default.isWritableFile(atPath: destPath)

        let lines: [String] = [
            "",
            "=== ProgramExport PDF failed ===",
            "destination: \(destPath)",
            "destination_dir: \(destDir)",
            "dir_exists: \(dirExists) (isDir: \(dirIsDir.boolValue))",
            "dest_exists: \(destExists)",
            "dir_writable: \(dirWritable)",
            "dest_writable_if_exists: \(destWritableIfExists)",
            "request.output: \(request.output)",
            "normalized_output: \(normalizePath(request.output))",
            "request.filename: \(request.filename)",
            "margins: \(request.margins)",
            "debugHTML: \(request.debugHTML)",
            "html_bytes: \(htmlBytes)",
            "error_type: \(String(reflecting: type(of: error)))",
            "localizedDescription: \(error.localizedDescription)",
            "NSError.domain: \(ns.domain)",
            "NSError.code: \(ns.code)",
            ns.userInfo.isEmpty ? "NSError.userInfo: <empty>" : "NSError.userInfo: \(ns.userInfo)",
            "=== /ProgramExport ===",
            ""
        ]

        fputs(lines.joined(separator: "\n"), stderr)
    }
}

// import Foundation
// import Interfaces

// public enum ProgramExport {
//     public struct Request: Sendable {
//         public var output: String

//         public var title: String
//         public var filename: String
//         public var margins: Double
//         public var debugHTML: Bool

//         public var estimateBand: ProgramTally.EstimateBand
//         public var tallyPlacements: Set<ModuleComponentPlacement>
//         public var sessionDuration: Int

//         public init(
//             output: String = "",
//             title: String = "Pakketsamenstelling",
//             filename: String = "programma-overzicht",
//             margins: Double = 35,
//             debugHTML: Bool = false,
//             estimateBand: ProgramTally.EstimateBand = .low_high,
//             tallyPlacements: Set<ModuleComponentPlacement> = [.elementary],
//             sessionDuration: Int = 60
//         ) {
//             self.output = output
//             self.title = title
//             self.filename = filename
//             self.margins = margins
//             self.debugHTML = debugHTML
//             self.estimateBand = estimateBand
//             self.tallyPlacements = tallyPlacements
//             self.sessionDuration = sessionDuration
//         }
//     }

//     public static func export(program: [Package], request: Request = .init()) throws -> URL {
//         let includedProgram = program.filter { $0.include }

//         let overview = makeOverview(program: includedProgram, request: request)

//         let html = ProgramHTML.build(
//             program: includedProgram,
//             title: request.title,
//             overview: overview
//         ).render()

//         let dest = try resolveDestination(request: request)

//         try FileManager.default.createDirectory(
//             at: dest.deletingLastPathComponent(),
//             withIntermediateDirectories: true
//         )

//         if request.debugHTML {
//             do {
//                 let debugHTML = dest
//                     .deletingPathExtension()
//                     .appendingPathExtension("debug.html")
//                 try html.write(to: debugHTML, atomically: true, encoding: .utf8)
//             } catch {
//                 // ignore
//             }
//         }

//         let cssMargins = CSSMargins(request.margins)
//         let css = CSSPageSetting(margins: cssMargins)

//         do {
//             try html.weasyPDF(css: css, destination: dest.path)
//         } catch {
//             logPDFExportFailure(
//                 error: error,
//                 destination: dest,
//                 request: request,
//                 htmlBytes: html.utf8.count
//             )
//             throw error
//         }

//         return dest
//     }

//     private static func makeOverview(program: [Package], request: Request) -> DocDataBox {
//         // Placeholders for now (you said hardcode)
//         let clientName = "—"
//         let dogName = "—"

//         let dateLabel: String = {
//             let f = DateFormatter()
//             f.locale = Locale(identifier: "nl_NL")
//             f.dateFormat = "d MMMM yyyy"
//             return f.string(from: Date())
//         }()

//         let sessions = ProgramTally.sessions(
//             program: program,
//             sessionDuration: request.sessionDuration,
//             band: request.estimateBand,
//             placements: request.tallyPlacements
//         )

//         let estimatedSessions: (low: Int, high: Int)? = {
//             let r = sessions.rounded
//             if r.low == 0 && r.high == 0 { return nil }
//             return (low: r.low, high: r.high)
//         }()

//         let includedPackages = program.map(\.title)

//         return DocDataBox(
//             dateLabel: dateLabel,
//             clientName: clientName,
//             dogName: dogName,
//             estimatedSessions: estimatedSessions,
//             includedPackages: includedPackages
//         )
//     }

//     private static func resolveDestination(request: Request) throws -> URL {
//         let output = normalizePath(request.output)

//         // Default to ~/Desktop when output is empty OR resolves to "/" (e.g. currentDirectoryPath in apps)
//         if output.isEmpty || output == "/" {
//             return try defaultDestinationOnDesktop(request: request)
//         }

//         var isDir: ObjCBool = false
//         if FileManager.default.fileExists(atPath: output, isDirectory: &isDir) {
//             if isDir.boolValue {
//                 return URL(fileURLWithPath: output, isDirectory: true)
//                     .appendingPathComponent("\(request.filename).pdf")
//                     .standardizedFileURL
//             } else {
//                 return forcePDFExtension(URL(fileURLWithPath: output, isDirectory: false))
//                     .standardizedFileURL
//             }
//         }

//         let endsWithSlash = output.hasSuffix("/") || output.hasSuffix("\\")
//         let outURL = URL(fileURLWithPath: output, isDirectory: endsWithSlash)

//         if endsWithSlash {
//             return outURL
//                 .appendingPathComponent("\(request.filename).pdf")
//                 .standardizedFileURL
//         }

//         let last = outURL.lastPathComponent
//         if last.contains(".") {
//             return forcePDFExtension(outURL).standardizedFileURL
//         } else {
//             return URL(fileURLWithPath: output, isDirectory: true)
//                 .appendingPathComponent("\(request.filename).pdf")
//                 .standardizedFileURL
//         }
//     }

//     /// HOME/Desktop
//     private static func defaultDestinationOnDesktop(request: Request) throws -> URL {
//         let desktop = try FileManager.default.url(
//             for: .desktopDirectory,
//             in: .userDomainMask,
//             appropriateFor: nil,
//             create: true
//         )

//         return desktop
//             .appendingPathComponent("\(request.filename).pdf")
//             .standardizedFileURL
//     }

//     private static func forcePDFExtension(_ url: URL) -> URL {
//         if url.pathExtension.lowercased() == "pdf" {
//             return url
//         }

//         if url.pathExtension.isEmpty {
//             return url.appendingPathExtension("pdf")
//         } else {
//             return url.deletingPathExtension().appendingPathExtension("pdf")
//         }
//     }

//     private static func normalizePath(_ path: String) -> String {
//         let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
//         guard !trimmed.isEmpty else { return "" }

//         if trimmed.hasPrefix("~") {
//             return (trimmed as NSString).expandingTildeInPath
//         }

//         return trimmed
//     }

//     // MARK: - Logging

//     private static func logPDFExportFailure(
//         error: Error,
//         destination: URL,
//         request: Request,
//         htmlBytes: Int
//     ) {
//         let ns = error as NSError

//         let destPath = destination.path
//         let destDir = destination.deletingLastPathComponent().path

//         var dirIsDir: ObjCBool = false
//         let dirExists = FileManager.default.fileExists(atPath: destDir, isDirectory: &dirIsDir)
//         let destExists = FileManager.default.fileExists(atPath: destPath)

//         let dirWritable = FileManager.default.isWritableFile(atPath: destDir)
//         let destWritableIfExists = FileManager.default.isWritableFile(atPath: destPath)

//         let lines: [String] = [
//             "",
//             "=== ProgramExport PDF failed ===",
//             "destination: \(destPath)",
//             "destination_dir: \(destDir)",
//             "dir_exists: \(dirExists) (isDir: \(dirIsDir.boolValue))",
//             "dest_exists: \(destExists)",
//             "dir_writable: \(dirWritable)",
//             "dest_writable_if_exists: \(destWritableIfExists)",
//             "request.output: \(request.output)",
//             "normalized_output: \(normalizePath(request.output))",
//             "request.filename: \(request.filename)",
//             "margins: \(request.margins)",
//             "debugHTML: \(request.debugHTML)",
//             "html_bytes: \(htmlBytes)",
//             "error_type: \(String(reflecting: type(of: error)))",
//             "localizedDescription: \(error.localizedDescription)",
//             "NSError.domain: \(ns.domain)",
//             "NSError.code: \(ns.code)",
//             ns.userInfo.isEmpty ? "NSError.userInfo: <empty>" : "NSError.userInfo: \(ns.userInfo)",
//             "=== /ProgramExport ===",
//             ""
//         ]

//         fputs(lines.joined(separator: "\n"), stderr)
//     }
// }
