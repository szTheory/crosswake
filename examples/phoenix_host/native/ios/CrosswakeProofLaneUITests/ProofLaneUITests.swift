import XCTest

final class ProofLaneUITests: XCTestCase {
  func testReferenceHostPhysicalStudyContract() throws {
    #if targetEnvironment(simulator)
      throw XCTSkip("PI-PREFLIGHT-DESTINATION")
    #endif

    let inheritedHostEnvironment = try referenceHostLaunchEnvironment(
      from: ProcessInfo.processInfo.environment
    )
    let app = XCUIApplication()
    app.launchEnvironment["CROSSWAKE_REFERENCE_HOST_PHYSICAL_ADAPTER"] = "1"
    app.launchEnvironment["CROSSWAKE_REFERENCE_HOST_RESET_STUDY"] = "1"
    inheritedHostEnvironment.forEach { key, value in
      app.launchEnvironment[key] = value
    }
    app.launch()

    let install = app.buttons.matching(identifier: "reference-pack-install").firstMatch
    XCTAssertTrue(install.waitForExistence(timeout: 10), "PI-PACK-INSTALL-AUDIO:INSTALL-CONTROL")
    install.tap()
    let packDiagnostic = app.staticTexts.matching(identifier: "reference-pack-diagnostic").firstMatch
    XCTAssertTrue(packDiagnostic.waitForExistence(timeout: 5), "PI-PACK-INSTALL-AUDIO:DIAGNOSTIC")
    let packTerminal = XCTNSPredicateExpectation(
      predicate: NSPredicate(
        format: "label IN %@",
        [
          "PI-PACK-INSTALL-AUDIO:INSTALL-BLOCKED",
          "PI-PACK-INSTALL-AUDIO:SANDBOX-BLOCKED",
          "PI-PACK-INSTALL-AUDIO:SOURCE-BLOCKED",
          "PI-PACK-INSTALL-AUDIO:SOURCE-MANIFEST-BLOCKED",
          "PI-PACK-INSTALL-AUDIO:SOURCE-IMAGE-BLOCKED",
          "PI-PACK-INSTALL-AUDIO:SOURCE-AUDIO-BLOCKED",
          "PI-PACK-INSTALL-AUDIO:STAGING-BLOCKED",
          "PI-PACK-INSTALL-AUDIO:FILESYSTEM-BLOCKED",
          "PI-PACK-INSTALL-AUDIO:FINAL-BLOCKED",
          "PI-PACK-INSTALL-AUDIO:AUDIO-BLOCKED",
          "PI-PACK-INSTALL-AUDIO:ENTRY-BLOCKED",
          "PI-PACK-INSTALL-AUDIO:PASSED",
        ]
      ),
      object: packDiagnostic
    )
    XCTAssertEqual(
      XCTWaiter.wait(for: [packTerminal], timeout: 5),
      .completed,
      "PI-PACK-INSTALL-AUDIO:DIAGNOSTIC"
    )
    XCTAssertEqual(
      packDiagnostic.label,
      "PI-PACK-INSTALL-AUDIO:PASSED",
      packDiagnostic.label
    )
    assertFullLabel(
      app.staticTexts.matching(identifier: "reference-pack-state").firstMatch,
      equals: "Pronunciation ready offline",
      ruleID: "PI-PACK-INSTALL-AUDIO:OFFLINE-STATE"
    )
    XCTAssertTrue(
      app.images.matching(identifier: "reference-card-image").firstMatch.waitForExistence(timeout: 5),
      "PI-PACK-INSTALL-AUDIO:INSTALLED-IMAGE"
    )

    let selected = app.buttons.matching(identifier: "reference-selected-submit").firstMatch
    XCTAssertTrue(selected.waitForExistence(timeout: 5), "PI-OFFLINE-SELECTED-PERSISTENCE")
    selected.tap()
    assertFullLabel(
      app.staticTexts.matching(identifier: "reference-selected-state").firstMatch,
      equals: "Selected answer saved",
      ruleID: "PI-OFFLINE-SELECTED-PERSISTENCE"
    )

    let freeForm = app.textFields.matching(identifier: "reference-free-form-input").firstMatch
    XCTAssertTrue(freeForm.waitForExistence(timeout: 5), "PI-OFFLINE-FREE-FORM-PERSISTENCE")
    freeForm.tap()
    freeForm.typeText("local-response")
    freeForm.typeText("\n")
    let freeFormSubmit = app.buttons.matching(identifier: "reference-free-form-submit").firstMatch
    freeFormSubmit.scrollToVisible()
    XCTAssertTrue(freeFormSubmit.isHittable, "PI-OFFLINE-FREE-FORM-PERSISTENCE")
    freeFormSubmit.tap()
    assertFullLabel(
      app.staticTexts.matching(identifier: "reference-free-form-state").firstMatch,
      equals: "Free-form answer saved",
      ruleID: "PI-OFFLINE-FREE-FORM-PERSISTENCE"
    )

    app.terminate()
    app.launchEnvironment.removeValue(forKey: "CROSSWAKE_REFERENCE_HOST_RESET_STUDY")
    app.launch()

    assertFullLabel(
      app.staticTexts.matching(identifier: "reference-relaunch-state").firstMatch,
      equals: "Relaunch state retained",
      ruleID: "PI-RELAUNCH-PERSISTENCE"
    )
    assertFullLabel(
      app.staticTexts.matching(identifier: "reference-recovery-state").firstMatch,
      equals: "Recovery work retained",
      ruleID: "PI-RECOVERY-RETAINED"
    )
    XCTAssertTrue(
      app.images.matching(identifier: "reference-card-image").firstMatch.waitForExistence(timeout: 5),
      "PI-RELAUNCH-PERSISTENCE"
    )

    let report: [String: Any] = [
      "schema_version": 1,
      "device_class": "physical_iphone",
      "assertions": [
        ["id": "PI-PACK-INSTALL-AUDIO", "outcome": "passed"],
        ["id": "PI-OFFLINE-SELECTED-PERSISTENCE", "outcome": "passed"],
        ["id": "PI-OFFLINE-FREE-FORM-PERSISTENCE", "outcome": "passed"],
        ["id": "PI-RELAUNCH-PERSISTENCE", "outcome": "passed"],
        ["id": "PI-RECOVERY-RETAINED", "outcome": "passed"]
      ]
    ]
    let bytes = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
    let attachment = XCTAttachment(data: bytes, uniformTypeIdentifier: "public.json")
    attachment.name = "crosswake-physical-report.json"
    attachment.lifetime = .keepAlways
    add(attachment)
    print(String(decoding: bytes, as: UTF8.self))
  }

