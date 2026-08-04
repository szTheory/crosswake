import XCTest
@testable import CrosswakeShell

@MainActor
final class NavigationShellTests: XCTestCase {
    func testSystemContainerContractIsAvailableForValidatedTopologyOnly() {
        XCTAssertTrue(NavigationShellViewController.isSystemContainerContract)
    }
}
