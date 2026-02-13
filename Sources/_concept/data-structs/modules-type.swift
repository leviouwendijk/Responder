import Foundation

// MODULES
public struct Module: Sendable, Codable, Hashable, Identifiable {
    public var id: UUID
    public var title: String?
    public var entries: [ModuleEntry]

    public init(
        id: UUID = UUID(),
        title: String? = nil,
        entries: [ModuleEntry]
    ) {
        self.id = id
        self.title = title
        self.entries = entries
    }
}

public enum ModuleComponentPlacement: String, Sendable, Codable, Hashable, CaseIterable {
    case elementary
    case exchangeable
}

public struct ModuleEntry: Sendable, Codable, Hashable, Identifiable {
    public var id: UUID
    public var component: ModuleComponent
    public var placement: ModuleComponentPlacement
    public var include: Bool

    public init(
        id: UUID = UUID(),
        component: ModuleComponent,
        placement: ModuleComponentPlacement,
        include: Bool = true
    ) {
        self.id = id
        self.component = component
        self.placement = placement
        self.include = include
    }
}

// module component == lesson concepts x lesson format
public struct ModuleComponent: Sendable, Codable, Hashable {
    public var concepts: Set<LessonConcept>
    public var format: Set<LessonFormat>
    public var allocation: SessionAllocation?

    public var details: String?  // internal notes

    public var tagline: String?
    public var caption: String?

    public init(
        concepts: Set<LessonConcept>,
        format: Set<LessonFormat> = [],
        allocation: SessionAllocation? = nil,
        details: String? = nil,
        tagline: String? = nil,
        caption: String? = nil
    ) {
        self.concepts = concepts
        self.format = format
        self.allocation = allocation
        self.details = details
        self.tagline = tagline
        self.caption = caption
    }
}

extension ModuleComponent {
    public static func empty() -> ModuleComponent {
        .init(concepts: [], format: [])
    }
}
