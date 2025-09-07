//
//  CodePipelineSettingsView.swift
//  CCMenu
//
//  A simple SwiftUI form to configure Region/Profile and test connectivity.
//  If the project uses AppKit, you can wrap this view in an NSHostingView.
//

import SwiftUI

struct CodePipelineSettingsView: View {
    @State private var region: String = "us-east-1"
    @State private var profile: String = ""
    @State private var pipelines: [String] = []
    @State private var isTesting = false
    @State private var testError: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AWS CodePipeline").font(.headline)

            Form {
                TextField("Region (e.g., us-east-1)", text: $region)
                TextField("Profile (optional; from ~/.aws/config)", text: $profile)
                HStack {
                    Button(action: testConnection) {
                        if isTesting { ProgressView() } else { Text("Test connection") }
                    }
                    .disabled(isTesting || region.isEmpty)
                    if let err = testError {
                        Text(err).foregroundColor(.red).lineLimit(2)
                    }
                }
                if !pipelines.isEmpty {
                    Text("Discovered pipelines:").font(.subheadline)
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(pipelines, id: \.self) { p in
                                Text("• \(p)")
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .padding(.vertical, 1)
                            }
                        }
                    }.frame(maxHeight: 140)
                }
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding()
    }

    private func testConnection() {
        isTesting = true
        testError = nil
        pipelines = []
        Task {
            do {
                let server = try CodePipelineServer(region: region, profile: profile.isEmpty ? nil : profile)
                let names = try await server.discoverPipelines()
                await MainActor.run {
                    self.pipelines = names
                    self.isTesting = false
                }
            } catch {
                await MainActor.run {
                    self.testError = error.localizedDescription
                    self.isTesting = false
                }
            }
        }
    }
}

#if DEBUG
struct CodePipelineSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CodePipelineSettingsView()
            .frame(width: 520, height: 360)
    }
}
#endif