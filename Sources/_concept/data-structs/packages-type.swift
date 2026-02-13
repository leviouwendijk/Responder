import Foundation

// PROGRAM
public typealias Program = [Package]

public enum BehaviorProblem: String, Sendable, CaseIterable {
    case reactiviteit
    case agressie
    case verlatingsangst
    case angst
    case ongehoorzaamheid
}

public struct Package: Sendable, Codable, Hashable, Identifiable {
    public var id: UUID
    public var title: String
    public var modules: [Module]
    public var include: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        modules: [Module],
        include: Bool = true
    ) {
        self.id = id
        self.title = title
        self.modules = modules
        self.include = include
    }

    public func package() -> Package {
        return Package(
            title: title,
            modules: modules,
            include: include
        )
    }
}

public enum PrebuiltPackage {
    public static let startersvaardigheden: Package = .init(
        title: "Startersvaardigheden",
        modules: [
            PrebuiltModules.communication(),
            PrebuiltModules.motivation(),
            PrebuiltModules.engagement()
        ]
    )

    public static func hervorming(target: BehaviorProblem) -> Package {
        return .init(
            title: "Hervorming: " + target.rawValue,
            modules: 
                // self.startersvaardigheden.modules 
                // + 
                [PrebuiltModules.applied_behavior_modification(target: target)]
        )
    }
}
