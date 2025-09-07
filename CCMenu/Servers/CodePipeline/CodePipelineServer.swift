//
//  CodePipelineServer.swift
//  CCMenu
//
//  Minimal server adapter to plug the provider into CCMenu's model.
//  NOTE: Replace `CCMenuServerProtocol` with the actual protocol/abstract type used in CCMenu.
//

import Foundation

// TODO: replace this with the actual protocol from CCMenu if it exists.
public protocol CCMenuServerProtocol {
    var displayName: String { get }
    func discoverPipelines() async throws -> [String] // names
    func latestStatus(for name: String) async throws -> (state: String, startedAt: Date?, endedAt: Date?)
}

public final class CodePipelineServer: CCMenuServerProtocol {
    public let region: String
    public let profile: String?
    private let svc: CodePipelineService

    public init(region: String, profile: String?) throws {
        self.region = region
        self.profile = profile
        self.svc = try CodePipelineService(region: region, profile: profile)
    }

    public var displayName: String {
        if let p = profile, !p.isEmpty { return "AWS CodePipeline (\(region), \(p))" }
        return "AWS CodePipeline (\(region))"
    }

    public func discoverPipelines() async throws -> [String] {
        try await svc.listPipelines().map { $0.name }
    }

    public func latestStatus(for name: String) async throws -> (state: String, startedAt: Date?, endedAt: Date?) {
        let s = try await svc.latestExecutionStatus(pipelineName: name)
        let mapped: String
        switch s.state {
        case .success: mapped = "success"
        case .failed: mapped = "failed"
        case .running: mapped = "running"
        case .unknown: mapped = "unknown"
        }
        return (mapped, s.startedAt, s.endedAt)
    }
}