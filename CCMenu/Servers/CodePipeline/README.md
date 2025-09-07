# Add AWS CodePipeline (UI + provider) to CCMenu

This patch includes:
- Provider wrapper (`AWSCodePipelineProvider.swift`)
- Server adapter (`CodePipelineServer.swift`)
- SwiftUI settings pane (`CodePipelineSettingsView.swift`)
- Provider registration shim (`ProviderRegistration.swift`)
- Tests

## 1) Add AWS Swift SDK via SPM

In Xcode: **File → Add Packages…** →
```
https://github.com/awslabs/aws-sdk-swift
```
Select **AWSCodePipeline** and **AWSClientRuntime** for the **CCMenu** target.

## 2) Wire the registration

Call `registerAWSCodePipelineProvider()` at app startup (e.g., in `AppDelegate` or wherever other providers are registered).

The simple registry here is a placeholder. Replace it with the app’s actual factory/registry (or adapt the closure to what CCMenu expects).

## 3) Show the settings pane

- If the app uses SwiftUI for settings, embed `CodePipelineSettingsView` in your “Add Server” flow.
- If the app uses AppKit, wrap via `NSHostingView(rootView: CodePipelineSettingsView())`.

The view lets users specify **Region** and an optional **Profile** (shared profile name). “Test connection” lists pipelines.

## 4) Persisting settings

Persist `region` and `profile` alongside other server config (e.g., UserDefaults or your existing model). When instantiating the server, pass those values to `CodePipelineServer(region:profile:)`.

## 5) Polling

Use your existing polling loop to fetch states:
```swift
let status = try await server.latestStatus(for: pipelineName)
// map "success/failed/running/unknown" to CCMenu colors
```

## 6) IAM permissions

Read-only policy is sufficient:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "codepipeline:ListPipelines",
      "codepipeline:ListPipelineExecutions",
      "codepipeline:GetPipelineState",
      "codepipeline:GetPipeline"
    ],
    "Resource": "*"
  }]
}
```

## 7) SSO profiles

Users with IAM Identity Center (SSO) should run:
```
aws sso login --profile <name>
```
before using the provider. The SDK will pick up the cached credentials via `AWS_PROFILE`.

## 8) Notes / TODOs

- Replace the placeholder `CCMenuServerProtocol` with the actual protocol in CCMenu.
- If you need concurrent multi-profile polling, move away from global `AWS_PROFILE` to an explicit credentials provider when the SDK exposes it for profiles.
- If the app doesn’t use SwiftUI, the settings view serves as a reference: mirror the fields/actions in your NSView-based UI.

---

Happy to iterate if you want me to align these files with the exact CCMenu provider interfaces after you push your fork’s current codegen / protocols.