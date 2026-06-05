import Foundation
import Combine
import SwiftUI

@MainActor
public final class CrosswakeShell: ObservableObject {
    @Published public var presentation: ShellPresentation = .booting
    public let coordinator: ActivationCoordinator
    private let config: CrosswakeShellConfig
    private var cancellables = Set<AnyCancellable>()

    public init(config: CrosswakeShellConfig, bundle: Bundle = .main) {
        self.config = config
        self.coordinator = ActivationCoordinator.bundled(bundle: bundle, config: config)

        self.coordinator.$presentation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPresentation in
                self?.presentation = newPresentation
            }
            .store(in: &cancellables)
    }

    public func createBridgeChannel(
        session: LiveViewSession,
        transferCoordinator: TransferCoordinator?,
        replySink: @escaping (BridgeReplyEnvelope) -> Void
    ) -> BridgeChannel {
        BridgeChannel(
            session: session,
            transferCoordinator: transferCoordinator,
            replySink: replySink,
            config: config
        )
    }

    public func bootstrap(intent: URL? = nil) {
        if let intent = intent {
            coordinator.openURL(intent)
        } else {
            coordinator.bootstrapIfNeeded()
        }
    }
}
