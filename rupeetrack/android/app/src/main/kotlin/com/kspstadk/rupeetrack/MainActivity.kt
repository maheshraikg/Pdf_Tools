package com.kspstadk.rupeetrack

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Small native bridge ("rupeetrack/native"):
 *  - openApp / isInstalled: hand off to a payment app (CRED, PhonePe, ...).
 *  - readSms: bank messages from the SMS inbox, read on the phone only.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rupeetrack/native")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openApp" -> result.success(openApp(call.argument<String>("package")!!))
                    "isInstalled" -> result.success(
                        packageManager.getLaunchIntentForPackage(
                            call.argument<String>("package")!!
                        ) != null
                    )
                    "readSms" -> {
                        if (checkSelfPermission(Manifest.permission.READ_SMS) !=
                            PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error("permission", "SMS permission not granted", null)
                        } else {
                            val since = call.argument<Number>("since")?.toLong() ?: 0L
                            val limit = call.argument<Int>("limit") ?: 5000
                            // Cursor work off the UI thread; reply on it.
                            Thread {
                                try {
                                    val messages = readSms(since, limit)
                                    runOnUiThread { result.success(messages) }
                                } catch (e: Exception) {
                                    runOnUiThread { result.error("read", e.message, null) }
                                }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Opens [pkg]; if it is not installed, opens its Play Store page. */
    private fun openApp(pkg: String): Boolean {
        val launch = packageManager.getLaunchIntentForPackage(pkg)
        if (launch != null) {
            startActivity(launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            return true
        }
        try {
            startActivity(
                Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$pkg"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        } catch (e: ActivityNotFoundException) {
            startActivity(
                Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("https://play.google.com/store/apps/details?id=$pkg")
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        }
        return false
    }

    /** Inbox messages newer than [since] (epoch millis), newest first. */
    private fun readSms(since: Long, limit: Int): List<Map<String, Any?>> {
        val out = ArrayList<Map<String, Any?>>()
        contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            arrayOf(Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE),
            "${Telephony.Sms.DATE} > ?",
            arrayOf(since.toString()),
            "${Telephony.Sms.DATE} DESC"
        )?.use { c ->
            val address = c.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
            val body = c.getColumnIndexOrThrow(Telephony.Sms.BODY)
            val date = c.getColumnIndexOrThrow(Telephony.Sms.DATE)
            while (c.moveToNext() && out.size < limit) {
                out.add(
                    mapOf(
                        "address" to c.getString(address),
                        "body" to c.getString(body),
                        "date" to c.getLong(date)
                    )
                )
            }
        }
        return out
    }
}
