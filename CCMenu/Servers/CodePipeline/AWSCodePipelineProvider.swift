//
//  AWSCodePipelineProvider.swift
//  CCMenu
//
//  Provider-layer wrapper for AWS CodePipeline.
//  Uses shared profile via AWS_PROFILE, plus explicit region.
//

import Foundation
import AWSCodePipeline
import AWSClientRuntime

public enum CPBuildState: Sendable {
    case success, failed, running, unknown
}

public struct CPPipelineSummary: Hashable, Sendable {
    public let name: String
    public let updatedAt: Date?
    public init(name: String, updatedAt: Date?) {
        self.name = name; self.updatedAt = updatedAt
    }
}

public struct CPExecutionStatus: Sendable {
    public let state: CPBuildState
    public let startedAt: Date?
    public let endedAt: Date?
    public let rawStatus: String
    public let executionId: String?
    public init(state: CPBuildState, startedAt: Date?, endedAt: Date?, rawStatus: String, executionId: String?) {
        self.state = state; self.startedAt = startedAt; self.endedAt = endedAt; self.rawStatus = rawStatus; self.executionId = executionId
    }
}

public protocol CodePipelineClientish {
    func listPipelinesPaginator(input: ListPipelinesInput) async throws -> PaginatorSequence<ListPipelinesInput, ListPipelinesOutput>
    func listPipelineExecutions(input: ListPipelineExecutionsInput) async throws -> ListPipelineExecutionsOutput
    func getPipelineState(input: GetPipelineStateInput) async throws -> GetPipelineStateOutput
}
extension CodePipelineClient: CodePipelineClientish {}

public final class CodePipelineService {
    private let client: CodePipelineClientish

    public convenience init(region: String, profile: String?) throws {
        if let p = profile, !p.isEmpty { setenv("AWS_PROFILE", p, 1) }
        let cfg = try CodePipelineClient.CodePipelineClientConfiguration(region: region)
        try self.init(client: CodePipelineClient(config: cfg))
    }

    public init(client: CodePipelineClientish) throws {
        self.client = client
    }

    public func listPipelines(limit: Int = 100) async throws -> [CPPipelineSummary] {
        var out: [CPPipelineSummary] = []
        var pager = try await client.listPipelinesPaginator(input: ListPipelinesInput(maxResults: limit))
        for try await page in pager {
            for p in page.pipelines ?? [] {
                out.append(.init(name: p.name ?? "", updatedAt: p.updated))
            }
        }
        return out.sorted { $0.name < $1.name }
    }

    public func latestExecutionStatus(pipelineName: String) async throws -> CPExecutionStatus {
        let page = try await client.listPipelineExecutions(input: ListPipelineExecutionsInput(maxResults: 1, pipelineName: pipelineName))
        guard let summary = page.pipelineExecutionSummaries?.first else {
            return CPExecutionStatus(state: .unknown, startedAt: nil, endedAt: nil, rawStatus: "NoExecutions", executionId: nil)
        }
        let raw = summary.status?.rawValue ?? "Unknown"
        let state: CPBuildState = switch raw {
            case "Succeeded": .success
            case "Failed": .failed
            case "InProgress": .running
            default: .unknown
        }
        return CPExecutionStatus(state: state, startedAt: summary.startTime, endedAt: summary.lastUpdateTime, rawStatus: raw, executionId: summary.pipelineExecutionId)
    }

    public func currentState(pipelineName: String) async throws -> GetPipelineStateOutput {
        try await client.getPipelineState(input: GetPipelineStateInput(name: pipelineName))
    }
}