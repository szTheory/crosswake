import XCTest
@testable import CrosswakeShell

@MainActor
final class NavigationShellTests: XCTestCase {
    func testSystemContainerContractIsAvailableForValidatedTopologyOnly() {
        XCTAssertTrue(NavigationShellViewController.isSystemContainerContract)
    }

    func testDocumentStartShellContractUsesOnlyFixedMarkerAndFiveDefaults() {
        let script = LiveViewContainerViewController.documentStartShellScript
        XCTAssertTrue(script.contains("cwNativeShell = \"ios\""))
        for key in ["--cw-safe-area-top", "--cw-safe-area-right", "--cw-safe-area-bottom", "--cw-safe-area-left", "--cw-keyboard-inset-bottom"] { XCTAssertTrue(script.contains(key)) }
    }
}
