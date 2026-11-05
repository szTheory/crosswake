package dev.crosswake.shell.core

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Pure JVM boundary tests for [SemVer.compatible]; expectations measured, not taken from KDoc. */
class SemVerBoundaryTest {

    @Test
    fun `null or blank input is incompatible`() {
        assertFalse(SemVer.compatible(null, "1.0.0"))
        assertFalse(SemVer.compatible("", "1.0.0"))
        assertFalse(SemVer.compatible("1.0.0", " "))
    }

    @Test
    fun `equal versions are compatible`() {
        assertTrue(SemVer.compatible("1.2.3", "1.2.3"))
        assertTrue(SemVer.compatible("1", "1.0"))
    }

    @Test
    fun `lower patch does not satisfy a higher demand`() {
        assertFalse(SemVer.compatible("1.2.2", "1.2.3"))
        assertTrue(SemVer.compatible("1.2.4", "1.2.3"))
    }

    @Test
    fun `unparseable versions fall back to raw equality both ways`() {
        assertTrue(SemVer.compatible("abc", "abc"))
        assertFalse(SemVer.compatible("abc", "1.0.0"))
        assertFalse(SemVer.compatible("1.0.0", "abc"))
    }

    @Test
    fun `negative plus signed and overflowing components fail closed`() {
        assertFalse(SemVer.compatible("0.0.0", "-1.0.0"))
        assertFalse(SemVer.compatible("+1.0.0", "1.0.0"))
        assertFalse(SemVer.compatible("99999999999.0.0", "1.0.0"))
    }
}
