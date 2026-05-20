import SwiftUI

struct NativeCaptureView: View {
    let routeID: String
    let routeTitle: String
    let runtimeLabel: String
    let transferID: String
    @ObservedObject private var transferCoordinator: TransferCoordinator

    @State private var stagedLocalFile = false

    init(
        routeID: String,
        routeTitle: String,
        runtimeLabel: String = "Native capture",
        transferID: String,
        transferCoordinator: TransferCoordinator?
    ) {
        self.routeID = routeID
        self.routeTitle = routeTitle
        self.runtimeLabel = runtimeLabel
        self.transferID = transferID
        self.transferCoordinator =
            transferCoordinator ?? TransferCoordinator(routeID: routeID, declaredTransfers: [])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(routeTitle)
                .font(.system(size: 28, weight: .semibold))

            Text(runtimeLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Capture media locally, stage it inside the shell, then hand it off through the declared transfer seam.")
                .font(.system(size: 16))

            if stagedLocalFile {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Captured locally")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Local staging is complete. Transfer handoff stays explicit until `\(transferID)` starts.")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }

            Button("Stage For Transfer") {
                onStageForTransfer()
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel Capture") {
                stagedLocalFile = false
            }
            .buttonStyle(.bordered)

            Spacer()

            Text("Route: \(routeID)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func onStageForTransfer() {
        stagedLocalFile = true

        _ = transferCoordinator.stageCapturedMedia(
            transferID: transferID,
            localPath: "/tmp/\(transferID)-captured.jpg",
            mediaType: "image/jpeg",
            bytes: 524_288
        )
    }
}
