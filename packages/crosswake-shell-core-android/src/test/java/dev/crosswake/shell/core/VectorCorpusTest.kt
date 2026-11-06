package dev.crosswake.shell.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

class VectorCorpusTest {

    @Test
    fun `corpus bytes match the generated vector set hash`() {
        val bytes = VectorCorpus.loadVerifiedBytes()
        assertTrue("CW-VECTOR-EMPTY corpus has no bytes", bytes.isNotEmpty())
        assertTrue(
            "CW-VECTOR-CONSTANT not 64 lowercase hex: ${VectorSet.SHA256}",
            Regex("^[0-9a-f]{64}$").matches(VectorSet.SHA256),
        )
        assertEquals(VectorSet.SHA256, VectorCorpus.sha256Hex(bytes))
    }

    @Test
    fun `one flipped byte fails with CW-VECTOR-HASH`() {
        val bytes = VectorCorpus.loadVerifiedBytes()
        val flipped = bytes.copyOf()
        flipped[flipped.size / 2] = (flipped[flipped.size / 2].toInt() xor 1).toByte()
        try {
            VectorCorpus.verify(flipped, VectorSet.SHA256)
            fail("CW-VECTOR-HASH-NOT-RAISED a flipped byte passed verification")
        } catch (e: AssertionError) {
            assertTrue(
                "expected a CW-VECTOR-HASH failure, got: ${e.message}",
                e.message?.startsWith("CW-VECTOR-HASH") == true,
            )
        }
    }
}
