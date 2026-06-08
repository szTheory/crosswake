package dev.crosswake.shell.core

data class ServerEvent(
    val name: String,
    val payload: Map<String, String> = emptyMap()
)
