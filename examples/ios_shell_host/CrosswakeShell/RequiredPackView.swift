import SwiftUI

struct RequiredPackView: View {
    let routeID: String
    let runtimeLabel: String
    // The view stays bound to PackStore-owned lifecycle truth.
    let status: RequiredPackStatus
    let onInstall: () -> Void
    let onRetry: () -> Void
    let onInvalidate: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Required pack")
                    .font(.largeTitle.weight(.semibold))

                HStack(spacing: 8) {
                    Text(runtimeLabel)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.teal.opacity(0.12))
                        .clipShape(Capsule())

                    Text(status.state.rawValue)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                Text("Crosswake blocked route activation until this declared pack verifies as available.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    metadataRow("Pack name", value: status.packID)
                    metadataRow("Required version", value: status.requiredVersion)
                    metadataRow("Installed version", value: status.installedVersion ?? "none")
                    metadataRow("Size", value: status.bytes.map { byteFormatter.string(fromByteCount: Int64($0)) } ?? "unknown")
                    metadataRow("Latest verification", value: verificationLabel)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if let stage = status.installStage {
                    Text(stage.rawValue)
                        .font(.headline)
                }

                if let failureReason = status.failureReason {
                    Text("Failure: \(failureReason)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if let lastKnownVersion = status.lastKnownVersion {
                    Text("Last successful version: \(lastKnownVersion)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    primaryAction

                    if status.state == .available || status.lastKnownVersion != nil {
                        Button("Invalidate Pack", role: .destructive, action: onInvalidate)
                            .buttonStyle(.bordered)
                    }
                }

                Text("Route: \(routeID)")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var primaryAction: some View {
        Button(primaryTitle, action: primaryHandler)
            .buttonStyle(.borderedProminent)
            .disabled(status.state == .installing || status.state == .invalidating || status.state == .checking)
    }

    private var primaryTitle: String {
        switch status.state {
        case .notInstalled:
            return "Install Required Pack"
        case .stale:
            return "Update Pack"
        case .failed:
            return "Retry Install"
        case .available:
            return "Reverify Pack"
        case .installing:
            return "Installing"
        case .invalidating:
            return "Invalidating"
        case .checking:
            return "Checking"
        }
    }

    private var primaryHandler: () -> Void {
        switch status.state {
        case .failed:
            return onRetry
        default:
            return onInstall
        }
    }

    private var verificationLabel: String {
        guard let verifiedAt = status.verifiedAt else {
            return "none"
        }

        return verifiedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter
    }()

    @ViewBuilder
    private func metadataRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(value == status.packID || value == status.requiredVersion || value == (status.installedVersion ?? "none") ? .body.monospaced() : .body)
        }
    }
}
