package com.maheshrai.waqt

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import org.json.JSONException
import org.json.JSONObject

/**
 * Home-screen widget: the next prayer with a live countdown and the five
 * times of its day. The app sends ~20 days of times (`save`); the widget
 * picks the next prayer itself and re-renders when it passes, so it stays
 * right without the app running.
 *
 * Data (JSON): {"place", "format" (countdown, with %s), "stale",
 *   "days": [{"title", "p": [{"n", "s", "t"(epoch ms)} × 5]}]}
 */
class WaqtWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    companion object {
        private const val PREFS = "waqt_widget"
        private const val KEY_DATA = "data"
        private const val GOLD = 0xFFE8C468.toInt()
        private const val WHITE = 0xFFFFFFFF.toInt()
        private const val DIM = 0xB3FFFFFF.toInt()

        private val NAME_IDS = intArrayOf(
            R.id.widget_p0_name, R.id.widget_p1_name, R.id.widget_p2_name,
            R.id.widget_p3_name, R.id.widget_p4_name,
        )
        private val TIME_IDS = intArrayOf(
            R.id.widget_p0_time, R.id.widget_p1_time, R.id.widget_p2_time,
            R.id.widget_p3_time, R.id.widget_p4_time,
        )

        /** Stores new data from the app and redraws all widgets. */
        fun save(context: Context, json: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putString(KEY_DATA, json).apply()
            refresh(context)
        }

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, WaqtWidgetProvider::class.java))
            if (ids.isNotEmpty()) render(context, manager, ids)
        }

        private fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_DATA, null)
            val data = try {
                if (raw == null) null else JSONObject(raw)
            } catch (e: JSONException) {
                null
            }
            val now = System.currentTimeMillis()
            val launch = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            // The day holding the next prayer, and that prayer's index.
            var day: JSONObject? = null
            var nextIndex = -1
            val days = data?.optJSONArray("days")
            if (days != null) {
                loop@ for (d in 0 until days.length()) {
                    val candidate = days.optJSONObject(d) ?: continue
                    val prayers = candidate.optJSONArray("p") ?: continue
                    for (i in 0 until prayers.length()) {
                        if ((prayers.optJSONObject(i)?.optLong("t") ?: 0L) > now) {
                            day = candidate
                            nextIndex = i
                            break@loop
                        }
                    }
                }
            }

            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.waqt_widget)
                views.setOnClickPendingIntent(R.id.widget_root, launch)
                views.setTextViewText(R.id.widget_place, data?.optString("place") ?: "")
                val prayers = day?.optJSONArray("p")
                if (day == null || prayers == null) {
                    views.setTextViewText(R.id.widget_title, "")
                    views.setTextViewText(R.id.widget_next, data?.optString("stale") ?: "Waqt")
                    views.setChronometer(R.id.widget_countdown, SystemClock.elapsedRealtime(), "", false)
                    for (i in NAME_IDS.indices) {
                        views.setTextViewText(NAME_IDS[i], "")
                        views.setTextViewText(TIME_IDS[i], "")
                    }
                } else {
                    views.setTextViewText(R.id.widget_title, day.optString("title"))
                    val next = prayers.getJSONObject(nextIndex)
                    views.setTextViewText(
                        R.id.widget_next,
                        "${next.optString("n")}  ${next.optString("s")}",
                    )
                    val base = SystemClock.elapsedRealtime() + (next.optLong("t") - now)
                    views.setChronometer(
                        R.id.widget_countdown,
                        base,
                        data?.optString("format", "%s") ?: "%s",
                        true,
                    )
                    views.setChronometerCountDown(R.id.widget_countdown, true)
                    for (i in NAME_IDS.indices) {
                        val p = prayers.optJSONObject(i)
                        views.setTextViewText(NAME_IDS[i], p?.optString("n") ?: "")
                        views.setTextViewText(TIME_IDS[i], p?.optString("s") ?: "")
                        views.setTextColor(TIME_IDS[i], if (i == nextIndex) GOLD else WHITE)
                        views.setTextColor(NAME_IDS[i], if (i == nextIndex) GOLD else DIM)
                    }
                    scheduleNext(context, next.optLong("t"))
                }
                manager.updateAppWidget(id, views)
            }
        }

        /** Redraw just after the next prayer (no wake-up: screen-off doesn't matter). */
        private fun scheduleNext(context: Context, at: Long) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, WaqtWidgetProvider::class.java)
                .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                .putExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_IDS,
                    AppWidgetManager.getInstance(context)
                        .getAppWidgetIds(ComponentName(context, WaqtWidgetProvider::class.java)),
                )
            val pi = PendingIntent.getBroadcast(
                context,
                1,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val time = at + 1000
            if (Build.VERSION.SDK_INT < 31 || am.canScheduleExactAlarms()) {
                am.setExact(AlarmManager.RTC, time, pi)
            } else {
                am.set(AlarmManager.RTC, time, pi)
            }
        }
    }
}
