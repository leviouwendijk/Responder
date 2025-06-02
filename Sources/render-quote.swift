import Foundation
import plate
import Economics

func render(quota: CustomQuota) throws {
    let tiers = quota.tiers()

    var repls: [StringTemplateReplacement] = []
    for t in tiers {
        let r = t.replacements(roundTo: 10)
        repls.append(contentsOf: r)
    }

    // let logoPath = try LoadableResource(name: "logo", fileExtension: "png").path()
    let logoPath = try ResourcesEnvironment.require(.h_logo)
    let logoRepl = StringTemplateReplacement(placeholders: ["logo_path"], replacement: logoPath, initializer: .auto)
    repls.append(logoRepl)

    let templatePath = try ResourcesEnvironment.require(.quote_template)
    let outputPath = "\(Home.string())/myworkdir/pdf_output/travel/offerte.pdf"

    try pdf(template: templatePath, destination: outputPath, replacements: repls)
}

func pdf(
    template: String,
    destination: String,
    replacements: [StringTemplateReplacement]
) throws {
    // let htmlRaw = try LoadableResource(name: template, fileExtension: "html").content()
    let htmlRaw = try ResourceLoader.contents(at: template)
    let converter = StringTemplateConverter(text: htmlRaw, replacements: replacements)
    let html = converter.replace()
    try html.weasyPDF(destination: destination)
    try copyFileObjectToClipboard(path: destination)
}
