package com.maheshrai.waqt

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

/**
 * The permanent "next prayer" notification: the next Azan with a live
 * countdown and the next Iqama. The Dart side sends the states for the
 * coming days (each valid from its start time); this shows the current one
 * and keeps one alarm armed for the next change, so it stays right while
 * the app is closed. Like the original app it is held by a foreground
 * service, so the phone does not clear it when it stops the app, and it
 * comes back if swiped away.
 */
object StatusNotifier {
    private const val PREFS = "waqt_status"
    private const val KEY_STATES = "states"
    private const val KEY_CHANNEL = "channel"
    const val ACTION_TICK = "com.maheshrai.waqt.STATUS_TICK"
    private const val CHANNEL_ID = "next_prayer"
    const val NOTIFICATION_ID = 7100

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
        val service = Intent(context, StatusService::class.java)
        val n = current(context)
        if (n == null) {
            context.stopService(service)
            nm.cancel(NOTIFICATION_ID)
        } else {
            try {
                if (Build.VERSION.SDK_INT >= 26) {
                    context.startForegroundService(service)
                } else {
                    context.startService(service)
                }
            } catch (e: Exception) {
                // Not allowed from the background just now: a plain one.
                nm.notify(NOTIFICATION_ID, n)
            }
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

    /**
     * The notification for now: the latest state already begun (kept even
     * when an alarm comes late), or null when there is none left.
     */
    fun current(context: Context): Notification? {
        val now = System.currentTimeMillis()
        val states = states(context)
        if (states.none { it.getLong("countdown") > now }) return null
        val s = states.lastOrNull { it.getLong("from") <= now } ?: states.first()
        return build(context, s)
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
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(open)
            // Swiped away (Android 14 allows it): shown again at once.
            .setDeleteIntent(
                PendingIntent.getBroadcast(
                    context,
                    6,
                    Intent(context, StatusReceiver::class.java).setAction(ACTION_TICK),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setShowWhen(true)
            .setWhen(s.getLong("countdown"))
            .setUsesChronometer(true)
        if (Build.VERSION.SDK_INT >= 24) b.setChronometerCountDown(true)
        if (s.has("iqama")) {
            // Centred layout like the original app (texts sent from Dart).
            b.setCustomContentView(views(context, R.layout.status_small, s, false))
            b.setCustomBigContentView(views(context, R.layout.status_big, s, true))
        } else {
            b.setStyle(Notification.BigTextStyle().bigText(s.optString("text")))
        }
        return b.build()
    }

    private fun views(context: Context, layout: Int, s: JSONObject, big: Boolean): RemoteViews {
        val v = RemoteViews(context.packageName, layout)
        v.setTextViewText(R.id.status_azan, s.optString("title"))
        v.setTextViewText(R.id.status_iqama, s.optString("iqama"))
        // Countdown to the next Azan, on the elapsed-time clock.
        val left = s.getLong("countdown") - System.currentTimeMillis()
        v.setChronometer(R.id.status_countdown, SystemClock.elapsedRealtime() + left, null, true)
        v.setChronometerCountDown(R.id.status_countdown, true)
        if (big) {
            val where = s.optString("where")
            v.setTextViewText(R.id.status_where_azan, where)
            v.setTextViewText(R.id.status_where_iqama, where)
            val gone = if (where.isEmpty()) android.view.View.GONE else android.view.View.VISIBLE
            v.setViewVisibility(R.id.status_where_azan, gone)
            v.setViewVisibility(R.id.status_where_iqama, gone)
            if (s.optString("iqama").isEmpty()) v.setViewVisibility(R.id.status_iqama, android.view.View.GONE)
        }
        return v
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

/** Holds the next-prayer notification in the foreground, as the original. */
class StatusService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val n = StatusNotifier.current(this)
        if (n == null) {
            if (Build.VERSION.SDK_INT >= 24) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            stopSelf()
            return START_NOT_STICKY
        }
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(
                StatusNotifier.NOTIFICATION_ID,
                n,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(StatusNotifier.NOTIFICATION_ID, n)
        }
        return START_STICKY
    }
}
