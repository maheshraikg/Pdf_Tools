package com.kspstadk.tulu_nighantu.keyboard

import android.content.ClipDescription
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.FileProvider
import androidx.core.view.inputmethod.EditorInfoCompat
import androidx.core.view.inputmethod.InputConnectionCompat
import androidx.core.view.inputmethod.InputContentInfoCompat
import java.io.File

/**
 * "Tulu Nighantu keyboard": a system keyboard for typing Tulu lipi in any app.
 *
 * Keys are Tulu-Tigalari letters (with their Kannada letter underneath).
 * What you type is kept in the strip at the top, drawn with the app's Tulu
 * font, and sent either as a sticker picture (visible on every phone) or as
 * Unicode text (for phones that have a Tulu-Tigalari font). Nothing typed is
 * stored or sent anywhere except into the app you are typing in.
 */
class TuluKeyboardService : InputMethodService() {

    private var buffer = ""
    private var page = 1
    private var tulu: Typeface = Typeface.DEFAULT
    private lateinit var colors: Palette

    private lateinit var root: LinearLayout
    private lateinit var preview: TextView
    private lateinit var signRow: LinearLayout
    private lateinit var keyArea: LinearLayout
    private val tabViews = mutableListOf<TextView>()

    override fun onCreate() {
        super.onCreate()
        tulu = try {
            Typeface.createFromAsset(assets, FONT_ASSET)
        } catch (e: RuntimeException) {
            Typeface.DEFAULT
        }
    }

