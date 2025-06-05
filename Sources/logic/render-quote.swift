// import Foundation
// import plate
// import Economics
// import Interfaces

// func prepareEnvironment() throws {
//     let env = DefaultEnvironmentVariables.string()
//     let vars = try ApplicationEnvironmentLoader.load(from: env)
//     ApplicationEnvironmentLoader.set(to: vars)
// }

// // good generic render implementation, but unused for particular tier selection export
// // func render(quota: CustomQuota) throws {
// //     try prepareEnvironment()

// //     let tiers = quota.tiers()

// //     var repls: [StringTemplateReplacement] = []

// //     for t in tiers {
// //         let r = t.replacements(roundTo: 10)
// //         repls.append(contentsOf: r)
// //     }
    
// //     let estPlaceholders = quota.replacements()
// //     repls.append(contentsOf: estPlaceholders)

// //     // let logoPath = try LoadableResource(name: "logo", fileExtension: "png").path()
// //     let logoPath = try ResourcesEnvironment.require(.h_logo)
// //     let logoRepl = StringTemplateReplacement(placeholders: ["logo_path"], replacement: logoPath, initializer: .auto)
// //     repls.append(logoRepl)

// //     let templatePath = try ResourcesEnvironment.require(.quote_template)
// //     let outputPath = "\(Home.string())/myworkdir/pdf_output/travel/offerte.pdf"
// //     print("out:", outputPath)

// //     try pdf(template: templatePath, destination: outputPath, replacements: repls)
// // }

// func renderTier(quota: CustomQuota, for tier: QuotaTierType) throws {
//     try prepareEnvironment()

//     let t = try quota.tier(being: tier)

//     var repls: [StringTemplateReplacement] = []

//     let p = t.standardPriceStringReplacements(roundTo: 10)
//     repls.append(contentsOf: p)

//     let l = t.locationStringReplacements()
//     repls.append(contentsOf: l)
    
//     let kmCode = quota.kilometerCodeReplacement(for: tier)
//     repls.append(contentsOf: kmCode)

//     // let logoPath = try LoadableResource(name: "logo", fileExtension: "png").path()
//     let logoPath = try ResourcesEnvironment.require(.h_logo)
//     let logoRepl = StringTemplateReplacement(placeholders: ["logo_path"], replacement: logoPath, initializer: .auto)
//     repls.append(logoRepl)

//     let templatePath = try ResourcesEnvironment.require(.quote_template)
//     let outputPath = "\(Home.string())/myworkdir/pdf_output/travel/offerte.pdf"
//     print("out:", outputPath)

//     try pdf(template: templatePath, destination: outputPath, replacements: repls)
// }

// func pdf(
//     template: String,
//     destination: String,
//     replacements: [StringTemplateReplacement]
// ) throws {
//     // let htmlRaw = try LoadableResource(name: template, fileExtension: "html").content()
//     let htmlRaw = try ResourceLoader.contents(at: template)
//     let converter = StringTemplateConverter(text: htmlRaw, replacements: replacements)
//     let html = converter.replace()
//     try html.weasyPDF(destination: destination)
//     try copyFileObjectToClipboard(path: destination)
// }
