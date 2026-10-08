package com.kspstadk.tulu_nighantu

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import com.kspstadk.tulu_nighantu.keyboard.KeyboardPrefs
import com.kspstadk.tulu_nighantu.keyboard.TuluKeyboardService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets the Flutter UI guide the user through turning on the
        // system keyboard (lib/screens/tulu_keyboard_screen.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tulu_nighantu/keyboard")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(
                        mapOf("enabled" to isEnabled(), "selected" to isSelected()),
                    )
                    "openSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(null)
                    }
                    "getPrefs" -> result.success(KeyboardPrefs.load(this).toMap())
                    "setPrefs" -> {
                        val m = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                        val p = KeyboardPrefs.fromMap(m, KeyboardPrefs.load(this))
                        p.save(this)
                        result.success(p.toMap())
                    }
                    "showPicker" -> {
                        imm().showInputMethodPicker()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun imm() = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager

    private val component = ComponentName(
        "com.kspstadk.tulu_nighantu",
        TuluKeyboardService::class.java.name,
    )

    private fun isEnabled(): Boolean = imm().enabledInputMethodList.any {
        it.packageName == packageName && it.serviceName == TuluKeyboardService::class.java.name
    }

    private fun isSelected(): Boolean {
        val current = Settings.Secure.getString(contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD)
            ?: return false
        return ComponentName.unflattenFromString(current)?.let {
            it.packageName == packageName && it.className == component.className
        } ?: false
    }
}
