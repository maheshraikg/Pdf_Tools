package com.kspstadk.tulu_nighantu.keyboard

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Same cases as test/keyboard_test.dart, for the Kotlin copy. */
class TuluEngineTest {
    @Test
    fun convertsKannadaToTulu() {
        assertEquals("𑎡𑎻", TuluEngine.fromKannada("ತು"))
        assertEquals("abc ", TuluEngine.fromKannada("abc "))
    }

    @Test
    fun vowelSignsAttachAndReplace() {
        assertEquals("ಕಾ", TuluEngine.applySign("ಕ", "ಾ"))
        assertEquals("ಕಿ", TuluEngine.applySign("ಕಾ", "ಿ"))
        assertEquals("ಕು", TuluEngine.applySign("ಕ್", "ು"))
        assertEquals("ಕ್", TuluEngine.applySign("ಕ", "್"))
        assertEquals("ಕ್", TuluEngine.applySign("ಕ್", "್"))
        assertEquals("ಕಾಂ", TuluEngine.applySign("ಕಾ", "ಂ"))
        assertEquals("ಅಂ", TuluEngine.applySign("ಅ", "ಂ"))
        assertEquals("", TuluEngine.applySign("", "ಾ"))
        assertEquals("ಅ", TuluEngine.applySign("ಅ", "ಾ"))
        assertEquals("ಕ ", TuluEngine.applySign("ಕ ", "ಾ"))
    }

    @Test
    fun lastConsonantAndBackspace() {
        assertEquals("ಳ", TuluEngine.lastConsonant("ತುಳು"))
        assertNull(TuluEngine.lastConsonant("ಕ್"))
        assertNull(TuluEngine.lastConsonant("ಅ"))
        assertEquals("ಕ", TuluEngine.backspace("ಕಾ"))
        assertEquals("", TuluEngine.backspace(""))
    }

    @Test
    fun ottaksharaJoinsToThePreviousConsonant() {
        assertEquals("ಕ್ತ", TuluEngine.addOttu("ಕ", "ತ"))
        assertEquals("ಕ್ತ", TuluEngine.addOttu("ಕ್", "ತ"))
        assertEquals("ಕಾ", TuluEngine.addOttu("ಕಾ", "ತ"))
        assertEquals("", TuluEngine.addOttu("", "ತ"))
        assertEquals("ಅ", TuluEngine.addOttu("ಅ", "ತ"))
    }
}
