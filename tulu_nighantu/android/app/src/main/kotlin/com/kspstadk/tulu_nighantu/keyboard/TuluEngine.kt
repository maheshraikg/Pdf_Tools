package com.kspstadk.tulu_nighantu.keyboard

/**
 * Kannada → Tulu-Tigalari conversion and the keyboard's editing rules.
 *
 * Kotlin copy of lib/lipi/tulu_lipi.dart and lib/lipi/composer.dart for the
 * system keyboard. test/keyboard_engine_sync_test.dart checks that the map
 * below stays identical to the Dart one.
 */
object TuluEngine {
    /** Kannada code point → Tulu-Tigalari code point. */
    val MAP: Map<Int, Int> = mapOf(
        0x0C85 to 0x11380, 0x0C86 to 0x11381, 0x0C87 to 0x11382, 0x0C88 to 0x11383,
        0x0C89 to 0x11384, 0x0C8A to 0x11385, 0x0C8B to 0x11386, 0x0CE0 to 0x11387,
        0x0C8C to 0x11388, 0x0CE1 to 0x11389, 0x0C8E to 0x1138B, 0x0C8F to 0x1138B,
        0x0C90 to 0x1138E, 0x0C92 to 0x11390, 0x0C93 to 0x11390, 0x0C94 to 0x11391,
        0x0C95 to 0x11392, 0x0C96 to 0x11393, 0x0C97 to 0x11394, 0x0C98 to 0x11395,
        0x0C99 to 0x11396, 0x0C9A to 0x11397, 0x0C9B to 0x11398, 0x0C9C to 0x11399,
        0x0C9D to 0x1139A, 0x0C9E to 0x1139B, 0x0C9F to 0x1139C, 0x0CA0 to 0x1139D,
        0x0CA1 to 0x1139E, 0x0CA2 to 0x1139F, 0x0CA3 to 0x113A0, 0x0CA4 to 0x113A1,
        0x0CA5 to 0x113A2, 0x0CA6 to 0x113A3, 0x0CA7 to 0x113A4, 0x0CA8 to 0x113A5,
        0x0CAA to 0x113A6, 0x0CAB to 0x113A7, 0x0CAC to 0x113A8, 0x0CAD to 0x113A9,
        0x0CAE to 0x113AA, 0x0CAF to 0x113AB, 0x0CB0 to 0x113AC, 0x0CB2 to 0x113AD,
        0x0CB5 to 0x113AE, 0x0CB6 to 0x113AF, 0x0CB7 to 0x113B0, 0x0CB8 to 0x113B1,
        0x0CB9 to 0x113B2, 0x0CB3 to 0x113B3, 0x0CB1 to 0x113B4, 0x0CDE to 0x113B5,
        0x0CBE to 0x113B8, 0x0CBF to 0x113B9, 0x0CC0 to 0x113BA, 0x0CC1 to 0x113BB,
        0x0CC2 to 0x113BC, 0x0CC3 to 0x113BD, 0x0CC4 to 0x113BE, 0x0CE2 to 0x113BF,
        0x0CE3 to 0x113C0, 0x0CC6 to 0x113C2, 0x0CC7 to 0x113C2, 0x0CC8 to 0x113C5,
        0x0CCA to 0x113C7, 0x0CCB to 0x113C7, 0x0CCC to 0x113C8, 0x0C81 to 0x113CA,
        0x0C82 to 0x113CC, 0x0C83 to 0x113CD, 0x0CCD to 0x113CE, 0x0CBD to 0x113B7,
    )

    private val COMPOSITIONS = listOf(
        "\u0CC6\u0CC2\u0CD5" to "\u0CCB",
        "\u0CCA\u0CD5" to "\u0CCB",
        "\u0CC6\u0CC2" to "\u0CCA",
        "\u0CC6\u0CD5" to "\u0CC7",
        "\u0CC6\u0CD6" to "\u0CC8",
        "\u0CBF\u0CD5" to "\u0CC0",
    )

    private val DROPPED = setOf(0x200C, 0x200D, 0x0CD5, 0x0CD6)

    /** Vowel signs, yogavahas and the virama, in barakhadi order. */
    val VOWEL_SIGNS = listOf(
        "\u0CBE", "\u0CBF", "\u0CC0", "\u0CC1", "\u0CC2", "\u0CC3", "\u0CC6",
        "\u0CC8", "\u0CCA", "\u0CCC", "\u0C82", "\u0C83", "\u0CCD",
    )

    fun normalize(input: String): String {
        var s = input
        for ((from, to) in COMPOSITIONS) s = s.replace(from, to)
        val sb = StringBuilder()
        s.codePoints().forEach { if (it !in DROPPED) sb.appendCodePoint(it) }
        return sb.toString()
    }

    /** Converts Kannada text to Tulu-Tigalari; other characters pass through. */
    fun fromKannada(input: String): String {
        val sb = StringBuilder()
        normalize(input).codePoints().forEach { sb.appendCodePoint(MAP[it] ?: it) }
        return sb.toString()
    }

    private fun isConsonant(c: Int) = c in 0x0C95..0x0CB9 || c == 0x0CDE
    private fun isDependent(c: Int) = c in 0x0CBE..0x0CCD || c == 0x0C82 || c == 0x0C83
    private fun isVowelSign(c: Int) = c in 0x0CBE..0x0CCC

    private fun cps(s: String) = s.codePoints().toArray()
    private fun str(cp: IntArray, from: Int = 0, to: Int = cp.size) =
        String(cp, from, to - from)

    /** The last consonant a vowel sign could attach to, or null. */
    fun lastConsonant(text: String): String? {
        val r = cps(text)
        var i = r.size - 1
        while (i >= 0 && isDependent(r[i]) && r[i] != 0x0CCD) i--
        return if (i >= 0 && isConsonant(r[i])) str(r, i, i + 1) else null
    }

    /**
     * Adds [sign] after the last consonant, replacing a vowel sign or virama
     * already there. Anusvara/visarga/virama are appended. Without a
     * consonant the text is unchanged (anusvara/visarga may follow a vowel).
     */
    fun applySign(text: String, sign: String): String {
        val r = cps(text)
        if (r.isEmpty()) return text
        val s = cps(sign).single()
        if (!isVowelSign(s)) {
            val last = r.last()
            if (isConsonant(last) || (isDependent(last) && last != 0x0CCD)) {
                if (s == 0x0CCD && isDependent(last)) return text
                return text + sign
            }
            if (s != 0x0CCD && last in 0x0C85..0x0C94) return text + sign
            return text
        }
        var end = r.size
        while (end > 0 && r[end - 1] in 0x0CBE..0x0CCD) end--
        if (end == 0 || !isConsonant(r[end - 1])) return text
        return str(r, 0, end) + sign
    }

    /**
     * Joins [consonant] to the previous letter as an ottakshara
     * (ಕ + ್ತ → ಕ್ತ). Only after a bare consonant or one ending in a virama;
     * otherwise the text is unchanged.
     */
    fun addOttu(text: String, consonant: String): String {
        val r = cps(text)
        if (r.isEmpty()) return text
        return when {
            isConsonant(r.last()) -> text + "\u0CCD" + consonant
            r.last() == 0x0CCD && r.size >= 2 && isConsonant(r[r.size - 2]) -> text + consonant
            else -> text
        }
    }

    /** Removes the last code point. */
    fun backspace(text: String): String {
        val r = cps(text)
        return if (r.isEmpty()) text else str(r, 0, r.size - 1)
    }
}
