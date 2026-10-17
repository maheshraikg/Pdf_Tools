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
 * Reminders the user answers from the notification: the Ramadan Niyyah
 * ("I did" / "Remind me in 30 min") and the Friday-night reminder. The Dart
 * side sends them with their texts; "later" puts the same reminder back 30
 * minutes on, as long as that is before its latest time.
 */
object NoticeScheduler {
    private const val PREFS = "waqt_notices"
    private const val KEY_NOTICES = "notices"
    private const val KEY_LATER = "later"
    private const val KEY_CHANNEL = "channel"
    private const val CHANNEL_ID = "notices"
    private const val ID_BASE = 8000
    private const val LATER_MS = 30 * 60 * 1000L

    /** A reminder is still shown this late (e.g. after the phone was off). */
    private const val LATE_MS = 60 * 60 * 1000L

    const val ACTION_TICK = "com.maheshrai.waqt.NOTICE_TICK"
    const val ACTION_DONE = "com.maheshrai.waqt.NOTICE_DONE"
    const val ACTION_LATER = "com.maheshrai.waqt.NOTICE_LATER"
    const val EXTRA_ID = "id"

    fun save(context: Context, notices: JSONArray, laterLabel: String, channelName: String) {
        // Reminders put off with "later" stay until they are shown.
        val now = System.currentTimeMillis()
        val ids = (0 until notices.length()).map { notices.getJSONObject(it).getInt("id") }.toSet()
        for (n in notices(context)) {
            if (n.optBoolean("deferred") && n.getLong("at") > now && n.getInt("id") !in ids) notices.put(n)
        }
        prefs(context).edit()
            .putString(KEY_NOTICES, notices.toString())
            .putString(KEY_LATER, laterLabel)
            .putString(KEY_CHANNEL, channelName)
            .apply()
        reschedule(context)
    }

    /** Shows the reminders that are due and arms the next one. */
    fun fire(context: Context) {
        val now = System.currentTimeMillis()
        val all = notices(context)
        for (n in all) {
            val at = n.getLong("at")
            if (at <= now + 1500 && at > now - LATE_MS) show(context, n)
        }
        store(context, all.filter { it.getLong("at") > now + 1500 })
        reschedule(context)
    }

    fun done(context: Context, id: Int) {
        nm(context).cancel(ID_BASE + id)
    }

    fun later(context: Context, id: Int) {
        nm(context).cancel(ID_BASE + id)
        val shown = prefs(context).getString("shown_$id", null) ?: return
        val n = JSONObject(shown)
        val at = System.currentTimeMillis() + LATER_MS
        if (at >= n.getLong("latest")) return
        n.put("at", at)
        n.put("deferred", true)
        store(context, notices(context).filter { it.getInt("id") != id } + n)
        reschedule(context)
    }

    fun reschedule(context: Context) {
        val now = System.currentTimeMillis()
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = PendingIntent.getBroadcast(
            context,
            6,
            Intent(context, NoticeReceiver::class.java).setAction(ACTION_TICK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        am.cancel(pi)
        val next = notices(context).map { it.getLong("at") }.filter { it > now }.minOrNull() ?: return
        if (Build.VERSION.SDK_INT < 31 || am.canScheduleExactAlarms()) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pi)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pi)
        }
    }

    private fun show(context: Context, n: JSONObject) {
        val id = n.getInt("id")
        // Kept so "later" can show the same texts again.
        prefs(context).edit().putString("shown_$id", n.toString()).apply()
        val nm = nm(context)
        if (Build.VERSION.SDK_INT >= 26 && nm.getNotificationChannel(CHANNEL_ID) == null) {
            val name = prefs(context).getString(KEY_CHANNEL, null) ?: "Reminders"
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_HIGH),
            )
        }
        fun action(action: String, code: Int) = PendingIntent.getBroadcast(
            context,
            ID_BASE + id * 4 + code,
            Intent(context, NoticeReceiver::class.java).setAction(action).putExtra(EXTRA_ID, id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val open = PendingIntent.getActivity(
            context,
            7,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val b = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_HIGH)
                .setDefaults(Notification.DEFAULT_ALL)
        }
        val text = n.optString("text")
        b.setSmallIcon(R.drawable.ic_stat_waqt)
            .setContentTitle(n.optString("title"))
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setCategory(Notification.CATEGORY_REMINDER)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setContentIntent(open)
            .setAutoCancel(true)
            .addAction(Notification.Action.Builder(null, n.optString("done", "OK"), action(ACTION_DONE, 1)).build())
        if (System.currentTimeMillis() + LATER_MS < n.getLong("latest")) {
            val label = prefs(context).getString(KEY_LATER, null) ?: "Remind me in 30 min"
            b.addAction(Notification.Action.Builder(null, label, action(ACTION_LATER, 2)).build())
        }
        nm.notify(ID_BASE + id, b.build())
    }

    private fun notices(context: Context): List<JSONObject> {
        val raw = prefs(context).getString(KEY_NOTICES, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { arr.getJSONObject(it) }
        } catch (e: org.json.JSONException) {
            emptyList()
        }
    }

    private fun store(context: Context, list: List<JSONObject>) {
        val arr = JSONArray()
        list.forEach { arr.put(it) }
        prefs(context).edit().putString(KEY_NOTICES, arr.toString()).apply()
    }

    private fun nm(context: Context) =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}

/** Reminder time, the answer buttons, and re-arming after boot or clock changes. */
class NoticeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(NoticeScheduler.EXTRA_ID, -1)
        when (intent.action) {
            NoticeScheduler.ACTION_TICK -> NoticeScheduler.fire(context)
            NoticeScheduler.ACTION_DONE -> NoticeScheduler.done(context, id)
            NoticeScheduler.ACTION_LATER -> NoticeScheduler.later(context, id)
            else -> NoticeScheduler.reschedule(context)
        }
    }
}