  func testReferenceHostLaunchEnvironmentRequiresAndForwardsValidatedInputs() throws {
    let supplied = [
      "CROSSWAKE_REFERENCE_HOST_SCOPE_REF": "fixture-scope",
      "CROSSWAKE_REFERENCE_HOST_BASE_URL": "https://localhost",
      "CROSSWAKE_REFERENCE_HOST_ESTABLISH_ACTION": "establish"
    ]

    let forwarded = try referenceHostLaunchEnvironment(from: supplied)

    XCTAssertEqual(Set(forwarded.keys), Set(ReferenceHostLaunchEnvironment.requiredKeys))
    XCTAssertEqual(forwarded, supplied)
    XCTAssertThrowsError(
      try referenceHostLaunchEnvironment(
        from: [
          "CROSSWAKE_REFERENCE_HOST_SCOPE_REF": "fixture-scope",
          "CROSSWAKE_REFERENCE_HOST_BASE_URL": "https://localhost"
        ]
      )
    )
  }

  func testMissingProviderInstallRelaunchAndOfflineAudio() {
    let app = XCUIApplication()
    app.launchEnvironment["UIPreferredContentSizeCategoryName"] = "UIContentSizeCategoryAccessibilityXXXL"
    app.launch()
    assertFullLabel(
      app.staticTexts.matching(identifier: "proof-lane-pack-status").firstMatch,
      equals: "Pronunciation provider unavailable"
    )
    print("PACK-MISSING-PROVIDER")
    app.terminate()

    app.launchEnvironment["CROSSWAKE_PROOF_LANE_REFERENCE_PACK_ADAPTER"] = "1"
    app.launchEnvironment["CROSSWAKE_PROOF_LANE_RESET_REFERENCE_PACK"] = "1"
    app.launch()
    let install = app.buttons.matching(identifier: "proof-lane-pack-install").firstMatch
    XCTAssertTrue(install.waitForExistence(timeout: 5))
    assertClosedOutcome(in: app, equals: "Blocked: packAudio")
    print("PACK-RESET-BLOCKED")
    install.tap()
    assertClosedOutcome(in: app, equals: "Passed: packAudio")
    print("PACK-INSTALL-READY")
    app.terminate()
    app.launchEnvironment.removeValue(forKey: "CROSSWAKE_PROOF_LANE_RESET_REFERENCE_PACK")
    app.launch()
    assertClosedOutcome(in: app, equals: "Passed: packAudio")
    print("PACK-RELAUNCH-READY")
    let audio = app.buttons.matching(identifier: "proof-lane-pack-audio").firstMatch
    XCTAssertTrue(audio.waitForExistence(timeout: 5))
    audio.tap()
    assertClosedOutcome(in: app, equals: "Passed: packAudio")
    print("PACK-AUDIO-OFFLINE")
  }

