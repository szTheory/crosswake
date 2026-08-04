import XCTest
import SwiftUI
@testable import CrosswakeShell
@testable import CrosswakeShellCore

final class RequiredPackViewTests: XCTestCase {
    func testClosedPresentationMapsEveryLifecycleToOneForegroundAction() {
        XCTAssertEqual(presentation(.checking).primaryAction, .none)
        XCTAssertEqual(presentation(.installing).primaryAction, .none)
        XCTAssertEqual(presentation(.invalidating).primaryAction, .none)
        XCTAssertEqual(presentation(.notInstalled).primaryAction, .install)
        XCTAssertEqual(presentation(.stale).primaryAction, .update)
        XCTAssertEqual(presentation(.failed, reason: .transferInterrupted).primaryAction, .retry)
        XCTAssertEqual(presentation(.available).primaryAction, .none)
    }

    func testCorruptAndRevokedFailuresRequireInvalidationBeforeInstall() {
        for reason in [PackFailureReason.digestMismatch, .sizeMismatch, .invalidationFailed, .malformedProviderResult] {
            let model = presentation(.failed, reason: reason)
            XCTAssertEqual(model.primaryAction, .none)
            XCTAssertEqual(model.secondaryAction, .invalidateThenInstall)
            XCTAssertFalse(model.primaryAction.isEnabled)
        }
    }

    func testPresentationUsesStableAccessibleSafeSemantics() {
        let model = presentation(.failed, reason: .digestMismatch)

        XCTAssertEqual(model.statusAccessibilityIdentifier, "required-pack-status")
        XCTAssertEqual(model.primaryActionAccessibilityIdentifier, "required-pack-primary-action")
        XCTAssertEqual(model.invalidateActionAccessibilityIdentifier, "required-pack-invalidate-action")
        XCTAssertEqual(model.ownerAccessibilityIdentifier, "required-pack-owner")
        XCTAssertEqual(model.owner, "host pack provider")
        XCTAssertEqual(model.rule, "PACK-DIGEST-MISMATCH")
        XCTAssertEqual(model.learnerMessage, "Offline audio could not be verified. Try the download again while connected.")
        XCTAssertFalse(model.developerRemediation.localizedCaseInsensitiveContains("http"))
        XCTAssertFalse(model.developerRemediation.localizedCaseInsensitiveContains("digest"))
    }

    func testSourceKeepsProviderConstructionInTheExampleCompositionRoot() throws {
        let testDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let sourceURL = testDirectory
            .deletingLastPathComponent()
            .appendingPathComponent("CrosswakeShell/CrosswakeShellApp.swift")
        let source = try String(contentsOf: sourceURL)
        XCTAssertTrue(source.contains("PronunciationPackProvider"))
        XCTAssertTrue(source.contains("packProvider: pronunciationPackProvider"))
    }

    func testRecoverySurfacePinsApprovedSpacing() throws {
        let testDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let sourceURL = testDirectory
            .deletingLastPathComponent()
            .appendingPathComponent("CrosswakeShell/RequiredPackView.swift")
        let source = try String(contentsOf: sourceURL)

        XCTAssertTrue(source.contains("VStack(alignment: .leading, spacing: 24)"))
        XCTAssertTrue(source.contains("VStack(alignment: .leading, spacing: 8) {\n                    Text(\"Owner:"))
    }

    func testAccessibilityXXXLRecoveryCopyWrapsAndControlsRemainReachable() throws {
        let hosted = hostedView(status: .failed, reason: .digestMismatch)
        let statusView = try XCTUnwrap(requiredElement("required-pack-status", in: hosted.rootView))
        let action = try XCTUnwrap(requiredElement("required-pack-invalidate-action", in: hosted.rootView))

        XCTAssertTrue(hosted.scrollView.bounds.intersects(action.convert(action.bounds, to: hosted.scrollView)))
        XCTAssertGreaterThanOrEqual(action.bounds.width, 44)
        XCTAssertGreaterThanOrEqual(action.bounds.height, 44)
        XCTAssertGreaterThan(statusView.bounds.height, 44)
        XCTAssertEqual(RequiredPackView.presentation(for: requiredStatus(.failed, reason: .digestMismatch)).learnerMessage, "Offline audio could not be verified. Try the download again while connected.")
    }

