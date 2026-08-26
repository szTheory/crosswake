import SwiftUI
import UIKit

@main
struct CrosswakeProofLaneApp: App {
  private let adapter: ProofLaneHostAdapter?
  private let navigationAdapter: ProofLaneNavigationHostAdapter?
  private let physicalReferenceHost: Bool

  init() {
    let environment = ProcessInfo.processInfo.environment
    physicalReferenceHost = environment["CROSSWAKE_REFERENCE_HOST_PHYSICAL_ADAPTER"] == "1"
    UIApplication.shared.isIdleTimerDisabled = physicalReferenceHost

    if physicalReferenceHost,
       environment["CROSSWAKE_REFERENCE_HOST_RESET_STUDY"] == "1" {
      ReferenceHostPhysicalIphoneAdapter.resetReferenceStudyPersistenceForTests()
    }

    if environment["CROSSWAKE_PROOF_LANE_REFERENCE_PACK_ADAPTER"] == "1",
       environment["CROSSWAKE_PROOF_LANE_RESET_REFERENCE_PACK"] == "1" {
      ProofLaneReferencePackAdapter.resetReferencePersistenceForTests()
    }

    adapter = ProofLaneHostAdapterFactory.make()
    navigationAdapter = ProofLaneNavigationHostAdapterFactory.make()
  }

  var body: some Scene {
    WindowGroup {
      if physicalReferenceHost {
        ReferencePhysicalStudyView()
      } else {
        ProofLaneView(adapter: adapter, navigationAdapter: navigationAdapter)
      }
    }
  }
}

private struct ReferencePhysicalStudyView: View {
  private let adapter = ReferenceHostPhysicalIphoneAdapter()
  @State private var packReady = false
  @State private var packDiagnostic = "PI-PACK-INSTALL-AUDIO:NOT-RUN"
  @State private var selectedReady = false
  @State private var freeFormReady = false
  @State private var recoveryReady = false
  @State private var freeFormDraft = ""

  var body: some View {
    VStack(spacing: 16) {
      Text("Offline study")
        .accessibilityIdentifier("reference-study-ready")

      Text(packReady ? "Pronunciation ready offline" : "Pronunciation unavailable")
        .accessibilityIdentifier("reference-pack-state")

      Text(packDiagnostic)
        .accessibilityIdentifier("reference-pack-diagnostic")

      if let location = adapter.installedCardImageURL(),
         let image = UIImage(contentsOfFile: location.path) {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(width: 96, height: 96)
          .accessibilityLabel("Installed study card image")
          .accessibilityIdentifier("reference-card-image")
      }

      Button("Install pronunciation pack") {
        Task {
          let installed = await adapter.installAndVerifyPack()
          guard installed == .passed else {
            packDiagnostic = adapter.packInstallDiagnostic()
            return
          }

          let audio = await adapter.playInstalledAudioOffline()
          guard audio == .passed else {
            packDiagnostic = "PI-PACK-INSTALL-AUDIO:AUDIO-BLOCKED"
            return
          }

          let entered = await adapter.enterAuthorizedStudy()
          guard entered == .passed else {
            packDiagnostic = "PI-PACK-INSTALL-AUDIO:ENTRY-BLOCKED"
            return
          }

          packReady = true
          packDiagnostic = "PI-PACK-INSTALL-AUDIO:PASSED"
        }
      }
      .frame(minWidth: 44, minHeight: 44)
      .accessibilityIdentifier("reference-pack-install")

      Button("Save selected answer") {
        Task {
          selectedReady = await adapter.submitSelectedAnswerOffline() == .passed
        }
      }
      .disabled(!packReady)
      .frame(minWidth: 44, minHeight: 44)
      .accessibilityIdentifier("reference-selected-submit")

      Text(selectedReady ? "Selected answer saved" : "Selected answer pending")
        .accessibilityIdentifier("reference-selected-state")

      TextField("Free-form answer", text: $freeFormDraft)
        .textFieldStyle(.roundedBorder)
        .accessibilityIdentifier("reference-free-form-input")

      Button("Save free-form answer") {
        guard !freeFormDraft.isEmpty else { return }
        Task {
          freeFormReady = await adapter.submitFreeFormAnswerOffline(freeFormDraft) == .passed
          if freeFormReady { freeFormDraft = "" }
        }
      }
      .disabled(!selectedReady)
      .frame(minWidth: 44, minHeight: 44)
      .accessibilityIdentifier("reference-free-form-submit")

      Text(freeFormReady ? "Free-form answer saved" : "Free-form answer pending")
        .accessibilityIdentifier("reference-free-form-state")

      Text(selectedReady && freeFormReady ? "Relaunch state retained" : "Relaunch state pending")
        .accessibilityIdentifier("reference-relaunch-state")

      Text(recoveryReady ? "Recovery work retained" : "Recovery work pending")
        .accessibilityIdentifier("reference-recovery-state")
    }
    .padding(24)
    .onAppear {
      let state = adapter.persistedStudyState()
      selectedReady = state.selected
      freeFormReady = state.freeForm
      packReady = state.entered
      if packReady {
        packDiagnostic = "PI-PACK-INSTALL-AUDIO:PASSED"
      }
      if selectedReady && freeFormReady {
        Task {
          recoveryReady = await adapter.observeRecoveryAndRetainedWork() == .passed
        }
      }
    }
  }
}

