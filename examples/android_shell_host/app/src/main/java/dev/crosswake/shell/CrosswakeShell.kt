package dev.crosswake.shell

import android.content.Context
import android.content.Intent
import dev.crosswake.shell.transfer.TransferCoordinator
import kotlinx.coroutines.flow.StateFlow

class CrosswakeShell(
    context: Context,
    val config: CrosswakeShellConfig
) {
    private val coordinator = ActivationCoordinator.bundled(context, config)

    val state: StateFlow<ShellPresentation>
        get() = coordinator.stateFlow

    fun bootstrap(intent: Intent? = null): ShellPresentation {
        return coordinator.bootstrapIfNeeded(intent)
    }

    fun handleIntent(intent: Intent?): ShellPresentation {
        return coordinator.handleIntent(intent)
    }
    
    fun retry(): ShellPresentation {
        return coordinator.retry()
    }
    
    fun resolveNavigation(url: String): NavigationDecision {
        return coordinator.resolveNavigation(url)
    }
    
    val currentTransferCoordinator: TransferCoordinator?
        get() = coordinator.currentTransferCoordinator

    fun createBridgeChannel(
        session: LiveViewSession,
        transferCoordinator: TransferCoordinator?
    ): BridgeChannel {
        return BridgeChannel(session, transferCoordinator, config)
    }
}