    func testAccessibilityXXXLLifecycleAnnouncementPreservesFocus() {
        let effect = RequiredPackView.lifecycleAccessibilityEffect(for: requiredStatus(.installing))

        XCTAssertEqual(effect.announcement, "Installing offline audio. Installing offline audio. Keep this screen open.")
        XCTAssertTrue(effect.preserveFocus)
    }

    func testAccessibilityXXXLActionLabelsWrapWithoutTruncation() throws {
        let actions: [(PackState, PackFailureReason?, String, String)] = [
            (.notInstalled, nil, "Install offline audio", "required-pack-primary-action"),
            (.stale, nil, "Update offline audio", "required-pack-primary-action"),
            (.failed, PackFailureReason.transferInterrupted, "Retry download", "required-pack-primary-action"),
            (.failed, PackFailureReason.digestMismatch, "Invalidate downloaded audio", "required-pack-invalidate-action")
        ]
        for (state, reason, expectedLabel, identifier) in actions {
            let hosted = hostedView(status: state, reason: reason)
            let action = try XCTUnwrap(requiredElement(identifier, in: hosted.rootView))

            XCTAssertTrue(hosted.scrollView.bounds.intersects(action.convert(action.bounds, to: hosted.scrollView)))
            XCTAssertGreaterThanOrEqual(action.bounds.width, 44)
            XCTAssertGreaterThanOrEqual(action.bounds.height, 44)
            XCTAssertTrue(hosted.rootView.accessibilityLabel?.contains(expectedLabel) ?? false)
        }
    }

    func testAccessibilityXXXLDeveloperContextWrapsWithoutSensitiveData() throws {
        let hosted = hostedView(status: .failed, reason: .transferInterrupted)
        let owner = try XCTUnwrap(requiredElement("required-pack-owner", in: hosted.rootView))
        let label = hosted.rootView.accessibilityLabel ?? ""

        XCTAssertGreaterThan(owner.bounds.height, 44)
        for safeValue in ["Owner: host pack provider", "Rule: PACK-TRANSFER-INTERRUPTED", "Route:", "reference runtime"] {
            XCTAssertTrue(label.contains(safeValue))
        }
        for excluded in ["http", "/private/", "sha256", "credential", "token", "account", "device", "transcript", "media"] {
            XCTAssertFalse(label.localizedCaseInsensitiveContains(excluded))
        }
    }

    private func hostedView(status state: PackState, reason: PackFailureReason? = nil) -> HostedView {
        let view = RequiredPackView(
            routeID: "route-0123456789abcdef",
            runtimeLabel: "reference runtime",
            status: requiredStatus(state, reason: reason),
            onInstall: {},
            onRetry: {},
            onInvalidate: {}
        )
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        guard let scrollView = descendant(of: controller.view, matching: { $0 is UIScrollView }) as? UIScrollView else {
            fatalError("RequiredPackView must preserve ScrollView overflow ownership")
        }
        scrollView.setContentOffset(CGPoint(x: 0, y: max(0, scrollView.contentSize.height - scrollView.bounds.height)), animated: false)
        controller.view.layoutIfNeeded()
        return HostedView(window: window, rootView: controller.view, scrollView: scrollView)
    }

    private func requiredElement(_ identifier: String, in root: UIView) -> UIView? {
        descendant(of: root, matching: { $0.accessibilityIdentifier == identifier })
    }

    private func descendant(of view: UIView, matching predicate: (UIView) -> Bool) -> UIView? {
        if predicate(view) { return view }
        for child in view.subviews {
            if let match = descendant(of: child, matching: predicate) { return match }
        }
        return nil
    }

    private struct HostedView {
        let window: UIWindow
        let rootView: UIView
        let scrollView: UIScrollView
    }

    private func presentation(_ state: PackState, reason: PackFailureReason? = nil) -> RequiredPackView.Presentation {
        RequiredPackView.presentation(for: requiredStatus(state, reason: reason))
    }

    private func requiredStatus(_ state: PackState, reason: PackFailureReason? = nil) -> RequiredPackStatus {
        RequiredPackStatus(
            id: "pack",
            packID: "pack",
            requiredVersion: "1",
            state: state,
            installedVersion: nil,
            bytes: nil,
            verifiedAt: nil,
            integrityStatus: nil,
            installStage: nil,
            failureReason: reason,
            lastKnownVersion: nil
        )
    }
}
