package dev.crosswake.shell.core

sealed class FilesPickResult {
    data class Immediate(val payload: Map<String, String>) : FilesPickResult()

    data class Denied(
        val reason: String,
        val message: String,
        val hint: String
    ) : FilesPickResult()

    class Deferred(
        private val starter: (
            onSuccess: (Map<String, String>) -> Unit,
            onDenied: (Denied) -> Unit
        ) -> Unit
    ) : FilesPickResult() {
        fun dispatch(
            onSuccess: (Map<String, String>) -> Unit,
            onDenied: (Denied) -> Unit
        ) {
            starter(onSuccess, onDenied)
        }
    }
}
