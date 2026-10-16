package com.maheshrai.waqt

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import org.json.JSONArray

/**
 * Auto-silent during prayer. The Dart side sends the windows (Azan →
 * Iqama + N minutes) for the coming days; this keeps a single alarm armed
 * for the next start or end, switches the ringer and restores it.
 *
 * The ringer is only restored when it is still in the mode Waqt set, so a
 * change the user made during the prayer is kept.
 */
object SilentScheduler {
    private const val PREFS = "waqt_silent"
    private const val KEY_WINDOWS = "windows"
    private const val KEY_MODE = "mode"
    private const val KEY_ACTIVE = "active"
    private const val KEY_PREVIOUS = "previous_ringer"
    private const val KEY_SET = "set_ringer"
    const val ACTION_TICK = "com.maheshrai.waqt.SILENT_TICK"

    fun save(context: Context, mode: String, windows: List<Pair<Long, Long>>) {
        val arr = JSONArray()
        for ((start, end) in windows) {
            if (end > start) arr.put(JSONArray().put(start).put(end))
        }
        prefs(context).edit()
            .putString(KEY_WINDOWS, arr.toString())
            .putString(KEY_MODE, mode)
            .apply()
        reschedule(context)
    }

    /** Brings the ringer to the state it should have now and arms the next alarm. */
    fun reschedule(context: Context) {
        val now = System.currentTimeMillis()
        val windows = load(context)
        val p = prefs(context)
        val active = p.getBoolean(KEY_ACTIVE, false)
        val inside = windows.any { now >= it.first && now < it.second }
        if (inside && !active) start(context)
        if (!inside && active) end(context)

        val next = windows.flatMap { listOf(it.first, it.second) }.filter { it > now }.minOrNull()
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = pendingIntent(context)
        am.cancel(pi)
        if (next == null) return
        val at = next + 500
        if (Build.VERSION.SDK_INT < 31 || am.canScheduleExactAlarms()) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
        }
    }

    private fun start(context: Context) {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val current = audio.ringerMode
        val p = prefs(context)
        // Already quiet: nothing to do or restore.
        if (current != AudioManager.RINGER_MODE_NORMAL) {
            p.edit().putBoolean(KEY_ACTIVE, true).remove(KEY_SET).apply()
            return
        }
        val wantSilent = p.getString(KEY_MODE, "vibrate") == "silent"
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        var target = if (wantSilent && nm.isNotificationPolicyAccessGranted) {
            AudioManager.RINGER_MODE_SILENT
        } else {
            AudioManager.RINGER_MODE_VIBRATE
        }
        try {
            audio.ringerMode = target
        } catch (e: SecurityException) {
            target = AudioManager.RINGER_MODE_VIBRATE
            try {
                audio.ringerMode = target
            } catch (e2: SecurityException) {
                return
            }
        }
        p.edit()
            .putBoolean(KEY_ACTIVE, true)
            .putInt(KEY_PREVIOUS, current)
            .putInt(KEY_SET, target)
            .apply()
    }

    private fun end(context: Context) {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val p = prefs(context)
        val set = p.getInt(KEY_SET, -1)
        val previous = p.getInt(KEY_PREVIOUS, AudioManager.RINGER_MODE_NORMAL)
        if (set != -1 && audio.ringerMode == set) {
            try {
                audio.ringerMode = previous
            } catch (e: SecurityException) {
                // DND access was revoked meanwhile; leave it to the user.
            }
        }
        p.edit().putBoolean(KEY_ACTIVE, false).remove(KEY_SET).remove(KEY_PREVIOUS).apply()
    }

    private fun load(context: Context): List<Pair<Long, Long>> {
        val raw = prefs(context).getString(KEY_WINDOWS, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map {
                val w = arr.getJSONArray(it)
                w.getLong(0) to w.getLong(1)
            }
        } catch (e: org.json.JSONException) {
            emptyList()
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, SilentReceiver::class.java).setAction(ACTION_TICK)
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

/** Fires at window starts/ends, and after boot, update or a clock change. */
class SilentReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        SilentScheduler.reschedule(context)
        // After boot or a clock change, also re-arm the widget's redraw.
        if (intent.action != SilentScheduler.ACTION_TICK) WaqtWidgetProvider.refresh(context)
    }
}
