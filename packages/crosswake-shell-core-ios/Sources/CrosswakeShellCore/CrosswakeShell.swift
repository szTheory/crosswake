import Foundation
import Combine
import SwiftUI

@MainActor
public final class CrosswakeShell: ObservableObject {
    @Published public var presentation: ShellPresentation = .booting
    @Published public var connectionState: ConnectionState = .disconnected
    public let serverEvents = PassthroughSubject<ServerEvent, Never>()
    
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
            config: config,
            connectionStateSink: { [weak self] state in
                Task { @MainActor in
                    self?.connectionState = state
                }
            },
            eventSink: { [weak self] event in
                Task { @MainActor in
                    self?.serverEvents.send(event)
                }
            }
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
