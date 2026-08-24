import Foundation

public enum NotificationPermissionStatus: String, Codable, Equatable {
    case unknown, granted, denied
}

public enum NotificationRegistrationFailure: String, Codable, Equatable {
    case missingDelegate, permissionDenied, hostRejected
}

public enum NotificationRegistrationState: Equatable {
    case idle
    case permissionGranted
    case observing
    case binding
    case bound(bindingRef: String)
    case permissionDenied
    case failed(reason: NotificationRegistrationFailure)
}

public enum NotificationBindingOutcome: Equatable {
    case bound(bindingRef: String)
    case rejected(reason: NotificationRegistrationFailure)
}

public enum NotificationPermissionLossOutcome: String, Codable, Equatable {
    case revoked, staleNoop, rejected, permissionDeniedNoop
}

/// Closed, authenticated host scope. These opaque references name a binding
/// authority boundary; they are not derived from nor a substitute for APNs
/// token material.
public struct NotificationRegistrationScope: Codable, Equatable {
    public let tenantRef: String
    public let subjectRef: String
    public let installationRef: String
    public let provider: String
    public let environment: String
    public let topic: String
    public let sessionRef: String
    public let sessionVersion: String
    public let channel: String

    public init(tenantRef: String, subjectRef: String, installationRef: String, provider: String, environment: String, topic: String, sessionRef: String, sessionVersion: String, channel: String) {
        self.tenantRef = tenantRef; self.subjectRef = subjectRef; self.installationRef = installationRef
        self.provider = provider; self.environment = environment; self.topic = topic
        self.sessionRef = sessionRef; self.sessionVersion = sessionVersion; self.channel = channel
    }

    enum CodingKeys: String, CodingKey { case tenantRef = "tenant_ref", subjectRef = "subject_ref", installationRef = "installation_ref", provider, environment, topic, sessionRef = "session_ref", sessionVersion = "session_version", channel }
}

public struct NotificationPermissionLossCommand: Codable, Equatable {
    public let bindingRef: String
    public let scope: NotificationRegistrationScope

    public init(bindingRef: String, scope: NotificationRegistrationScope) { self.bindingRef = bindingRef; self.scope = scope }

    enum CodingKeys: String, CodingKey { case bindingRef = "binding_ref", tenantRef = "tenant_ref", subjectRef = "subject_ref", installationRef = "installation_ref", provider, environment, topic, sessionRef = "session_ref", sessionVersion = "session_version", channel }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        bindingRef = try values.decode(String.self, forKey: .bindingRef)
        scope = NotificationRegistrationScope(tenantRef: try values.decode(String.self, forKey: .tenantRef), subjectRef: try values.decode(String.self, forKey: .subjectRef), installationRef: try values.decode(String.self, forKey: .installationRef), provider: try values.decode(String.self, forKey: .provider), environment: try values.decode(String.self, forKey: .environment), topic: try values.decode(String.self, forKey: .topic), sessionRef: try values.decode(String.self, forKey: .sessionRef), sessionVersion: try values.decode(String.self, forKey: .sessionVersion), channel: try values.decode(String.self, forKey: .channel))
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(bindingRef, forKey: .bindingRef)
        try values.encode(scope.tenantRef, forKey: .tenantRef); try values.encode(scope.subjectRef, forKey: .subjectRef); try values.encode(scope.installationRef, forKey: .installationRef)
        try values.encode(scope.provider, forKey: .provider); try values.encode(scope.environment, forKey: .environment); try values.encode(scope.topic, forKey: .topic)
        try values.encode(scope.sessionRef, forKey: .sessionRef); try values.encode(scope.sessionVersion, forKey: .sessionVersion); try values.encode(scope.channel, forKey: .channel)
    }
}

public struct NotificationPermissionLossTranscript: Codable, Equatable {
    public let version: String
    public let bindingRef: String
    public let scope: NotificationRegistrationScope
    public let command: NotificationPermissionLossCommand

    enum CodingKeys: String, CodingKey { case version, bindingRef = "binding_ref", scope, command }
}

public final class NotificationRegistrationCoordinator {
    public private(set) var state: NotificationRegistrationState = .idle
    public var diagnostics: String { String(describing: state) }

    private let permissionStatusProvider: () -> NotificationPermissionStatus
    private weak var delegate: NotificationRegistrationDelegate?
    private var retainedBinding: NotificationPermissionLossCommand?
    private var permissionLossDelivered = false

    public init(permissionStatusProvider: @escaping () -> NotificationPermissionStatus, delegate: NotificationRegistrationDelegate?) {
        self.permissionStatusProvider = permissionStatusProvider
        self.delegate = delegate
    }

    public func recordPermissionRequest(granted: Bool) {
        state = granted ? .permissionGranted : .permissionDenied
    }

    @discardableResult
    public func observeAPNSToken(_ token: Data, scope: NotificationRegistrationScope) -> NotificationBindingOutcome {
        guard permissionStatusProvider() == .granted else { state = .permissionDenied; return .rejected(reason: .permissionDenied) }
        guard let delegate else { state = .failed(reason: .missingDelegate); return .rejected(reason: .missingDelegate) }
        state = .observing
        state = .binding
        let outcome = delegate.bindObservedNotificationToken(token, scope: scope)
        switch outcome {
        case let .bound(bindingRef): state = .bound(bindingRef: bindingRef); retainedBinding = NotificationPermissionLossCommand(bindingRef: bindingRef, scope: scope); permissionLossDelivered = false
        case let .rejected(reason): state = .failed(reason: reason)
        }
        return outcome
    }

    @discardableResult
    public func recheckPermissionState() -> NotificationPermissionLossOutcome {
        guard permissionStatusProvider() == .denied else { return .rejected }
        guard let command = retainedBinding else { state = .permissionDenied; return .permissionDeniedNoop }
        guard !permissionLossDelivered else { return .permissionDeniedNoop }
        permissionLossDelivered = true
        state = .permissionDenied
        return delegate?.revokeNotificationBindingForPermissionLoss(command) ?? .rejected
    }
}
