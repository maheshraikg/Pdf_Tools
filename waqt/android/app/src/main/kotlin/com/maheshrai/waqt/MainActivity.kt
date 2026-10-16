package com.maheshrai.waqt

import android.Manifest
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Platform side of `lib/app/native.dart`: one-shot location (framework
 * LocationManager, no Google Play services), Do Not Disturb access, battery
 * optimisation settings and the auto-silent schedule.
 */
class MainActivity : FlutterActivity() {
    private var pendingLocation: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLocation" -> getLocation(result, call.argument<Boolean>("prompt") ?: true)
                    "clockStatus" -> result.success(clockStatus())
                    "openDateSettings" -> {
                        open(Intent(Settings.ACTION_DATE_SETTINGS))
                        result.success(null)
                    }
                    "hasDndAccess" -> result.success(notificationManager().isNotificationPolicyAccessGranted)
                    "openDndSettings" -> {
                        open(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "openBatterySettings" -> {
                        if (!open(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))) {
                            open(appDetails())
                        }
                        result.success(null)
                    }
                    "updateWidget" -> {
                        call.argument<String>("data")?.let { WaqtWidgetProvider.save(this, it) }
                        result.success(null)
                    }
                    "setSilentWindows" -> {
                        val mode = call.argument<String>("mode") ?: "vibrate"
                        val raw = call.argument<List<List<Number>>>("windows") ?: emptyList()
                        val windows = raw.mapNotNull { w ->
                            if (w.size == 2) w[0].toLong() to w[1].toLong() else null
                        }
                        SilentScheduler.save(this, mode, windows)
                        result.success(null)
                    }
                    "setAzanAlarms" -> {
                        val events = org.json.JSONArray(call.argument<String>("events") ?: "[]")
                        AzanScheduler.save(
                            this,
                            events,
                            call.argument<Boolean>("vibrate") ?: true,
                            call.argument<Boolean>("whenSilent") ?: false,
                            call.argument<String>("stopLabel") ?: "Stop",
                            call.argument<String>("channelName") ?: "Azan",
                            call.argument<Boolean>("fullScreen") ?: true,
                        )
                        result.success(null)
                    }
                    "saveSound" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null) {
                            result.error("invalid", "No data", null)
                        } else {
                            result.success(
                                AzanScheduler.saveSound(
                                    this,
                                    call.argument<String>("slot") ?: "azan",
                                    call.argument<String>("ext") ?: "mp3",
                                    bytes,
                                ),
                            )
                        }
                    }
                    "playSound" -> {
                        AzanService.play(
                            this,
                            call.argument<String>("title") ?: "",
                            call.argument<String>("body") ?: "",
                            call.argument<String>("sound") ?: "chime",
                        )
                        result.success(null)
                    }
                    "canFullScreen" -> {
                        result.success(
                            Build.VERSION.SDK_INT < 34 || notificationManager().canUseFullScreenIntent(),
                        )
                    }
                    "openFullScreenSettings" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            open(
                                Intent(
                                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                                    Uri.parse("package:$packageName"),
                                ),
                            ) || open(appDetails())
                        }
                        result.success(null)
                    }
                    "stopSound" -> {
                        AzanService.stop(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Re-arm the silent schedule in case the process was killed.
        SilentScheduler.reschedule(this)
        AzanScheduler.reschedule(this)
    }

    private fun notificationManager() =
        getSystemService(NOTIFICATION_SERVICE) as NotificationManager

    private fun appDetails() =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))

    private fun open(intent: Intent): Boolean = try {
        startActivity(intent)
        true
    } catch (e: ActivityNotFoundException) {
        false
    }

    // ---- Location ----

    private fun hasLocationPermission() =
        checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun getLocation(result: MethodChannel.Result, prompt: Boolean) {
        if (hasLocationPermission()) {
            fetchLocation(result)
            return
        }
        if (!prompt) {
            result.error("denied", "No location permission", null)
            return
        }
        if (pendingLocation != null) {
            result.error("unavailable", "A location request is already running", null)
            return
        }
        pendingLocation = result
        requestPermissions(
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ),
            REQUEST_LOCATION,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_LOCATION) return
        val result = pendingLocation ?: return
        pendingLocation = null
        if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
            fetchLocation(result)
        } else {
            result.error("denied", "Location permission denied", null)
        }
    }

    private fun fetchLocation(result: MethodChannel.Result) {
        val lm = getSystemService(LOCATION_SERVICE) as LocationManager
        val enabled = if (Build.VERSION.SDK_INT >= 28) {
            lm.isLocationEnabled
        } else {
            lm.getProviders(true).any { it != LocationManager.PASSIVE_PROVIDER }
        }
        val providers = lm.getProviders(true).filter { it != LocationManager.PASSIVE_PROVIDER }
        if (!enabled || providers.isEmpty()) {
            result.error("disabled", "Location is turned off", null)
            return
        }
        val last = providers.mapNotNull {
            try {
                lm.getLastKnownLocation(it)
            } catch (e: SecurityException) {
                null
            }
        }.maxByOrNull { it.time }
        if (last != null && System.currentTimeMillis() - last.time < FRESH_MS) {
            result.success(toMap(last))
            return
        }

        // Network is quick indoors and a few hundred metres is plenty for
        // prayer times; fall back to GPS.
        val provider = when {
            LocationManager.NETWORK_PROVIDER in providers -> LocationManager.NETWORK_PROVIDER
            LocationManager.GPS_PROVIDER in providers -> LocationManager.GPS_PROVIDER
            else -> providers.first()
        }
        val handler = Handler(Looper.getMainLooper())
        var done = false
        var listener: LocationListener? = null
        fun finish(loc: Location?) {
            if (done) return
            done = true
            listener?.let { lm.removeUpdates(it) }
            val best = loc ?: last
            if (best != null) {
                result.success(toMap(best))
            } else {
                result.error("unavailable", "No location fix", null)
            }
        }
        try {
            if (Build.VERSION.SDK_INT >= 30) {
                lm.getCurrentLocation(provider, null, mainExecutor) { finish(it) }
            } else {
                val l = object : LocationListener {
                    override fun onLocationChanged(location: Location) = finish(location)
                    @Deprecated("Deprecated in Java")
                    override fun onStatusChanged(p: String?, status: Int, extras: Bundle?) {}
                    override fun onProviderEnabled(p: String) {}
                    override fun onProviderDisabled(p: String) {}
                }
                listener = l
                @Suppress("DEPRECATION")
                lm.requestSingleUpdate(provider, l, Looper.getMainLooper())
            }
        } catch (e: SecurityException) {
            finish(null)
            return
        } catch (e: IllegalArgumentException) {
            finish(null)
            return
        }
        handler.postDelayed({ finish(null) }, TIMEOUT_MS)
    }

    /**
     * Whether the phone sets its clock and time zone automatically, and how
     * far its clock is from satellite (GNSS) time when that is known.
     */
    private fun clockStatus(): Map<String, Any?> {
        val autoTime = Settings.Global.getInt(contentResolver, Settings.Global.AUTO_TIME, 1) == 1
        val autoZone = Settings.Global.getInt(contentResolver, Settings.Global.AUTO_TIME_ZONE, 1) == 1
        var offset: Long? = null
        if (Build.VERSION.SDK_INT >= 29) {
            try {
                val gnss = android.os.SystemClock.currentGnssTimeClock().millis()
                offset = System.currentTimeMillis() - gnss
            } catch (e: java.time.DateTimeException) {
                // No recent satellite fix: unknown.
            }
        }
        return mapOf("autoTime" to autoTime, "autoZone" to autoZone, "offsetMs" to offset)
    }

    private fun toMap(l: Location): Map<String, Any?> = mapOf(
        "latitude" to l.latitude,
        "longitude" to l.longitude,
        "altitude" to if (l.hasAltitude()) l.altitude else null,
    )

    companion object {
        private const val CHANNEL = "com.maheshrai.waqt/native"
        private const val REQUEST_LOCATION = 4101
        private const val FRESH_MS = 10 * 60 * 1000L
        private const val TIMEOUT_MS = 30 * 1000L
    }
}
