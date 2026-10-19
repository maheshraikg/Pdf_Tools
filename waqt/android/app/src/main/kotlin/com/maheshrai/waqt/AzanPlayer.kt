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
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * Azan with a chosen sound. The Dart side sends the Azan times for the
 * coming days with their title, text and sound; this keeps one alarm armed
 * for the next one and, when it fires, [AzanService] plays the sound as an
 * alarm with a Stop button.
 *
 * Sounds: "chime" and "bell" (built in, res/raw) or "file:<path>" (a file
 * the user picked, copied into the app's storage).
 */
object AzanScheduler {
    private const val PREFS = "waqt_azan"
    private const val KEY_EVENTS = "events"
    private const val KEY_VIBRATE = "vibrate"
    private const val KEY_WHEN_SILENT = "when_silent"
    private const val KEY_STOP_LABEL = "stop_label"
    private const val KEY_CHANNEL_NAME = "channel_name"
    private const val KEY_FULL_SCREEN = "full_screen"
    const val ACTION_FIRE = "com.maheshrai.waqt.AZAN_FIRE"

    /** An Azan is still played this late (e.g. after the phone was off). */
    private const val LATE_MS = 2 * 60 * 1000L

    fun save(
        context: Context,
        events: JSONArray,
        vibrate: Boolean,
        whenSilent: Boolean,
        stopLabel: String,
        channelName: String,
        fullScreen: Boolean,
    ) {
        prefs(context).edit()
            .putString(KEY_EVENTS, events.toString())
            .putBoolean(KEY_VIBRATE, vibrate)
            .putBoolean(KEY_WHEN_SILENT, whenSilent)
            .putString(KEY_STOP_LABEL, stopLabel)
            .putString(KEY_CHANNEL_NAME, channelName)
            .putBoolean(KEY_FULL_SCREEN, fullScreen)
            .apply()
        reschedule(context)
    }

    fun vibrate(context: Context) = prefs(context).getBoolean(KEY_VIBRATE, true)

    fun playWhenSilent(context: Context) = prefs(context).getBoolean(KEY_WHEN_SILENT, false)

    /** Texts in the app's language (sent from Dart). */
    fun stopLabel(context: Context) = prefs(context).getString(KEY_STOP_LABEL, null) ?: "Stop"

    fun channelName(context: Context) = prefs(context).getString(KEY_CHANNEL_NAME, null) ?: "Azan"

    fun fullScreen(context: Context) = prefs(context).getBoolean(KEY_FULL_SCREEN, true)

    fun reschedule(context: Context) {
        val now = System.currentTimeMillis()
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = firePendingIntent(context)
        am.cancel(pi)
        val next = events(context).map { it.getLong("at") }.filter { it > now }.minOrNull() ?: return
        if (Build.VERSION.SDK_INT < 31 || am.canScheduleExactAlarms()) {
            // An alarm clock is exact in Doze and may start the player.
            val show = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            am.setAlarmClock(AlarmManager.AlarmClockInfo(next, show), pi)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pi)
        }
    }

    /** Plays the Azan that is due now (if any) and arms the next one. */
    fun fire(context: Context) {
        val now = System.currentTimeMillis()
        val due = events(context)
            .filter { it.getLong("at") in (now - LATE_MS)..(now + 1500) }
            .maxByOrNull { it.getLong("at") }
        if (due != null) {
            AzanService.play(
                context,
                due.optString("title"),
                due.optString("body"),
                due.optString("sound", "chime"),
                fromAlarm = true,
                volume = due.optInt("volume", 0),
                full = if (due.has("full")) due.optBoolean("full") else null,
            )
        }
        // Forget played and missed events so they never repeat.
        val left = JSONArray()
        for (e in events(context)) if (e.getLong("at") > now + 1500) left.put(e)
        prefs(context).edit().putString(KEY_EVENTS, left.toString()).apply()
        reschedule(context)
    }

    private fun events(context: Context): List<JSONObject> {
        val raw = prefs(context).getString(KEY_EVENTS, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { arr.getJSONObject(it) }
        } catch (e: org.json.JSONException) {
            emptyList()
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun firePendingIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        1,
        Intent(context, AzanReceiver::class.java).setAction(ACTION_FIRE),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** Copies a picked sound into app storage; returns the "file:" sound. */
    fun saveSound(context: Context, slot: String, ext: String, bytes: ByteArray): String {
        val dir = File(context.filesDir, "sounds").apply { mkdirs() }
        dir.listFiles()?.filter { it.name.startsWith("$slot.") }?.forEach { it.delete() }
        val safeExt = ext.lowercase().filter { it.isLetterOrDigit() }.take(5).ifEmpty { "mp3" }
        val f = File(dir, "$slot.$safeExt")
        f.writeBytes(bytes)
        return "file:" + f.absolutePath
    }
}

/** Fires at Azan time, and re-arms after boot, update or a clock change. */
class AzanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == AzanScheduler.ACTION_FIRE) {
            AzanScheduler.fire(context)
        } else {
            AzanScheduler.reschedule(context)
        }
    }
}

