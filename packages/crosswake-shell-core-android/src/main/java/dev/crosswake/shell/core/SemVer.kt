package dev.crosswake.shell.core

/**
 * Minimal semver floor-comparison helper, ported from Elixir's
 * `compatible_version?/2` + `normalize_version/1` in
 * `lib/crosswake/compatibility/compatibility.ex`.
 *
 * Provides the single public entry point [SemVer.compatible] which returns
 * `true` when `provides >= demands` (i.e. the shell satisfies the requested
 * floor), mirroring Elixir's `Version.compare != :lt` semantics.
 *
 * Zero third-party dependencies — do NOT add a Kotlin semver library (D-04).
 */
internal object SemVer {

    /**
     * Returns `true` when [provides] satisfies the minimum floor of [demands]
     * (i.e. `provides >= demands`).
     *
     * - Null or blank input → `false` (fail-closed, deny).
     * - Unparseable version string → falls back to raw `==` comparison (Elixir
     *   fail-closed fallback: deny on mismatch, never allow or throw).
     */
    fun compatible(provides: String?, demands: String?): Boolean {
        if (provides.isNullOrBlank() || demands.isNullOrBlank()) return false
        val pComponents = parse(normalize(provides))
        val dComponents = parse(normalize(demands))
        return if (pComponents != null && dComponents != null) {
            compare(pComponents, dComponents) >= 0
        } else {
            // Fail-closed fallback: raw equality (same as Elixir's `available == required`)
            provides == demands
        }
    }

    // --- Private helpers ---

    /**
     * Zero-pads a version string to MAJOR.MINOR.PATCH.
     * "1" → "1.0.0", "1.1" → "1.1.0", "1.0.0" → unchanged.
     */
    private fun normalize(value: String): String {
        val parts = value.split(".")
        return when (parts.size) {
            1 -> "${parts[0]}.0.0"
            2 -> "${parts[0]}.${parts[1]}.0"
            else -> value
        }
    }

    /**
     * Parses a "MAJOR.MINOR.PATCH" string into a list of three Ints.
     * Returns `null` if any component is non-numeric or the count != 3.
     */
    private fun parse(version: String): List<Int>? {
        val parts = version.split(".")
        if (parts.size != 3) return null
        val ints = parts.mapNotNull { it.toIntOrNull() }
        if (ints.size != 3) return null
        return ints
    }

    /**
     * Compares two parsed [major, minor, patch] lists.
     * Returns negative/zero/positive, matching the Comparable contract.
     */
    private fun compare(a: List<Int>, b: List<Int>): Int {
        for (i in 0..2) {
            val diff = a[i] - b[i]
            if (diff != 0) return diff
        }
        return 0
    }
}
