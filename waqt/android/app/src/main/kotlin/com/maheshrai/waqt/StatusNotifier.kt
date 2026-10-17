package com.maheshrai.waqt

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/**
 * The permanent "next prayer" notification: the next Azan with a live
 * countdown and the next Iqama. The Dart side sends the states for the
 * coming days (each valid from its start time); this shows the current one
 * and keeps one alarm armed for the next change, so it stays right while
 * the app is closed.
 */
object StatusNotifier {
    private const val PREFS = "waqt_status"
    private const val KEY_STATES = "states"
    private const val KEY_CHANNEL = "channel"
    const val ACTION_TICK = "com.maheshrai.waqt.STATUS_TICK"
    private const val CHANNEL_ID = "next_prayer"
    private const val NOTIFICATION_ID = 7100

    fun save(context: Context, states: JSONArray, channelName: String) {
        prefs(context).edit()
            .putString(KEY_STATES, states.toString())
            .putString(KEY_CHANNEL, channelName)
            .apply()
        refresh(context)
    }

    /** Shows the current state (or removes the notification) and re-arms. */
    fun refresh(context: Context) {
        val now = System.currentTimeMillis()
        val states = states(context)
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val current = states.lastOrNull { it.getLong("from") <= now }
        if (current == null || current.getLong("countdown") <= now) {
            nm.cancel(NOTIFICATION_ID)
        } else {
            nm.notify(NOTIFICATION_ID, build(context, current))
        }
        val next = states.map { it.getLong("from") }.filter { it > now }.minOrNull()
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = PendingIntent.getBroadcast(
            context,
            3,
            Intent(context, StatusReceiver::class.java).setAction(ACTION_TICK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        am.cancel(pi)
        if (next == null) return
        if (Build.VERSION.SDK_INT < 31 || am.canScheduleExactAlarms()) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next + 500, pi)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next + 500, pi)
        }
    }

    private fun build(context: Context, s: JSONObject): Notification {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26 && nm.getNotificationChannel(CHANNEL_ID) == null) {
            val name = prefs(context).getString(KEY_CHANNEL, null) ?: "Next prayer"
            val c = NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_LOW)
            c.setShowBadge(false)
            c.setSound(null, null)
            c.enableVibration(false)
            c.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            nm.createNotificationChannel(c)
        }
        val open = PendingIntent.getActivity(
            context,
            5,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val b = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        }
        b.setSmallIcon(R.drawable.ic_stat_waqt)
            .setContentTitle(s.optString("title"))
            .setContentText(s.optString("text"))
            .setStyle(Notification.BigTextStyle().bigText(s.optString("text")))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(open)
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setShowWhen(true)
            .setWhen(s.getLong("countdown"))
            .setUsesChronometer(true)
        if (Build.VERSION.SDK_INT >= 24) b.setChronometerCountDown(true)
        return b.build()
    }

    private fun states(context: Context): List<JSONObject> {
        val raw = prefs(context).getString(KEY_STATES, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { arr.getJSONObject(it) }.sortedBy { it.getLong("from") }
        } catch (e: org.json.JSONException) {
            emptyList()
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}

/** Fires at each change of the next prayer, and after boot or clock changes. */
class StatusReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) = StatusNotifier.refresh(context)
}