/** Plays one Azan in the foreground, with Stop in its notification. */
class AzanService : Service() {
    private var player: MediaPlayer? = null

    /** A preview from the settings: leaves no notification behind. */
    private var preview = false
    private var focus: AudioFocusRequest? = null
    private val handler = Handler(Looper.getMainLooper())

    /** Alarm volume before a custom volume was set (-1: untouched). */
    private var savedVolume = -1

    /** Alarm volume while playing; a volume key press changes it → stop. */
    private var playingVolume = -1
    private var volumeObserver: android.database.ContentObserver? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopAll()
            return START_NOT_STICKY
        }
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: ""
        val body = intent?.getStringExtra(EXTRA_BODY) ?: ""
        val sound = intent?.getStringExtra(EXTRA_SOUND) ?: "chime"
        val volume = intent?.getIntExtra(EXTRA_VOLUME, 0) ?: 0
        preview = intent?.getBooleanExtra(EXTRA_PREVIEW, false) == true
        val notification = buildNotification(this, title, body, intent?.getBooleanExtra(EXTRA_FULL, false) == true)
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        releasePlayer()
        if (AzanScheduler.vibrate(this)) vibrate()
        if (shouldPlaySound()) {
            applyVolume(volume)
            start(sound)
        } else {
            // Leave the notification, without sound, and end the service.
            handler.postDelayed({ stopForegroundKeepNotification() }, 1500)
        }
        handler.removeCallbacksAndMessages(TIMEOUT_TOKEN)
        handler.postAtTime({ stopAll() }, TIMEOUT_TOKEN, android.os.SystemClock.uptimeMillis() + MAX_PLAY_MS)
        return START_NOT_STICKY
    }

    private fun shouldPlaySound(): Boolean {
        val audio = getSystemService(AUDIO_SERVICE) as AudioManager
        if (audio.mode == AudioManager.MODE_IN_CALL || audio.mode == AudioManager.MODE_IN_COMMUNICATION) {
            return false
        }
        if (audio.ringerMode == AudioManager.RINGER_MODE_NORMAL) return true
        return AzanScheduler.playWhenSilent(this)
    }

    private fun start(sound: String, retried: Boolean = false) {
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val mp = MediaPlayer()
        player = mp
        try {
            mp.setAudioAttributes(attrs)
            mp.setWakeMode(this, android.os.PowerManager.PARTIAL_WAKE_LOCK)
            when {
                sound.startsWith("file:") -> mp.setDataSource(sound.removePrefix("file:"))
                sound == "system" -> {
                    // The phone's notification sound, once.
                    val uri = android.media.RingtoneManager.getDefaultUri(
                        android.media.RingtoneManager.TYPE_NOTIFICATION,
                    ) ?: rawUri(this, "chime")
                    mp.setDataSource(this, uri)
                }
                else -> mp.setDataSource(this, rawUri(this, sound))
            }
            mp.setOnPreparedListener {
                requestFocus(attrs)
                it.start()
                playing = true
            }
            mp.setOnCompletionListener {
                if (preview) stopAll() else stopForegroundKeepNotification()
            }
            mp.setOnErrorListener { _, _, _ ->
                releasePlayer()
                if (!retried) start("chime", true) else stopForegroundKeepNotification()
                true
            }
            mp.prepareAsync()
        } catch (e: Exception) {
            Log.w(TAG, "Cannot play $sound", e)
            releasePlayer()
            if (!retried) start("chime", true) else stopForegroundKeepNotification()
        }
    }

    /** Sets the alarm stream to [percent] of its maximum (0: leave it). */
    private fun applyVolume(percent: Int) {
        val audio = getSystemService(AUDIO_SERVICE) as AudioManager
        val stream = AudioManager.STREAM_ALARM
        if (percent in 1..100) {
            if (savedVolume < 0) savedVolume = audio.getStreamVolume(stream)
            val max = audio.getStreamMaxVolume(stream)
            val v = (max * percent + 50) / 100
            try {
                audio.setStreamVolume(stream, v.coerceIn(1, max), 0)
            } catch (e: SecurityException) {
                // Do Not Disturb forbids changing it: play at the phone's volume.
            }
        }
        playingVolume = audio.getStreamVolume(stream)
        watchVolumeKeys()
    }

    /** Pressing a volume key while the Azan plays stops it. */
    private fun watchVolumeKeys() {
        if (volumeObserver != null) return
        val audio = getSystemService(AUDIO_SERVICE) as AudioManager
        val o = object : android.database.ContentObserver(handler) {
            override fun onChange(selfChange: Boolean) {
                val now = audio.getStreamVolume(AudioManager.STREAM_ALARM)
                if (player != null && playingVolume >= 0 && now != playingVolume) {
                    stopAll()
                }
            }
        }
        volumeObserver = o
        contentResolver.registerContentObserver(android.provider.Settings.System.CONTENT_URI, true, o)
    }

    private fun restoreVolume() {
        volumeObserver?.let { contentResolver.unregisterContentObserver(it) }
        volumeObserver = null
        playingVolume = -1
        if (savedVolume >= 0) {
            val audio = getSystemService(AUDIO_SERVICE) as AudioManager
            try {
                audio.setStreamVolume(AudioManager.STREAM_ALARM, savedVolume, 0)
            } catch (e: SecurityException) {
                // Not allowed in Do Not Disturb.
            }
            savedVolume = -1
        }
    }

    private fun requestFocus(attrs: AudioAttributes) {
        val audio = getSystemService(AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= 26) {
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(attrs)
                .build()
            focus = req
            audio.requestAudioFocus(req)
        }
    }

    private fun vibrate() {
        val v = getSystemService(VIBRATOR_SERVICE) as? Vibrator ?: return
        val pattern = longArrayOf(0, 600, 400, 600, 400, 600)
        if (Build.VERSION.SDK_INT >= 26) {
            v.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(pattern, -1)
        }
    }

    private fun releasePlayer() {
        player?.let {
            try {
                it.stop()
            } catch (e: IllegalStateException) {
                // Not started yet.
            }
            it.release()
        }
        player = null
        playing = false
        restoreVolume()
        val audio = getSystemService(AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= 26) focus?.let { audio.abandonAudioFocusRequest(it) }
        focus = null
    }

    /** Sound finished: keep the notification as a record, end the service. */
    private fun stopForegroundKeepNotification() {
        releasePlayer()
        if (Build.VERSION.SDK_INT >= 24) {
            stopForeground(STOP_FOREGROUND_DETACH)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(false)
        }
        stopSelf()
    }

    private fun stopAll() {
        sendBroadcast(Intent(AzanActivity.ACTION_FINISHED).setPackage(packageName))
        releasePlayer()
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(NOTIFICATION_ID)
        (getSystemService(VIBRATOR_SERVICE) as? Vibrator)?.cancel()
        if (Build.VERSION.SDK_INT >= 24) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        releasePlayer()
        super.onDestroy()
    }

    companion object {
        private const val TAG = "WaqtAzan"
        const val ACTION_PLAY = "com.maheshrai.waqt.AZAN_PLAY"
        const val ACTION_STOP = "com.maheshrai.waqt.AZAN_STOP"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_BODY = "body"
        private const val EXTRA_SOUND = "sound"
        private const val EXTRA_FULL = "full"
        private const val EXTRA_VOLUME = "volume"
        private const val EXTRA_PREVIEW = "preview"

        /** Whether a sound is playing now (for the settings' play/stop). */
        @Volatile
        var playing = false
        private const val CHANNEL = "azan_player"
        private const val FALLBACK_CHANNEL = "azan_player_fallback"
        private const val NOTIFICATION_ID = 7001
        private const val MAX_PLAY_MS = 6 * 60 * 1000L
        private val TIMEOUT_TOKEN = Any()

        fun rawUri(context: Context, sound: String): Uri {
            val id = when (sound) {
                "azan" -> R.raw.waqt_azan
                "bell" -> R.raw.waqt_bell
                else -> R.raw.waqt_chime
            }
            return Uri.parse("android.resource://${context.packageName}/$id")
        }

        fun play(
            context: Context,
            title: String,
            body: String,
            sound: String,
            fromAlarm: Boolean = false,
            volume: Int = 0,
            full: Boolean? = null,
            preview: Boolean = false,
        ) {
            val i = Intent(context, AzanService::class.java)
                .setAction(ACTION_PLAY)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_BODY, body)
                .putExtra(EXTRA_SOUND, sound)
                .putExtra(EXTRA_VOLUME, volume)
                .putExtra(EXTRA_PREVIEW, preview)
                .putExtra(EXTRA_FULL, fromAlarm && (full ?: AzanScheduler.fullScreen(context)))
            try {
                if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(i) else context.startService(i)
            } catch (e: Exception) {
                // Background start refused (no exact-alarm permission on
                // Android 12+): at least show the Azan with a sound.
                Log.w(TAG, "Cannot start the Azan player", e)
                if (fromAlarm) fallback(context, title, body, sound)
            }
        }

        fun stop(context: Context) {
            try {
                context.startService(Intent(context, AzanService::class.java).setAction(ACTION_STOP))
            } catch (e: Exception) {
                // Service not running and cannot be started: nothing plays.
            }
        }

        private fun channel(context: Context, id: String, sound: Uri?) {
            if (Build.VERSION.SDK_INT < 26) return
            val nm = context.getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(id) != null) return
            val c = NotificationChannel(id, AzanScheduler.channelName(context), NotificationManager.IMPORTANCE_HIGH)
            c.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            if (sound == null) {
                c.setSound(null, null)
            } else {
                c.setSound(
                    sound,
                    AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build(),
                )
            }
            nm.createNotificationChannel(c)
        }

        private fun builder(context: Context, channelId: String): Notification.Builder =
            if (Build.VERSION.SDK_INT >= 26) {
                Notification.Builder(context, channelId)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context).setPriority(Notification.PRIORITY_MAX)
            }

        fun buildNotification(context: Context, title: String, body: String, full: Boolean): Notification {
            channel(context, CHANNEL, null)
            val stop = PendingIntent.getService(
                context,
                2,
                Intent(context, AzanService::class.java).setAction(ACTION_STOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val open = PendingIntent.getActivity(
                context,
                3,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            return builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_stat_waqt)
                .setContentTitle(title)
                .setContentText(body)
                .setCategory(Notification.CATEGORY_ALARM)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setContentIntent(open)
                .setDeleteIntent(stop)
                .apply {
                    if (full) {
                        // Over the lock screen, like an alarm clock.
                        val screen = PendingIntent.getActivity(
                            context,
                            4,
                            AzanActivity.intent(context, title, body),
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                        )
                        setFullScreenIntent(screen, true)
                    }
                }
                .setAutoCancel(true)
                .addAction(
                    Notification.Action.Builder(null, AzanScheduler.stopLabel(context), stop).build(),
                )
                .build()
        }

        private fun fallback(context: Context, title: String, body: String, sound: String) {
            val uri = if (sound.startsWith("file:") || sound == "system") {
                android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION)
                    ?: rawUri(context, "chime")
            } else {
                rawUri(context, sound)
            }
            channel(context, FALLBACK_CHANNEL, uri)
            val nm = context.getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            val n = builder(context, FALLBACK_CHANNEL)
                .setSmallIcon(R.drawable.ic_stat_waqt)
                .setContentTitle(title)
                .setContentText(body)
                .setCategory(Notification.CATEGORY_ALARM)
                .setAutoCancel(true)
            if (Build.VERSION.SDK_INT < 26) {
                @Suppress("DEPRECATION")
                n.setSound(uri)
            }
            nm.notify(NOTIFICATION_ID + 1, n.build())
        }
    }
}