private struct ProofLaneView: View {
  let adapter: ProofLaneHostAdapter?
  let navigationAdapter: ProofLaneNavigationHostAdapter?
  @State private var snapshot = ProofLaneSnapshot(
    outcome: .unavailable, prerequisite: .packAudio, shellBooted: false
  )

  var body: some View {
    VStack(spacing: 16) {
      Text("Proof lane")
        .accessibilityIdentifier("proof-lane-ready")
      Text("Backend authority required")
        .accessibilityIdentifier("proof-lane-auth-posture")
      Text(adapter == nil ? "Pronunciation provider unavailable" : "Pronunciation pack status")
        .accessibilityIdentifier("proof-lane-pack-status")
      Text("\(snapshot.outcome.rawValue.capitalized): \(snapshot.prerequisite.rawValue)")
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("proof-lane-outcome")
      if let adapter {
        Button("Install pronunciation pack") {
          Task { snapshot = await adapter.installPronunciationPackForeground() }
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityIdentifier("proof-lane-pack-install")
        Button("Play installed pronunciation audio") {
          Task { snapshot = await adapter.exerciseInstalledPronunciationAudioOffline() }
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityIdentifier("proof-lane-pack-audio")
      }
      if let retry = adapter?.retry {
        Button("Retry proof check") {
          retry()
          refresh()
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityIdentifier("proof-lane-reconnect")
      }
      NavigationProofView(adapter: navigationAdapter)
    }
    .padding(24)
    .onAppear(perform: refresh)
  }

  private func refresh() {
    guard let adapter else { return }
    snapshot = adapter.observe()
  }
}

private struct NavigationProofView: View {
  let adapter: ProofLaneNavigationHostAdapter?
  @State private var outcome: ProofLaneOutcome = .unavailable

  var body: some View {
    VStack(spacing: 12) {
      Text(adapter == nil ? "Navigation shell marker unavailable" : "Navigation shell marker observed")
        .accessibilityIdentifier("proof-lane-navigation-marker")
      Text(adapter == nil ? "Navigation insets unavailable" : "Navigation insets observed")
        .accessibilityIdentifier("proof-lane-navigation-insets")
      Text(adapter == nil ? "Navigation focus unavailable" : "Navigation focus observed")
        .accessibilityIdentifier("proof-lane-navigation-focus")
      Text("Navigation advisory: \(outcome.rawValue.capitalized)")
        .accessibilityIdentifier("proof-lane-navigation-outcome")
      if let adapter {
        Button("Select proof tab") { outcome = adapter.selectRoot() }
          .frame(minWidth: 44, minHeight: 44)
          .accessibilityIdentifier("proof-lane-navigation-tab")
        Button("Navigate once") { outcome = adapter.applyPushNavigate() }
          .frame(minWidth: 44, minHeight: 44)
          .accessibilityIdentifier("proof-lane-navigation-navigate")
        Button("Observe back") { outcome = adapter.observeBackOrEdgeSwipe() }
          .frame(minWidth: 44, minHeight: 44)
          .accessibilityIdentifier("proof-lane-navigation-back")
      }
    }
  }
}