  func testAccessibilityReflowContract() {
    let app = XCUIApplication()
    app.launchEnvironment["UIPreferredContentSizeCategoryName"] = "UIContentSizeCategoryAccessibilityXXXL"
    app.launch()

    let window = app.windows.firstMatch
    XCTAssertTrue(window.waitForExistence(timeout: 5))
    let horizontalInsets = window.frame.insetBy(dx: 24, dy: 0)

    assertFullLabel(app.staticTexts.matching(identifier: "proof-lane-ready").firstMatch, equals: "Proof lane")
    assertFullLabel(
      app.staticTexts.matching(identifier: "proof-lane-auth-posture").firstMatch,
      equals: "Backend authority required"
    )

    XCTAssertTrue(app.staticTexts.matching(identifier: "proof-lane-pack-status").firstMatch.exists)

    let outcome = app.staticTexts.matching(identifier: "proof-lane-outcome").firstMatch
    XCTAssertTrue(outcome.waitForExistence(timeout: 5))
    XCTAssertFalse(outcome.label.contains("…"))
    assertContainedHorizontally(outcome, within: horizontalInsets)
    XCTAssertEqual(app.scrollViews.count, 0)

    let retry = app.buttons.matching(identifier: "proof-lane-reconnect").firstMatch

    if retry.exists {
      assertFullLabel(retry, equals: "Retry proof check")
      XCTAssertGreaterThanOrEqual(retry.frame.width, 44)
      XCTAssertGreaterThanOrEqual(retry.frame.height, 44)
      XCTAssertTrue(retry.isHittable)
      assertContainedHorizontally(retry, within: horizontalInsets)
    }
  }

  func testReferencePackLeavesNavigationUnavailable() {
    let app = XCUIApplication()
    app.launchEnvironment["CROSSWAKE_PROOF_LANE_REFERENCE_PACK_ADAPTER"] = "1"
    app.launch()

    let tab = app.buttons.matching(identifier: "proof-lane-navigation-tab").firstMatch
    let navigate = app.buttons.matching(identifier: "proof-lane-navigation-navigate").firstMatch
    let back = app.buttons.matching(identifier: "proof-lane-navigation-back").firstMatch

    XCTAssertFalse(tab.waitForExistence(timeout: 1))
    XCTAssertFalse(navigate.exists)
    XCTAssertFalse(back.exists)
    assertFullLabel(
      app.staticTexts.matching(identifier: "proof-lane-navigation-outcome").firstMatch,
      equals: "Navigation advisory: Unavailable"
    )
  }

  func testReferencePackNavigationMarkersRemainUnavailable() {
    let app = XCUIApplication()
    app.launchEnvironment["CROSSWAKE_PROOF_LANE_REFERENCE_PACK_ADAPTER"] = "1"
    app.launch()

    assertFullLabel(app.staticTexts.matching(identifier: "proof-lane-navigation-marker").firstMatch, equals: "Navigation shell marker unavailable")
    assertFullLabel(app.staticTexts.matching(identifier: "proof-lane-navigation-insets").firstMatch, equals: "Navigation insets unavailable")
    assertFullLabel(app.staticTexts.matching(identifier: "proof-lane-navigation-focus").firstMatch, equals: "Navigation focus unavailable")
  }

