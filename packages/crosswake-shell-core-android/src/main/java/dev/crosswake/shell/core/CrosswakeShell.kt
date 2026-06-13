package dev.crosswake.shell.core

import android.content.Context
import android.content.Intent
import dev.crosswake.shell.core.transfer.TransferCoordinator
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow

class CrosswakeShell(
    context: Context,
    val config: CrosswakeShellConfig
) {
    private val coordinator = ActivationCoordinator.bundled(context, config)

    val state: StateFlow<ShellPresentation>
        get() = coordinator.stateFlow

    private val _connectionState = MutableStateFlow(ConnectionState.Connecting)
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()

    private val _serverEvents = MutableSharedFlow<ServerEvent>(extraBufferCapacity = 64)
    val serverEvents: SharedFlow<ServerEvent> = _serverEvents.asSharedFlow()

    fun bootstrap(intent: Intent? = null): ShellPresentation {
        return coordinator.bootstrapIfNeeded(intent)
    }

    fun handleIntent(intent: Intent?): ShellPresentation {
        return coordinator.handleIntent(intent)
    }
    
    fun createBridgeChannel(
        session: LiveViewSession,
        transferCoordinator: TransferCoordinator?
    ): BridgeChannel {
        return BridgeChannel(session, transferCoordinator, config, _connectionState, _serverEvents)
    }
}
