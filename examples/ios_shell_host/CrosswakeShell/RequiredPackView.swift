import SwiftUI
import CrosswakeShellCore

struct RequiredPackView: View {
    struct LifecycleAccessibilityEffect: Equatable {
        let announcement: String
        let preserveFocus: Bool
    }

    typealias LifecycleAnnouncementSink = (LifecycleAccessibilityEffect) -> Void

    enum ForegroundAction: Equatable {
        case none
        case install
        case update
        case retry
        case invalidateThenInstall

        var isEnabled: Bool { self != .none }
    }

    struct Presentation: Equatable {
        let stateLabel: String
        let learnerMessage: String
        let developerRemediation: String
        let rule: String
        let owner: String
        let primaryAction: ForegroundAction
        let secondaryAction: ForegroundAction

        let statusAccessibilityIdentifier = "required-pack-status"
        let primaryActionAccessibilityIdentifier = "required-pack-primary-action"
        let invalidateActionAccessibilityIdentifier = "required-pack-invalidate-action"
        let ownerAccessibilityIdentifier = "required-pack-owner"
    }

    let routeID: String
    let runtimeLabel: String
    // The view stays bound to PackStore-owned lifecycle truth.
    let status: RequiredPackStatus
    let onInstall: () -> Void
    let onRetry: () -> Void
    let onInvalidate: () -> Void
    private let lifecycleAnnouncementSink: LifecycleAnnouncementSink

    @AccessibilityFocusState private var statusIsFocused: Bool

    init(
        routeID: String,
        runtimeLabel: String,
        status: RequiredPackStatus,
        onInstall: @escaping () -> Void,
        onRetry: @escaping () -> Void,
        onInvalidate: @escaping () -> Void,
        lifecycleAnnouncementSink: @escaping LifecycleAnnouncementSink = { effect in
            UIAccessibility.post(notification: .announcement, argument: effect.announcement)
        }
    ) {
        self.routeID = routeID
        self.runtimeLabel = runtimeLabel
        self.status = status
        self.onInstall = onInstall
        self.onRetry = onRetry
        self.onInvalidate = onInvalidate
        self.lifecycleAnnouncementSink = lifecycleAnnouncementSink
    }

