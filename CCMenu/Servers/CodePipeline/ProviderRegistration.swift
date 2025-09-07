//
//  ProviderRegistration.swift
//  CCMenu
//
//  Registers an "AWS CodePipeline" provider type.
//  NOTE: Wire this into whatever factory/registry the app uses.
//

import Foundation

public enum ServerKind: String {
    case githubActions = "github-actions"
    case gitlab = "gitlab"
    case awsCodePipeline = "aws-codepipeline" // NEW
}

// Example registry placeholder.
public final class ServerRegistry {
    public static let shared = ServerRegistry()
    private init() {}

    // Map kind -> factory
    private var factories: [ServerKind: (Dictionary<String, String>) throws -> Any] = [:]

    public func register(kind: ServerKind, factory: @escaping (Dictionary<String, String>) throws -> Any) {
        factories[kind] = factory
    }

    public func make(kind: ServerKind, settings: Dictionary<String, String>) throws -> Any {
        guard let f = factories[kind] else { throw NSError(domain: "CCMenu", code: 404, userInfo: [NSLocalizedDescriptionKey: "No factory for kind \(kind)"]) }
        return try f(settings)
    }
}

// Call this at app startup (e.g., AppDelegate) to register the provider.
public func registerAWSCodePipelineProvider() {
    ServerRegistry.shared.register(kind: .awsCodePipeline) { settings in
        let region = settings["region"] ?? "us-east-1"
        let profile = settings["profile"]
        return try CodePipelineServer(region: region, profile: profile)
    }
}