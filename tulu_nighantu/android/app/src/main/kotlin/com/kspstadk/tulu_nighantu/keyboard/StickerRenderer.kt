package com.kspstadk.tulu_nighantu.keyboard

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import java.io.File
import java.io.FileOutputStream
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/** Draws Tulu lipi text as a sticker picture (red card, yellow letters). */
object StickerRenderer {
    private const val MAX_TEXT_WIDTH = 880
    private const val PADDING = 48f
    private const val TEXT_SIZE = 96f

    /** Renders [text] and returns a PNG file in the cache's stickers folder. */
    fun render(context: Context, text: String, face: Typeface): File {
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = face
            textSize = TEXT_SIZE
            color = Color.parseColor("#FFD54F")
        }
        val natural = ceil(Layout.getDesiredWidth(text, paint)).toInt()
        val width = max(1, min(natural, MAX_TEXT_WIDTH))
        val layout = staticLayout(text, paint, width)
        val w = (width + PADDING * 2).toInt().coerceAtLeast(160)
        val h = (layout.height + PADDING * 2).toInt()

        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val bg = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#B3261E") }
        canvas.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), 48f, 48f, bg)
        canvas.save()
        canvas.translate((w - width) / 2f, PADDING)
        layout.draw(canvas)
        canvas.restore()

        val dir = File(context.cacheDir, "stickers").apply { mkdirs() }
        dir.listFiles()?.forEach { if (it.lastModified() < System.currentTimeMillis() - DAY) it.delete() }
        val file = File(dir, "tulu_${System.currentTimeMillis()}.png")
        FileOutputStream(file).use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
        bmp.recycle()
        return file
    }

    private const val DAY = 24L * 60 * 60 * 1000

    @Suppress("DEPRECATION")
    private fun staticLayout(text: String, paint: TextPaint, width: Int): StaticLayout =
        if (Build.VERSION.SDK_INT >= 23) {
            StaticLayout.Builder.obtain(text, 0, text.length, paint, width)
                .setAlignment(Layout.Alignment.ALIGN_CENTER)
                .build()
        } else {
            StaticLayout(text, paint, width, Layout.Alignment.ALIGN_CENTER, 1f, 0f, false)
        }
}