    override fun onCreateInputView(): View {
        colors = Palette.of(this)
        root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(colors.background)
            setPadding(dp(4), dp(4), dp(4), dp(6))
        }
        root.addView(buildTopBar())
        signRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        root.addView(
            HorizontalScrollView(this).apply {
                isHorizontalScrollBarEnabled = false
                addView(signRow)
            },
            LinearLayout.LayoutParams(MATCH, WRAP).apply { topMargin = dp(2) },
        )
        keyArea = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        root.addView(keyArea)
        root.addView(buildBottomRow())
        refresh()
        return root
    }

    override fun onStartInput(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInput(attribute, restarting)
        if (!restarting) buffer = ""
        if (::root.isInitialized) refresh()
    }

    // ------------------------------------------------------------------ UI

    private fun buildTopBar(): View {
        val bar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        preview = TextView(this).apply {
            typeface = tulu
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 26f)
            setTextColor(colors.accentText)
            setSingleLine()
            ellipsize = TextUtils.TruncateAt.START
            setPadding(dp(12), dp(2), dp(8), dp(2))
            background = rounded(colors.accent, 14)
            gravity = Gravity.CENTER_VERTICAL
            minHeight = dp(46)
        }
        bar.addView(preview, LinearLayout.LayoutParams(0, WRAP, 1f))
        bar.addView(
            actionButton("ಸ್ಟಿಕ್ಕರ್\nSticker") { sendSticker() },
            LinearLayout.LayoutParams(WRAP, dp(46)).apply { leftMargin = dp(4) },
        )
        bar.addView(
            actionButton("ಪಠ್ಯ\nText") { commitBufferAsText() },
            LinearLayout.LayoutParams(WRAP, dp(46)).apply { leftMargin = dp(4) },
        )
        return bar
    }

    private fun buildBottomRow(): View {
        val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        row.addView(
            key("🌐", null, colors.special) { switchKeyboard() }.apply {
                setOnLongClickListener {
                    imm().showInputMethodPicker()
                    true
                }
            },
            keyParams(0.9f),
        )
        tabViews.clear()
        PAGES.forEachIndexed { i, p ->
            val tab = key(p.tab, null, colors.special) {
                page = i
                refresh()
            }
            tabViews += tab
            row.addView(tab, keyParams(0.9f))
        }
        row.addView(key("␣", null, colors.key) { typeSpace() }, keyParams(2.2f))
        row.addView(
            key("⌫", null, colors.special) { deleteOne() }.apply {
                setOnLongClickListener {
                    buffer = ""
                    refresh()
                    true
                }
            },
            keyParams(1.1f),
        )
        row.addView(key("↵", null, colors.special) { enter() }, keyParams(1.1f))
        return row
    }

    private fun refresh() {
        val lipi = TuluEngine.fromKannada(buffer)
        preview.text = if (lipi.isEmpty()) PLACEHOLDER else lipi
        preview.typeface = if (lipi.isEmpty()) Typeface.DEFAULT else tulu
        preview.setTextSize(TypedValue.COMPLEX_UNIT_SP, if (lipi.isEmpty()) 14f else 26f)

        signRow.removeAllViews()
        val consonant = TuluEngine.lastConsonant(buffer)
        for (sign in TuluEngine.VOWEL_SIGNS) {
            val enabled = consonant != null ||
                ((sign == "ಂ" || sign == "ಃ") && buffer.isNotEmpty())
            val shown = (consonant ?: "") + sign
            val v = key(
                if (consonant == null) "◌" + TuluEngine.fromKannada(sign) else TuluEngine.fromKannada(shown),
                shown,
                colors.signKey,
                tuluGlyph = true,
            ) {
                buffer = TuluEngine.applySign(buffer, sign)
                refresh()
            }
            v.alpha = if (enabled) 1f else 0.35f
            v.isEnabled = enabled
            signRow.addView(v, LinearLayout.LayoutParams(dp(46), dp(52)).apply { setMargins(dp(2), dp(2), dp(2), dp(2)) })
        }

        keyArea.removeAllViews()
        val letters = PAGES[page].letters
        letters.chunked(COLUMNS).forEach { chunk ->
            val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            chunk.forEach { k ->
                row.addView(
                    key(TuluEngine.fromKannada(k), k, colors.key, tuluGlyph = true) {
                        buffer += k
                        refresh()
                    },
                    keyParams(1f),
                )
            }
            repeat(COLUMNS - chunk.size) { row.addView(View(this), keyParams(1f)) }
            keyArea.addView(row)
        }
        tabViews.forEachIndexed { i, t ->
            t.background = rounded(if (i == page) colors.accent else colors.special, 10)
            t.setTextColor(if (i == page) colors.accentText else colors.text)
        }
    }

    private fun key(
        main: String,
        label: String?,
        bg: Int,
        tuluGlyph: Boolean = false,
        onTap: () -> Unit,
    ): TextView = TextView(this).apply {
        gravity = Gravity.CENTER
        setTextColor(colors.text)
        background = rounded(bg, 10)
        if (label == null) {
            text = main
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
        } else {
            // Glyph on top, Kannada letter underneath.
            text = android.text.SpannableStringBuilder().apply {
                append(main)
                setSpan(
                    android.text.style.RelativeSizeSpan(1f),
                    0,
                    length,
                    0,
                )
                if (tuluGlyph) {
                    setSpan(TypefaceSpanCompat(tulu), 0, length, 0)
                }
                append("\n")
                val start = length
                append(label)
                setSpan(android.text.style.RelativeSizeSpan(0.5f), start, length, 0)
                setSpan(
                    android.text.style.ForegroundColorSpan(colors.subText),
                    start,
                    length,
                    0,
                )
            }
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setLineSpacing(0f, 0.85f)
        }
        isClickable = true
        isHapticFeedbackEnabled = true
        setOnClickListener {
            it.performHapticFeedback(android.view.HapticFeedbackConstants.KEYBOARD_TAP)
            onTap()
        }
    }

    private fun actionButton(text: String, onTap: () -> Unit) = TextView(this).apply {
        this.text = text
        gravity = Gravity.CENTER
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
        setTextColor(colors.accentText)
        background = rounded(colors.action, 14)
        setPadding(dp(10), 0, dp(10), 0)
        setOnClickListener { onTap() }
    }

    private fun keyParams(weight: Float) =
        LinearLayout.LayoutParams(0, dp(52), weight).apply { setMargins(dp(2), dp(2), dp(2), dp(2)) }

    // -------------------------------------------------------------- actions

    private fun typeSpace() {
        if (buffer.isNotEmpty()) {
            buffer += " "
            refresh()
        } else {
            currentInputConnection?.commitText(" ", 1)
        }
    }

    private fun deleteOne() {
        if (buffer.isNotEmpty()) {
            buffer = TuluEngine.backspace(buffer)
            refresh()
        } else {
            // Lets the app delete a whole character (Tulu letters use two
            // UTF-16 units).
            sendDownUpKeyEvents(KeyEvent.KEYCODE_DEL)
        }
    }

    private fun enter() {
        if (buffer.isNotEmpty()) {
            commitBufferAsText()
            return
        }
        val info = currentInputEditorInfo
        val action = info?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) ?: EditorInfo.IME_ACTION_NONE
        val noEnterAction = info != null && (info.imeOptions and EditorInfo.IME_FLAG_NO_ENTER_ACTION) != 0
        if (action != EditorInfo.IME_ACTION_NONE && action != EditorInfo.IME_ACTION_UNSPECIFIED && !noEnterAction) {
            currentInputConnection?.performEditorAction(action)
        } else {
            sendDownUpKeyEvents(KeyEvent.KEYCODE_ENTER)
        }
    }

    private fun commitBufferAsText() {
        if (buffer.isEmpty()) return
        currentInputConnection?.commitText(TuluEngine.fromKannada(buffer), 1)
        buffer = ""
        refresh()
    }

    private fun switchKeyboard() {
        val switched = if (Build.VERSION.SDK_INT >= 28) {
            switchToNextInputMethod(false)
        } else {
            false
        }
        if (!switched) imm().showInputMethodPicker()
    }

    private fun imm() = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager

    // ------------------------------------------------------------- stickers

    private fun sendSticker() {
        val lipi = TuluEngine.fromKannada(buffer).trim()
        if (lipi.isEmpty()) {
            toast("ಮೊದಲು ಬರೆಯಿರಿ · Type something first")
            return
        }
        val file = try {
            StickerRenderer.render(this, lipi, tulu)
        } catch (e: Exception) {
            toast("Could not make the sticker")
            return
        }
        val uri = FileProvider.getUriForFile(this, "$packageName.keyboard.files", file)
        val info = currentInputEditorInfo
        val ic = currentInputConnection
        val accepts = info != null && EditorInfoCompat.getContentMimeTypes(info).any {
            ClipDescription.compareMimeTypes(PNG, it)
        }
        var sent = false
        if (accepts && ic != null) {
            var flags = 0
            if (Build.VERSION.SDK_INT >= 25) {
                flags = InputConnectionCompat.INPUT_CONTENT_GRANT_READ_URI_PERMISSION
            } else {
                grantUriPermission(info!!.packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val content = InputContentInfoCompat(
                uri,
                ClipDescription("Tulu lipi", arrayOf(PNG)),
                null,
            )
            sent = InputConnectionCompat.commitContent(ic, info!!, content, flags, null)
        }
        if (!sent) shareSticker(uri, info?.packageName)
        buffer = ""
        refresh()
    }

    /** For apps that do not accept stickers from keyboards: open the share sheet. */
    private fun shareSticker(uri: android.net.Uri, targetPackage: String?) {
        val send = Intent(Intent.ACTION_SEND).apply {
            type = PNG
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val direct = targetPackage?.let { Intent(send).setPackage(it) }
        try {
            if (direct != null && direct.resolveActivity(packageManager) != null) {
                startActivity(direct)
            } else {
                startActivity(
                    Intent.createChooser(send, "ತುಳು ಸ್ಟಿಕ್ಕರ್ · Tulu sticker")
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
            }
        } catch (e: Exception) {
            toast("This app cannot receive pictures. Use “Text” instead.")
        }
    }

    // --------------------------------------------------------------- helpers

    private fun toast(msg: String) = Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    private fun rounded(color: Int, radiusDp: Int) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(radiusDp).toFloat()
    }

    /** Light/dark colours matching the app (red #B3261E, yellow #FFD54F). */
    private data class Palette(
        val background: Int,
        val key: Int,
        val signKey: Int,
        val special: Int,
        val text: Int,
        val subText: Int,
        val accent: Int,
        val accentText: Int,
        val action: Int,
    ) {
        companion object {
            fun of(c: Context): Palette {
                val dark = (c.resources.configuration.uiMode and
                    Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
                return if (dark) {
                    Palette(
                        background = Color.parseColor("#1E1514"),
                        key = Color.parseColor("#3A2E2C"),
                        signKey = Color.parseColor("#4A3B00"),
                        special = Color.parseColor("#2C2220"),
                        text = Color.parseColor("#F5DDDA"),
                        subText = Color.parseColor("#C9AFAB"),
                        accent = Color.parseColor("#7A1410"),
                        accentText = Color.parseColor("#FFD54F"),
                        action = Color.parseColor("#B3261E"),
                    )
                } else {
                    Palette(
                        background = Color.parseColor("#FBEAE7"),
                        key = Color.WHITE,
                        signKey = Color.parseColor("#FFF3C4"),
                        special = Color.parseColor("#F3D9D5"),
                        text = Color.parseColor("#231917"),
                        subText = Color.parseColor("#775652"),
                        accent = Color.parseColor("#B3261E"),
                        accentText = Color.parseColor("#FFD54F"),
                        action = Color.parseColor("#7A1410"),
                    )
                }
            }
        }
    }

    /** A per-character typeface (TypefaceSpan(Typeface) needs API 28). */
    private class TypefaceSpanCompat(private val face: Typeface) :
        android.text.style.MetricAffectingSpan() {
        override fun updateDrawState(tp: android.text.TextPaint) {
            tp.typeface = face
        }

        override fun updateMeasureState(tp: android.text.TextPaint) {
            tp.typeface = face
        }
    }

    private class Page(val tab: String, val letters: List<String>)

    companion object {
        /** The Flutter app's Tulu font inside the APK. */
        const val FONT_ASSET = "flutter_assets/assets/fonts/mallige_v1.4.ttf"
        private const val PNG = "image/png"
        private const val COLUMNS = 7
        private const val MATCH = LinearLayout.LayoutParams.MATCH_PARENT
        private const val WRAP = LinearLayout.LayoutParams.WRAP_CONTENT
        private const val PLACEHOLDER = "ತುಳು ಲಿಪಿಯಲ್ಲಿ ಬರೆಯಿರಿ · Type Tulu lipi"

        private val PAGES = listOf(
            Page("ಅ", "ಅ ಆ ಇ ಈ ಉ ಊ ಋ ಎ ಏ ಐ ಒ ಓ ಔ".split(" ")),
            Page("ಕ", "ಕ ಖ ಗ ಘ ಙ ಚ ಛ ಜ ಝ ಞ".split(" ")),
            Page("ಟ", "ಟ ಠ ಡ ಢ ಣ ತ ಥ ದ ಧ ನ".split(" ")),
            Page("ಪ", "ಪ ಫ ಬ ಭ ಮ ಯ ರ ಲ ವ ಶ ಷ ಸ ಹ ಳ".split(" ")),
        )
    }
}