  func testStudyStatusAccessibilityContractThroughHostAdapter() {
    guard requireStudyStatusHostAdapter() else { return }

    for (state, label, message) in [
      ("saved_locally", "Saved on this iPhone.", "It will sync when you’re back online."),
      ("syncing", "Syncing saved answers…", ""),
      ("needs_attention", "Some saved answers need review.", ""),
      ("sync_paused", "Saved answers paused", "Your saved answers remain on this iPhone.")
    ] {
      let app = studyStatusApp(state: state, reduceMotion: true)
      let status = app.otherElements.matching(identifier: "crosswake-study-status").firstMatch
      XCTAssertTrue(status.waitForExistence(timeout: 5))
      XCTAssertEqual(status.value as? String, state)
      assertFullLabel(app.staticTexts.matching(identifier: "crosswake-study-status-label").firstMatch, equals: label)
      if !message.isEmpty {
        assertFullLabel(app.staticTexts.matching(identifier: "crosswake-study-status-message").firstMatch, equals: message)
      }
      XCTAssertTrue(status.isHittable)
      XCTAssertFalse(status.label.contains("…"))
      XCTAssertTrue(app.staticTexts.matching(identifier: "crosswake-study-status-icon").firstMatch.exists)
    }
  }

  func testStudyStatusRecoveryAndAccessibilityBackstops() {
    guard requireStudyStatusHostAdapter() else { return }

    let app = studyStatusApp(state: "needs_attention", reduceMotion: true)
    let window = app.windows.firstMatch
    XCTAssertTrue(window.waitForExistence(timeout: 5))
    let horizontalInsets = window.frame.insetBy(dx: 24, dy: 0)

    let status = app.otherElements.matching(identifier: "crosswake-study-status").firstMatch
    XCTAssertTrue(status.waitForExistence(timeout: 5))
    assertContainedHorizontally(status, within: horizontalInsets)
    XCTAssertTrue(app.staticTexts.matching(identifier: "crosswake-study-status-label").firstMatch.label.contains("Some saved answers need review."))
    XCTAssertFalse(app.staticTexts.matching(identifier: "crosswake-study-status-message").firstMatch.label.contains("…"))

    let review = app.buttons.matching(identifier: "crosswake-review-saved-answers").firstMatch
    XCTAssertTrue(review.waitForExistence(timeout: 5))
    assertFullLabel(review, equals: "Review saved answers")
    review.scrollToVisible()
    XCTAssertGreaterThanOrEqual(review.frame.width, 44)
    XCTAssertGreaterThanOrEqual(review.frame.height, 44)
    XCTAssertTrue(review.isHittable)
    assertContainedHorizontally(review, within: horizontalInsets)

    let noDestination = studyStatusApp(state: "needs_attention", reduceMotion: true, recoveryDestination: false)
    XCTAssertFalse(noDestination.buttons.matching(identifier: "crosswake-review-saved-answers").firstMatch.exists)
  }

  func testStudyStatusAppearanceMotionAndAnnouncementContract() {
    guard requireStudyStatusHostAdapter() else { return }

    for appearance in ["light", "dark", "system"] {
      let app = studyStatusApp(state: "syncing", reduceMotion: true, appearance: appearance)
      let status = app.otherElements.matching(identifier: "crosswake-study-status").firstMatch
      XCTAssertTrue(status.waitForExistence(timeout: 5))
      XCTAssertTrue(app.staticTexts.matching(identifier: "crosswake-study-status-label").firstMatch.label.contains("Syncing saved answers…"))
      XCTAssertTrue(app.staticTexts.matching(identifier: "crosswake-study-status-icon").firstMatch.exists)
      XCTAssertTrue(app.staticTexts.matching(identifier: "crosswake-study-status-announcement-count").firstMatch.label.contains("1"))
      XCTAssertTrue(app.staticTexts.matching(identifier: "crosswake-study-status-focus-preserved").firstMatch.label.contains("true"))
    }
  }

