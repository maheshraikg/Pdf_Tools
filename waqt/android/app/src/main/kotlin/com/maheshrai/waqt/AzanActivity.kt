package com.maheshrai.waqt

import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Full-screen Azan, shown over the lock screen like an alarm clock: the
 * prayer, its time and place, and a big Stop button. Volume keys stop the
 * sound too.
 */
class AzanActivity : Activity() {
    private val finished = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = finish()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val title = intent.getStringExtra(EXTRA_TITLE) ?: ""
        val body = intent.getStringExtra(EXTRA_BODY) ?: ""
        setContentView(buildView(title, body))

        val filter = IntentFilter(ACTION_FINISHED)
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(finished, filter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(finished, filter)
        }
    }

    override fun onDestroy() {
        unregisterReceiver(finished)
        super.onDestroy()
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            AzanService.stop(this)
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun dp(v: Float) =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, resources.displayMetrics)

    private fun buildView(title: String, body: String): LinearLayout {
        val gold = Color.rgb(0xE2, 0xB8, 0x4B)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(32f).toInt(), dp(48f).toInt(), dp(32f).toInt(), dp(48f).toInt())
            background = GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                intArrayOf(Color.rgb(0x02, 0x23, 0x1B), Color.rgb(0x07, 0x40, 0x2F), Color.rgb(0x0B, 0x5A, 0x48)),
            )
        }
        val icon = ImageView(this).apply {
            setImageResource(R.mipmap.ic_launcher)
            layoutParams = LinearLayout.LayoutParams(dp(96f).toInt(), dp(96f).toInt()).apply {
                bottomMargin = dp(28f).toInt()
            }
        }
        val titleView = TextView(this).apply {
            text = title
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 34f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        val bodyView = TextView(this).apply {
            text = body
            setTextColor(gold)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            gravity = Gravity.CENTER
            setPadding(0, dp(12f).toInt(), 0, dp(56f).toInt())
        }
        val stop = Button(this).apply {
            text = AzanScheduler.stopLabel(this@AzanActivity)
            setTextColor(Color.rgb(0x05, 0x3B, 0x2D))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            typeface = Typeface.DEFAULT_BOLD
            isAllCaps = false
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(gold)
            }
            val size = dp(150f).toInt()
            layoutParams = LinearLayout.LayoutParams(size, size)
            setOnClickListener {
                AzanService.stop(this@AzanActivity)
                dismissKeyguardAndFinish()
            }
        }
        root.addView(icon)
        root.addView(titleView)
        root.addView(bodyView)
        root.addView(stop)
        return root
    }

    private fun dismissKeyguardAndFinish() {
        // Just close; the lock screen stays locked.
        val km = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
        if (!km.isKeyguardLocked) {
            startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
        finish()
    }

    companion object {
        const val ACTION_FINISHED = "com.maheshrai.waqt.AZAN_FINISHED"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_BODY = "body"

        fun intent(context: Context, title: String, body: String): Intent =
            Intent(context, AzanActivity::class.java)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_BODY, body)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION)
    }
}