    var body: some View {
        let model = Self.presentation(for: status)

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Required pronunciation audio")
                    .font(.title.weight(.semibold))

                Text(runtimeLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label(model.stateLabel, systemImage: statusSymbol)
                        .font(.headline)
                        .foregroundStyle(statusColor)
                    Text(model.learnerMessage)
                        .font(.body)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(model.statusAccessibilityIdentifier)
                .accessibilityFocused($statusIsFocused)
                .accessibilityAddTraits(.updatesFrequently)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Owner: \(model.owner)")
                        .font(.footnote)
                    Text("Rule: \(model.rule)")
                        .font(.footnote.monospaced())
                    Text(model.developerRemediation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier(model.ownerAccessibilityIdentifier)

                if model.primaryAction.isEnabled {
                    Button(actionTitle(for: model.primaryAction), action: primaryHandler(for: model.primaryAction))
                        .buttonStyle(.borderedProminent)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier(model.primaryActionAccessibilityIdentifier)
                }

                if model.secondaryAction == .invalidateThenInstall {
                    Button("Invalidate downloaded audio", role: .destructive, action: onInvalidate)
                        .buttonStyle(.bordered)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier(model.invalidateActionAccessibilityIdentifier)
                }

                Text("Route: \(routeID)")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .animation(nil, value: status.state)
        .onChange(of: status.state) { _, _ in
            // Announce changes while leaving VoiceOver focus where the learner placed it.
            lifecycleAnnouncementSink(Self.lifecycleAccessibilityEffect(for: status))
        }
    }

    static func lifecycleAccessibilityEffect(for status: RequiredPackStatus) -> LifecycleAccessibilityEffect {
        let presentation = presentation(for: status)
        return LifecycleAccessibilityEffect(
            announcement: "\(presentation.stateLabel). \(presentation.learnerMessage)",
            preserveFocus: true
        )
    }

    static func presentation(for status: RequiredPackStatus) -> Presentation {
        let failure = status.failureReason
        let requiresInvalidation = failure == .digestMismatch || failure == .sizeMismatch ||
            failure == .invalidationFailed || failure == .malformedProviderResult

        if requiresInvalidation {
            return Presentation(
                stateLabel: "Offline audio needs recovery",
                learnerMessage: "Offline audio could not be verified. Try the download again while connected.",
                developerRemediation: "Remove the downloaded audio, then install again.",
                rule: rule(for: failure),
                owner: "host pack provider",
                primaryAction: .none,
                secondaryAction: .invalidateThenInstall
            )
        }

        switch status.state {
        case .checking:
            return unavailablePresentation("Checking offline audio", "Checking whether offline audio is ready.", rule: "PACK-CHECKING")
        case .installing:
            return unavailablePresentation("Installing offline audio", "Installing offline audio. Keep this screen open.", rule: "PACK-INSTALLING")
        case .invalidating:
            return unavailablePresentation("Removing offline audio", "Removing offline audio before it can be installed again.", rule: "PACK-INVALIDATING")
        case .notInstalled:
            return actionablePresentation("Offline audio is required", "Install offline audio while connected to continue.", rule: "PACK-NOT-INSTALLED", action: .install)
        case .stale:
            return actionablePresentation("Offline audio needs an update", "Update offline audio while connected to continue.", rule: "PACK-VERSION-MISMATCH", action: .update)
        case .failed:
            return actionablePresentation("Offline audio could not be installed", "Try the download again while connected.", rule: rule(for: failure), action: .retry)
        case .available:
            return unavailablePresentation("Offline audio is ready", "Pronunciation audio is ready for offline use.", rule: "PACK-READY")
        }
    }

    private static func unavailablePresentation(_ state: String, _ message: String, rule: String) -> Presentation {
        Presentation(stateLabel: state, learnerMessage: message, developerRemediation: "Wait for this foreground step to finish.", rule: rule, owner: "host pack provider", primaryAction: .none, secondaryAction: .none)
    }

    private static func actionablePresentation(_ state: String, _ message: String, rule: String, action: ForegroundAction) -> Presentation {
        Presentation(stateLabel: state, learnerMessage: message, developerRemediation: "Use the foreground action when connected.", rule: rule, owner: "host pack provider", primaryAction: action, secondaryAction: .none)
    }

    private static func rule(for reason: PackFailureReason?) -> String {
        switch reason {
        case .digestMismatch: return "PACK-DIGEST-MISMATCH"
        case .sizeMismatch: return "PACK-SIZE-MISMATCH"
        case .invalidationFailed: return "PACK-INVALIDATION-FAILED"
        case .malformedProviderResult: return "PACK-PROVIDER-RESULT"
        case .providerUnavailable: return "PACK-PROVIDER-UNAVAILABLE"
        case .transferInterrupted: return "PACK-TRANSFER-INTERRUPTED"
        case .insufficientStorage: return "PACK-INSUFFICIENT-STORAGE"
        case .versionMismatch: return "PACK-VERSION-MISMATCH"
        case .atomicInstallFailed: return "PACK-ATOMIC-INSTALL"
        case .inventoryPersistenceFailed: return "PACK-INVENTORY-PERSISTENCE"
        case .providerFailed, .none: return "PACK-PROVIDER-FAILED"
        }
    }

    private var statusColor: Color {
        switch status.state {
        case .available: return .green
        case .checking, .installing, .invalidating: return .secondary
        case .notInstalled, .stale, .failed: return .orange
        }
    }

    private var statusSymbol: String {
        status.state == .available ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    private func actionTitle(for action: ForegroundAction) -> String {
        switch action {
        case .install: return "Install offline audio"
        case .update: return "Update offline audio"
        case .retry: return "Retry download"
        case .none, .invalidateThenInstall: return ""
        }
    }

    private func primaryHandler(for action: ForegroundAction) -> () -> Void {
        switch action {
        case .retry: return onRetry
        case .install, .update: return onInstall
        case .none, .invalidateThenInstall: return {}
        }
    }
}