  private func studyStatusApp(
    state: String,
    reduceMotion: Bool,
    appearance: String = "system",
    recoveryDestination: Bool = true
  ) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchEnvironment["CROSSWAKE_PROOF_LANE_STUDY_STATUS"] = state
    app.launchEnvironment["CROSSWAKE_PROOF_LANE_REDUCE_MOTION"] = reduceMotion ? "1" : "0"
    app.launchEnvironment["CROSSWAKE_PROOF_LANE_APPEARANCE"] = appearance
    app.launchEnvironment["CROSSWAKE_PROOF_LANE_RECOVERY_DESTINATION"] = recoveryDestination ? "1" : "0"
    app.launchEnvironment["UIPreferredContentSizeCategoryName"] = "UIContentSizeCategoryAccessibilityXXXL"
    app.launch()
    return app
  }

  private func requireStudyStatusHostAdapter() -> Bool {
    guard ProcessInfo.processInfo.environment["CROSSWAKE_PROOF_LANE_STUDY_HOST_ADAPTER"] == "1" else {
      XCTFail("PL-STUDY-STATUS-HOST-ADAPTER")
      return false
    }

    return true
  }

  private func assertClosedOutcome(in app: XCUIApplication, equals expected: String) {
    XCTAssertTrue(app.staticTexts.matching(identifier: "proof-lane-ready").firstMatch.waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts.matching(identifier: "proof-lane-auth-posture").firstMatch.exists)

    let outcome = app.staticTexts.matching(identifier: "proof-lane-outcome").firstMatch
    XCTAssertTrue(outcome.waitForExistence(timeout: 5))
    XCTAssertEqual(outcome.label, expected)
    XCTAssertFalse(outcome.label.contains("…"))
  }

  private func assertFullLabel(
    _ element: XCUIElement,
    equals label: String,
    ruleID: String = "PI-REPORT-DEVICE",
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertTrue(element.waitForExistence(timeout: 5), ruleID, file: file, line: line)

    let labelExpectation = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", label),
      object: element
    )
    XCTAssertEqual(
      XCTWaiter.wait(for: [labelExpectation], timeout: 5),
      .completed,
      ruleID,
      file: file,
      line: line
    )
    XCTAssertEqual(element.label, label, ruleID, file: file, line: line)
    XCTAssertFalse(element.label.contains("…"), ruleID, file: file, line: line)
  }

  private func assertContainedHorizontally(_ element: XCUIElement, within frame: CGRect) {
    XCTAssertGreaterThanOrEqual(element.frame.minX, frame.minX)
    XCTAssertLessThanOrEqual(element.frame.maxX, frame.maxX)
  }
}

private enum ReferenceHostLaunchEnvironment {
  static let requiredKeys = [
    "CROSSWAKE_REFERENCE_HOST_SCOPE_REF",
    "CROSSWAKE_REFERENCE_HOST_BASE_URL",
    "CROSSWAKE_REFERENCE_HOST_ESTABLISH_ACTION"
  ]

  static func validated(from environment: [String: String]) throws -> [String: String] {
    guard let scope = environment[requiredKeys[0]], !scope.isEmpty,
          let baseURL = environment[requiredKeys[1]],
          let url = URL(string: baseURL),
          ["http", "https"].contains(url.scheme),
          url.host != nil,
          environment[requiredKeys[2]] == "establish"
    else {
      throw ValidationError.invalid
    }

    return Dictionary(uniqueKeysWithValues: requiredKeys.compactMap { key in
      environment[key].map { (key, $0) }
    })
  }

  enum ValidationError: Error {
    case invalid
  }
}

private func referenceHostLaunchEnvironment(
  from environment: [String: String]
) throws -> [String: String] {
  try ReferenceHostLaunchEnvironment.validated(from: environment)
}

private extension XCUIElement {
  func scrollToVisible(attempts: Int = 5) {
    let app = XCUIApplication()
    for _ in 0..<attempts where !isHittable {
      if frame.minY < app.frame.minY {
        app.swipeDown()
      } else {
        app.swipeUp()
      }
    }
  }
}
