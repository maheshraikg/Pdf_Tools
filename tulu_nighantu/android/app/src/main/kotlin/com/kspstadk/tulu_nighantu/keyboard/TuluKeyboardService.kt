package com.kspstadk.tulu_nighantu.keyboard

import android.annotation.SuppressLint
import android.content.ClipDescription
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
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

/**
 * "Tulu Nighantu keyboard": a system keyboard for any app, this one included.
 *
 * It types straight into the text box like a normal keyboard. Tulu pages
 * show each letter in Tulu lipi with its Kannada letter underneath and type
 * the Kannada letter, which every phone can show and this app can search.
 * The strip at the top shows the message in Tulu lipi as you type; "Sticker"
 * sends it as a picture that everyone can see, and "Unicode" changes it to
 * Tulu-Tigalari Unicode for phones that have a Tulu font. There are also
 * ottakshara, English, number and emoji pages. Nothing typed is stored or
 * sent anywhere except into the app you are typing in.
 */
class TuluKeyboardService : InputMethodService() {

    private enum class Mode { TULU1, TULU2, OTTU, ENGLISH, SYMBOLS, EMOJI }

    private enum class Shift { OFF, ONCE, CAPS }

    private var mode = Mode.TULU1
    private var shift = Shift.OFF
    private var prefs = KeyboardPrefs()
    private var tulu: Typeface = Typeface.DEFAULT
    private lateinit var colors: Palette

