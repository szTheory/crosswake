import XCTest
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

    private func presentation(_ state: PackState, reason: PackFailureReason? = nil) -> RequiredPackView.Presentation {
        RequiredPackView.presentation(for: RequiredPackStatus(
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
        ))
    }
}
