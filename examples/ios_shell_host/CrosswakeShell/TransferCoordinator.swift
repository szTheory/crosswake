import Foundation
import SwiftUI

@MainActor
final class TransferCoordinator: ObservableObject {
    enum TransferCommand: String, CaseIterable {
        case transferImport = "transfer.import"
        case transferExport = "transfer.export"
        case transferDownload = "transfer.download"
        case transferUploadPrepare = "transfer.upload.prepare"
    }

    enum TransferState: String, CaseIterable {
        case queued = "queued"
        case preparing = "preparing"
        case transferring = "transferring"
        case awaitingNetwork = "awaiting_network"
        case verifying = "verifying"
        case complete = "complete"
        case failed = "failed"
        case canceled = "canceled"
    }

    struct TransferRecord: Equatable {
        let routeID: String
        let transferID: String
        let command: TransferCommand
        let intent: String
        let source: String?
        let destination: String?
        let state: TransferState
        let detail: String
        let stagedPath: String?
    }

    private let routeID: String
    private let declaredTransfers: [ShellManifest.TransferSeam]

    @Published private(set) var transfers: [String: TransferRecord] = [:]

    init(routeID: String, declaredTransfers: [ShellManifest.TransferSeam]) {
        self.routeID = routeID
        self.declaredTransfers = declaredTransfers
    }

    func execute(command: String, payload: [String: String], correlationID: String) -> [String: String]? {
        guard let transferCommand = TransferCommand(rawValue: command),
              let transferID = payload["transfer_id"],
              let seam = declaredTransfer(id: transferID, matching: transferCommand) else {
            return nil
        }

        let record = transition(
            transferID: transferID,
            command: transferCommand,
            seam: seam,
            stagedPath: payload["staged_path"],
            correlationID: correlationID
        )

        transfers[transferID] = record

        return [
            "route_id": routeID,
            "transfer_id": transferID,
            "state": record.state.rawValue,
            "intent": seam.intent,
            "detail": record.detail,
            "correlation_id": correlationID
        ]
    }

    func stageCapturedMedia(
        transferID: String,
        localPath: String,
        mediaType: String,
        bytes: Int
    ) -> [String: String]? {
        guard let seam = declaredTransfers.first(where: {
            $0.id == transferID && $0.intent == "upload" && $0.source == "native_capture"
        }) else {
            return nil
        }

        let record = TransferRecord(
            routeID: routeID,
            transferID: transferID,
            command: .transferUploadPrepare,
            intent: seam.intent,
            source: seam.source,
            destination: seam.destination,
            state: .queued,
            detail: "Captured locally. Transfer handoff stays explicit until the route starts upload preparation.",
            stagedPath: localPath
        )

        transfers[transferID] = record

        return [
            "route_id": routeID,
            "transfer_id": transferID,
            "state": record.state.rawValue,
            "intent": seam.intent,
            "staged_path": localPath,
            "media_type": mediaType,
            "bytes": String(bytes)
        ]
    }

    private func declaredTransfer(id: String, matching command: TransferCommand) -> ShellManifest.TransferSeam? {
        declaredTransfers.first(where: { seam in
            seam.id == id && commandMatchesDeclaredIntent(command, intent: seam.intent)
        })
    }

    private func commandMatchesDeclaredIntent(_ command: TransferCommand, intent: String) -> Bool {
        switch (command, intent) {
        case (.transferImport, "import"),
             (.transferExport, "export"),
             (.transferDownload, "download"),
             (.transferUploadPrepare, "upload"):
            return true
        default:
            return false
        }
    }

    private func transition(
        transferID: String,
        command: TransferCommand,
        seam: ShellManifest.TransferSeam,
        stagedPath: String?,
        correlationID: String
    ) -> TransferRecord {
        let state: TransferState
        let detail: String

        switch command {
        case .transferUploadPrepare:
            state = stagedPath == nil ? .failed : .preparing
            detail = stagedPath == nil
                ? "Upload preparation requires an explicitly staged local media file."
                : "Upload preparation acknowledged for staged media. Foreground transfer remains route-local."
        case .transferImport:
            state = .preparing
            detail = "Import preparation acknowledged. Route-local transfer remains explicit."
        case .transferExport:
            state = .queued
            detail = "Export request queued for the active route only."
        case .transferDownload:
            state = .transferring
            detail = "Download started in the foreground for the active route only."
        }

        return TransferRecord(
            routeID: routeID,
            transferID: transferID,
            command: command,
            intent: seam.intent,
            source: seam.source,
            destination: seam.destination,
            state: state,
            detail: detail + " [\(correlationID)]",
            stagedPath: stagedPath
        )
    }
}
