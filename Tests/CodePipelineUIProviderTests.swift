import XCTest
@testable import CCMenu
import AWSCodePipeline

final class CodePipelineUIProviderTests: XCTestCase {

    struct MockClient: CodePipelineClientish {
        func listPipelinesPaginator(input: ListPipelinesInput) async throws -> PaginatorSequence<ListPipelinesInput, ListPipelinesOutput> {
            let page = ListPipelinesOutput(pipelines: [
                PipelineSummary(name: "alpha", version: 1, updated: Date()),
                PipelineSummary(name: "beta", version: 1, updated: Date())
            ])
            return SinglePagePaginator(seed: page)
        }
        func listPipelineExecutions(input: ListPipelineExecutionsInput) async throws -> ListPipelineExecutionsOutput {
            let s = PipelineExecutionSummary(status: .inProgress, startTime: Date().addingTimeInterval(-60), lastUpdateTime: Date(), pipelineExecutionId: "exe-1", sourceRevisions: nil, trigger: nil, artifactRevisions: nil)
            return ListPipelineExecutionsOutput(pipelineExecutionSummaries: [s], nextToken: nil)
        }
        func getPipelineState(input: GetPipelineStateInput) async throws -> GetPipelineStateOutput {
            GetPipelineStateOutput(created: Date(), pipelineName: input.name, pipelineVersion: 1, stageStates: nil, updated: Date())
        }
    }

    func testDiscoverAndMap() async throws {
        let svc = try CodePipelineService(client: MockClient())
        let list = try await svc.listPipelines()
        XCTAssertEqual(list.map { $0.name }, ["alpha", "beta"])

        let status = try await svc.latestExecutionStatus(pipelineName: "alpha")
        switch status.state {
        case .running: break
        default: XCTFail("expected running")
        }
    }
}

// Single-page paginator helper
public struct SinglePagePaginator<Input, Output>: AsyncSequence, AsyncIteratorProtocol {
    public typealias Element = Output
    public var seed: Output?
    public init(seed: Output) { self.seed = seed }
    public mutating func next() async throws -> Output? {
        defer { seed = nil }
        return seed
    }
    public func makeAsyncIterator() -> SinglePagePaginator<Input, Output> { self }
}