    private lateinit var root: LinearLayout
    private lateinit var preview: TextView
    private lateinit var signScroll: HorizontalScrollView
    private lateinit var signRow: LinearLayout
    private lateinit var keyArea: LinearLayout
    private val tabViews = mutableListOf<Pair<Mode, TextView>>()
    private val ottuKeys = mutableListOf<TextView>()
    private val repeater = Handler(Looper.getMainLooper())

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
        signScroll = HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            addView(signRow)
        }
        root.addView(
            signScroll,
            LinearLayout.LayoutParams(MATCH, dp(SIGN_H + 4)).apply { topMargin = dp(2) },
        )
        root.addView(buildTabRow())
        // Same height on every page, so the keyboard does not jump.
        keyArea = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        root.addView(keyArea, LinearLayout.LayoutParams(MATCH, dp(KEY_H + 4) * KEY_ROWS))
        root.addView(buildBottomRow())
        buildKeys()
        return root
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        prefs = KeyboardPrefs.load(this)
        if (::root.isInitialized) {
            // Number and phone boxes open on the number page.
            val cls = (info?.inputType ?: 0) and EditorInfo.TYPE_MASK_CLASS
            if (cls == EditorInfo.TYPE_CLASS_NUMBER || cls == EditorInfo.TYPE_CLASS_PHONE) {
                mode = Mode.SYMBOLS
            } else if (mode == Mode.SYMBOLS) {
                mode = Mode.TULU1
            }
            buildKeys()
        }
    }

    override fun onUpdateSelection(
        oldSelStart: Int,
        oldSelEnd: Int,
        newSelStart: Int,
        newSelEnd: Int,
        candidatesStart: Int,
        candidatesEnd: Int,
    ) {
        super.onUpdateSelection(
            oldSelStart, oldSelEnd, newSelStart, newSelEnd, candidatesStart, candidatesEnd,
        )
        if (::root.isInitialized) refreshContext()
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        repeater.removeCallbacksAndMessages(null)
    }

    // ------------------------------------------------------------------ UI

    private fun buildTopBar(): View {
        val bar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        preview = TextView(this).apply {
            typeface = tulu
            setTextColor(colors.accentText)
            setSingleLine()
            ellipsize = TextUtils.TruncateAt.START
            setPadding(dp(12), dp(2), dp(8), dp(2))
            background = rounded(colors.accent, 14)
            gravity = Gravity.CENTER_VERTICAL
            minHeight = dp(44)
        }
        bar.addView(preview, LinearLayout.LayoutParams(0, WRAP, 1f))
        bar.addView(
            actionButton("ಸ್ಟಿಕ್ಕರ್\nSticker") { sendSticker() },
            LinearLayout.LayoutParams(WRAP, dp(44)).apply { leftMargin = dp(4) },
        )
        bar.addView(
            actionButton("ಯೂನಿಕೋಡ್\nUnicode") { convertToTuluUnicode() },
            LinearLayout.LayoutParams(WRAP, dp(44)).apply { leftMargin = dp(4) },
        )
        return bar
    }

    private fun buildTabRow(): View {
        val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        tabViews.clear()
        TABS.forEach { (m, label) ->
            val tab = plainKey(label, colors.special, 15f) {
                mode = m
                shift = Shift.OFF
                buildKeys()
            }
            tabViews += m to tab
            row.addView(
                tab,
                LinearLayout.LayoutParams(0, dp(36), 1f).apply { setMargins(dp(2), dp(2), dp(2), dp(2)) },
            )
        }
        return row
    }

    private fun buildBottomRow(): View {
        val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        row.addView(
            plainKey("🌐", colors.special) { switchKeyboard() }.apply {
                setOnLongClickListener {
                    imm().showInputMethodPicker()
                    true
                }
            },
            keyParams(1f, dp(KEY_H)),
        )
        row.addView(plainKey(",", colors.special) { commit(",") }, keyParams(0.8f, dp(KEY_H)))
        row.addView(
            plainKey("ತುಳು ನಿಘಂಟು", colors.key, 13f) { commit(" ") },
            keyParams(3.6f, dp(KEY_H)),
        )
        row.addView(plainKey(".", colors.special) { commit(".") }, keyParams(0.8f, dp(KEY_H)))
        row.addView(backspaceKey(), keyParams(1.3f, dp(KEY_H)))
        row.addView(plainKey("↵", colors.special) { enter() }, keyParams(1.3f, dp(KEY_H)))
        return row
    }

    /** Builds the keys of the current page. */
    private fun buildKeys() {
        keyArea.removeAllViews()
        ottuKeys.clear()
        val rows: List<List<String>> = when (mode) {
            Mode.TULU1 -> TULU1.chunked(7)
            Mode.TULU2 -> TULU2.chunked(7)
            Mode.OTTU -> CONSONANTS.chunked(9)
            Mode.ENGLISH -> ENGLISH
            Mode.SYMBOLS -> SYMBOLS
            Mode.EMOJI -> EMOJI.chunked(8)
        }
        val columns = rows.maxOf { it.size }
        rows.forEach { chunk ->
            val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            chunk.forEach { k -> row.addView(letterKey(k), keyParams(1f, MATCH)) }
            for (i in chunk.size until columns) row.addView(View(this), keyParams(1f, MATCH))
            keyArea.addView(row, LinearLayout.LayoutParams(MATCH, 0, 1f))
        }
        tabViews.forEach { (m, t) ->
            t.background = rounded(if (m == mode) colors.accent else colors.special, 10)
            t.setTextColor(if (m == mode) colors.accentText else colors.text)
        }
        refreshContext()
    }

    private fun letterKey(k: String): TextView = when (mode) {
        Mode.TULU1, Mode.TULU2 ->
            key(TuluEngine.fromKannada(k), k, colors.key) { commit(k) }
        Mode.OTTU -> key(TuluEngine.fromKannada("್$k"), "್$k", colors.key) {
            edit { TuluEngine.addOttu(it, k) }
        }.also { ottuKeys += it }
        Mode.ENGLISH -> if (k == SHIFT) shiftKey() else englishKey(k)
        Mode.SYMBOLS, Mode.EMOJI ->
            plainKey(k, colors.key, if (mode == Mode.EMOJI) 22f else 18f) { commit(k) }
    }

    private fun shiftKey(): TextView = plainKey(
        when (shift) {
            Shift.OFF -> "⇧"
            Shift.ONCE -> "⬆"
            Shift.CAPS -> "⇪"
        },
        if (shift == Shift.OFF) colors.special else colors.signKey,
        20f,
    ) {
        shift = when (shift) {
            Shift.OFF -> Shift.ONCE
            Shift.ONCE -> Shift.CAPS
            Shift.CAPS -> Shift.OFF
        }
        buildKeys()
    }

    private fun englishKey(k: String): TextView {
        val letter = if (shift != Shift.OFF) k.uppercase() else k
        return plainKey(letter, colors.key, 20f) {
            commit(letter)
            if (shift == Shift.ONCE) {
                shift = Shift.OFF
                buildKeys()
            }
        }
    }

    /** Updates the preview, the vowel-sign row and the ottakshara keys. */
    private fun refreshContext() {
        val before = textBefore(PREVIEW_CHARS)
        val lipi = if (TuluEngine.hasKannada(before)) TuluEngine.fromKannada(before).trim() else ""
        preview.text = if (lipi.isEmpty()) PLACEHOLDER else lipi
        preview.typeface = if (lipi.isEmpty()) Typeface.DEFAULT else tulu
        preview.setTextSize(TypedValue.COMPLEX_UNIT_SP, if (lipi.isEmpty()) 13f else 24f)

        // Gunitakshara: the last consonant with every vowel sign.
        signRow.removeAllViews()
        val tail = textBefore(EDIT_CHARS)
        val consonant = TuluEngine.lastConsonant(tail)
        for (sign in TuluEngine.VOWEL_SIGNS) {
            val enabled = consonant != null ||
                ((sign == "ಂ" || sign == "ಃ") && TuluEngine.applySign(tail, sign) != tail)
            val shown = (consonant ?: "") + sign
            val glyph = if (consonant == null) {
                "◌" + TuluEngine.fromKannada(sign)
            } else {
                TuluEngine.fromKannada(shown)
            }
            val v = key(glyph, shown, colors.signKey) {
                edit { TuluEngine.applySign(it, sign) }
            }
            v.alpha = if (enabled) 1f else 0.35f
            v.isEnabled = enabled
            signRow.addView(
                v,
                LinearLayout.LayoutParams(dp(46), dp(SIGN_H)).apply { setMargins(dp(2), dp(2), dp(2), dp(2)) },
            )
        }
        signScroll.visibility = if (mode in TULU_MODES) View.VISIBLE else View.INVISIBLE

        val canJoin = TuluEngine.addOttu(tail, "ಕ") != tail
        ottuKeys.forEach {
            it.alpha = if (canJoin) 1f else 0.35f
            it.isEnabled = canJoin
        }
    }

    /** A Tulu key: the Tulu glyph on top, the Kannada letter underneath. */
    private fun key(main: String, label: String, bg: Int, onTap: () -> Unit): TextView =
        TextView(this).apply {
            gravity = Gravity.CENTER
            setTextColor(colors.text)
            background = rounded(bg, 10)
            text = android.text.SpannableStringBuilder().apply {
                append(main)
                setSpan(TypefaceSpanCompat(tulu), 0, length, 0)
                append("\n")
                val start = length
                append(label)
                setSpan(android.text.style.RelativeSizeSpan(0.5f), start, length, 0)
                setSpan(android.text.style.ForegroundColorSpan(colors.subText), start, length, 0)
            }
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setLineSpacing(0f, 0.85f)
            isClickable = true
            setOnClickListener {
                feedback(it)
                onTap()
            }
        }

    private fun plainKey(text: String, bg: Int, size: Float = 18f, onTap: () -> Unit) =
        TextView(this).apply {
            this.text = text
            gravity = Gravity.CENTER
            setTextColor(colors.text)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, size)
            setSingleLine()
            background = rounded(bg, 10)
            isClickable = true
            setOnClickListener {
                feedback(it)
                onTap()
            }
        }

    /** ⌫ deletes one sign at a time and repeats while held. */
    @SuppressLint("ClickableViewAccessibility")
    private fun backspaceKey(): TextView = plainKey("⌫", colors.special) {}.apply {
        setOnClickListener(null)
        val again = object : Runnable {
            override fun run() {
                deleteOne()
                repeater.postDelayed(this, REPEAT_MS)
            }
        }
        setOnTouchListener { v, e ->
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    v.isPressed = true
                    feedback(v)
                    deleteOne()
                    repeater.postDelayed(again, REPEAT_START_MS)
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    v.isPressed = false
                    repeater.removeCallbacks(again)
                }
            }
            true
        }
    }

    /** Key click sound and vibration, as chosen in the app. */
    private fun feedback(v: View) {
        if (prefs.vibrate) {
            v.performHapticFeedback(
                android.view.HapticFeedbackConstants.KEYBOARD_TAP,
                android.view.HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING,
            )
        }
        if (prefs.sound) {
            (getSystemService(Context.AUDIO_SERVICE) as AudioManager)
                .playSoundEffect(AudioManager.FX_KEYPRESS_STANDARD, 1f)
        }
    }

    private fun actionButton(text: String, onTap: () -> Unit) = TextView(this).apply {
        this.text = text
        gravity = Gravity.CENTER
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
        setTextColor(colors.accentText)
        background = rounded(colors.action, 14)
        setPadding(dp(10), 0, dp(10), 0)
        setOnClickListener {
            feedback(it)
            onTap()
        }
    }

    private fun keyParams(weight: Float, height: Int) =
        LinearLayout.LayoutParams(0, height, weight).apply { setMargins(dp(2), dp(2), dp(2), dp(2)) }

    // -------------------------------------------------------------- typing

    private fun textBefore(n: Int): String =
        currentInputConnection?.getTextBeforeCursor(n, 0)?.toString() ?: ""

    private fun commit(text: String) {
        currentInputConnection?.commitText(text, 1)
    }

    /** Rewrites the end of the text before the cursor (vowel signs, ottu). */
    private fun edit(transform: (String) -> String) {
        val ic = currentInputConnection ?: return
        val before = ic.getTextBeforeCursor(EDIT_CHARS, 0)?.toString() ?: return
        val (delete, insert) = TuluEngine.diff(before, transform(before))
        if (delete == 0 && insert.isEmpty()) return
        ic.beginBatchEdit()
        if (delete > 0) ic.deleteSurroundingText(delete, 0)
        if (insert.isNotEmpty()) ic.commitText(insert, 1)
        ic.endBatchEdit()
    }

    private fun deleteOne() {
        val ic = currentInputConnection ?: return
        val selected = ic.getSelectedText(0)
        val last = ic.getTextBeforeCursor(1, 0)
        if (selected.isNullOrEmpty() && !last.isNullOrEmpty() && TuluEngine.isKannada(last[0])) {
            // One sign at a time (ಕಾ → ಕ), like Kannada keyboards.
            ic.deleteSurroundingText(1, 0)
        } else {
            sendDownUpKeyEvents(KeyEvent.KEYCODE_DEL)
        }
    }

    private fun enter() {
        val info = currentInputEditorInfo
        val action = info?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) ?: EditorInfo.IME_ACTION_NONE
        val noEnterAction = info != null && (info.imeOptions and EditorInfo.IME_FLAG_NO_ENTER_ACTION) != 0
        val multiLine = info != null && (info.inputType and EditorInfo.TYPE_TEXT_FLAG_MULTI_LINE) != 0
        if (!multiLine && action != EditorInfo.IME_ACTION_NONE &&
            action != EditorInfo.IME_ACTION_UNSPECIFIED && !noEnterAction
        ) {
            currentInputConnection?.performEditorAction(action)
        } else {
            sendDownUpKeyEvents(KeyEvent.KEYCODE_ENTER)
        }
    }

    /** Replaces the Kannada message with Tulu-Tigalari Unicode letters. */
    private fun convertToTuluUnicode() {
        if (!TuluEngine.hasKannada(textBefore(STICKER_CHARS))) {
            toast("ಮೊದಲು ಬರೆಯಿರಿ · Type something first")
            return
        }
        val ic = currentInputConnection ?: return
        val before = ic.getTextBeforeCursor(STICKER_CHARS, 0)?.toString() ?: return
        val (delete, insert) = TuluEngine.diff(before, TuluEngine.fromKannada(before))
        ic.beginBatchEdit()
        if (delete > 0) ic.deleteSurroundingText(delete, 0)
        if (insert.isNotEmpty()) ic.commitText(insert, 1)
        ic.endBatchEdit()
        toast("Tulu Unicode – shows only on phones with a Tulu font")
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

    /** Sends the message as a Tulu lipi picture and clears it from the box. */
    private fun sendSticker() {
        val message = textBefore(STICKER_CHARS)
        if (!TuluEngine.hasKannada(message)) {
            toast("ಮೊದಲು ಬರೆಯಿರಿ · Type something first")
            return
        }
        val lipi = TuluEngine.fromKannada(message).trim()
        val file = try {
            StickerRenderer.render(this, lipi, tulu, prefs.stickerLabel)
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
        if (sent) {
            // The message went as a picture: remove the typed text.
            if (textBefore(message.length) == message) ic?.deleteSurroundingText(message.length, 0)
        } else {
            shareSticker(uri, info?.packageName)
        }
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
            toast("This app cannot receive pictures")
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

    companion object {
        /** The Flutter app's Tulu font inside the APK. */
        const val FONT_ASSET = "flutter_assets/assets/fonts/mallige_v1.4.ttf"
        private const val PNG = "image/png"
        private const val KEY_H = 50
        private const val SIGN_H = 50
        private const val KEY_ROWS = 4
        private const val PREVIEW_CHARS = 200
        private const val EDIT_CHARS = 16
        private const val STICKER_CHARS = 1000
        private const val REPEAT_START_MS = 400L
        private const val REPEAT_MS = 60L
        private const val SHIFT = "⇧"
        private const val MATCH = LinearLayout.LayoutParams.MATCH_PARENT
        private const val WRAP = LinearLayout.LayoutParams.WRAP_CONTENT
        private const val PLACEHOLDER = "ತುಳು ಲಿಪಿ ಇಲ್ಲಿ ಕಾಣುತ್ತದೆ · Tulu lipi shows here"

        private val TULU_MODES = setOf(Mode.TULU1, Mode.TULU2, Mode.OTTU)

        private val TABS = listOf(
            Mode.TULU1 to "ಅ ಕ",
            Mode.TULU2 to "ತ ಯ",
            Mode.OTTU to "್ಕ",
            Mode.ENGLISH to "ABC",
            Mode.SYMBOLS to "?123",
            Mode.EMOJI to "😊",
        )

        /** Vowels and the first consonants (4 rows of 7). */
        val TULU1 = (
            "ಅ ಆ ಇ ಈ ಉ ಊ ಋ ಎ ಏ ಐ ಒ ಓ ಔ ಅಂ " +
                "ಕ ಖ ಗ ಘ ಙ ಚ ಛ ಜ ಝ ಞ ಟ ಠ ಡ ಢ"
            ).split(" ")

        /** The other consonants, rarer letters and common joined letters. */
        val TULU2 = (
            "ಣ ತ ಥ ದ ಧ ನ ಪ ಫ ಬ ಭ ಮ ಯ ರ ಲ ವ ಶ ಷ ಸ ಹ ಳ ಱ " +
                "ೞ ಕ್ಷ ಜ್ಞ ತ್ರ ಶ್ರೀ ಓಂ ೠ"
            ).split(" ")

        /** Ottakshara page: joins a consonant to the one before (ಕ + ್ತ → ಕ್ತ). */
        val CONSONANTS = (
            "ಕ ಖ ಗ ಘ ಙ ಚ ಛ ಜ ಝ ಞ ಟ ಠ ಡ ಢ ಣ ತ ಥ ದ ಧ ನ " +
                "ಪ ಫ ಬ ಭ ಮ ಯ ರ ಲ ವ ಶ ಷ ಸ ಹ ಳ"
            ).split(" ")

        private val ENGLISH = listOf(
            "q w e r t y u i o p".split(" "),
            "a s d f g h j k l".split(" "),
            "$SHIFT z x c v b n m".split(" "),
            "' - ? ! @ : ; /".split(" "),
        )

        private val SYMBOLS = listOf(
            "1 2 3 4 5 6 7 8 9 0".split(" "),
            "೧ ೨ ೩ ೪ ೫ ೬ ೭ ೮ ೯ ೦".split(" "),
            "@ # ₹ & - + ( ) / _".split(" "),
            "* \" ' : ; ! ? % = ।".split(" "),
        )

        private val EMOJI = (
            "😀 😂 🥰 😍 😊 😉 😎 🤔 😢 😭 😡 🙏 👍 👌 👏 🙌 " +
                "❤️ 💛 🧡 🔥 ✨ 🎉 🌺 🌸 🌴 🥥 🐯 🐄 🌾 🍚 ☕ 🏠"
            ).split(" ")
    }
}
