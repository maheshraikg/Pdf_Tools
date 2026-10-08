package com.kspstadk.tulu_nighantu.keyboard

import android.content.Context

/**
 * Keyboard settings chosen in the app (Keyboard screen) and read by
 * [TuluKeyboardService] each time it opens.
 */
data class KeyboardPrefs(
    val vibrate: Boolean = true,
    val sound: Boolean = false,
    val stickerLabel: Boolean = true,
) {
    fun toMap(): Map<String, Boolean> =
        mapOf("vibrate" to vibrate, "sound" to sound, "stickerLabel" to stickerLabel)

    fun save(context: Context) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit()
            .putBoolean("vibrate", vibrate)
            .putBoolean("sound", sound)
            .putBoolean("stickerLabel", stickerLabel)
            .apply()
    }

    companion object {
        private const val FILE = "tulu_keyboard"

        fun load(context: Context): KeyboardPrefs {
            val p = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            return KeyboardPrefs(
                vibrate = p.getBoolean("vibrate", true),
                sound = p.getBoolean("sound", false),
                stickerLabel = p.getBoolean("stickerLabel", true),
            )
        }

        fun fromMap(m: Map<*, *>, base: KeyboardPrefs) = KeyboardPrefs(
            vibrate = m["vibrate"] as? Boolean ?: base.vibrate,
            sound = m["sound"] as? Boolean ?: base.sound,
            stickerLabel = m["stickerLabel"] as? Boolean ?: base.stickerLabel,
        )
    }
}
