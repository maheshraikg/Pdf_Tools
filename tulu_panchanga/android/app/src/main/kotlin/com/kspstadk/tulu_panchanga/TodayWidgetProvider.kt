package com.kspstadk.tulu_panchanga

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Shows today's panchanga. The app stores a month of precomputed lines keyed
 * by date ("days" JSON); the widget picks today's entry, so it stays correct
 * after midnight without running Dart.
 */
class TodayWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val day = try {
            JSONObject(widgetData.getString("days", "{}") ?: "{}").optJSONObject(today)
        } catch (e: Exception) {
            null
        }
        val launch = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.today_widget)
            if (day != null) {
                views.setTextViewText(R.id.widget_title, day.optString("title"))
                views.setTextViewText(R.id.widget_line1, day.optString("line1"))
                views.setTextViewText(R.id.widget_line2, day.optString("line2"))
                views.setTextViewText(R.id.widget_line3, day.optString("line3"))
            } else {
                views.setTextViewText(R.id.widget_title, widgetData.getString("stale", "Tulu Panchanga"))
                views.setTextViewText(R.id.widget_line1, "Open the app to refresh")
                views.setTextViewText(R.id.widget_line2, "")
                views.setTextViewText(R.id.widget_line3, "")
            }
            views.setTextViewText(R.id.widget_place, widgetData.getString("place", ""))
            views.setOnClickPendingIntent(R.id.widget_root, launch)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
