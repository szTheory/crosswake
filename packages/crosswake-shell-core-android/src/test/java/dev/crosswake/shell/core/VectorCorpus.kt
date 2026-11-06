package dev.crosswake.shell.core

import java.security.MessageDigest

/**
 * The only loader of `bridge_contract_vectors.json` in the JVM tests. It checks the corpus
 * bytes against the generated [VectorSet.SHA256] before any parser sees them, so Kotlin runs
 * exactly the bytes `mix crosswake.contract.gen` wrote (D-04, D-05).
 */
internal object VectorCorpus {

    fun loadVerifiedBytes(): ByteArray {
        val stream = VectorCorpus::class.java.getResourceAsStream("/bridge_contract_vectors.json")
            ?: throw AssertionError("CW-VECTOR-MISSING bridge_contract_vectors.json")
        val bytes = stream.use { it.readBytes() }
        return verify(bytes, VectorSet.SHA256)
    }

    fun verify(bytes: ByteArray, expected: String): ByteArray {
        val actual = sha256Hex(bytes)
        if (actual != expected) {
            throw AssertionError("CW-VECTOR-HASH expected $expected got $actual")
        }
        return bytes
    }

    fun sha256Hex(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
}
