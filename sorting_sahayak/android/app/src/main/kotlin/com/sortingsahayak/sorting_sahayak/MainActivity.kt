package com.sortingsahayak.sorting_sahayak

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import android.media.ExifInterface
import android.os.Handler
import android.os.Looper
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

/**
 * Kannada text recognition with Tesseract (offline, bundled `kan` model).
 * ML Kit has no Kannada model, so the scan screen sends camera frames and
 * captured photos here. Nothing is stored: images are only held in memory.
 */
class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var tess: TessBaseAPI? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "po_sorting/kannada_ocr").setMethodCallHandler { call, result ->
            when (call.method) {
                "readFile" -> {
                    val path = call.argument<String>("path")!!
                    run(result) { loadFile(path) }
                }
                "readNv21" -> {
                    val stride = call.argument<Int>("stride") ?: 0
                    val bytes = call.argument<ByteArray>("bytes")!!
                    val width = call.argument<Int>("width")!!
                    val height = call.argument<Int>("height")!!
                    val rotation = call.argument<Int>("rotation") ?: 0
                    run(result) { nv21ToBitmap(bytes, width, height, stride, rotation) }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun run(result: MethodChannel.Result, image: () -> Bitmap?) {
        worker.execute {
            try {
                val bmp = image()
                val text = if (bmp == null) "" else recognise(bmp).also { bmp.recycle() }
                main.post { result.success(text) }
            } catch (e: Throwable) {
                main.post { result.error("ocr", e.message, null) }
            }
        }
    }

    private fun engine(): TessBaseAPI {
        tess?.let { return it }
        val root = File(filesDir, "tesseract")
        val data = File(root, "tessdata/kan.traineddata")
        if (!data.exists() || data.length() == 0L) {
            data.parentFile!!.mkdirs()
            val tmp = File(data.path + ".tmp")
            assets.open("tessdata/kan.traineddata").use { input -> tmp.outputStream().use { input.copyTo(it) } }
            tmp.renameTo(data)
        }
        val api = TessBaseAPI()
        if (!api.init(root.absolutePath, "kan")) {
            api.recycle()
            throw IllegalStateException("Kannada model could not be loaded")
        }
        api.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO)
        api.setVariable("user_defined_dpi", "300")
        tess = api
        return api
    }

    private fun recognise(bmp: Bitmap): String {
        val api = engine()
        api.setImage(bmp)
        val text = api.getUTF8Text() ?: ""
        api.clear()
        return text
    }

    /** Loads a captured photo, at most ~2000 px, upright per its EXIF. */
    private fun loadFile(path: String): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 2000) sample *= 2
        val bmp = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample }) ?: return null
        val degrees = when (ExifInterface(path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90
            ExifInterface.ORIENTATION_ROTATE_180 -> 180
            ExifInterface.ORIENTATION_ROTATE_270 -> 270
            else -> 0
        }
        return rotate(bmp, degrees)
    }

    private fun nv21ToBitmap(bytes: ByteArray, width: Int, height: Int, stride: Int, rotation: Int): Bitmap? {
        val strides = if (stride > 0) intArrayOf(stride, stride) else null
        val out = ByteArrayOutputStream()
        YuvImage(bytes, ImageFormat.NV21, width, height, strides).compressToJpeg(Rect(0, 0, width, height), 90, out)
        val jpeg = out.toByteArray()
        val bmp = BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size) ?: return null
        return rotate(bmp, rotation)
    }

    private fun rotate(bmp: Bitmap, degrees: Int): Bitmap {
        if (degrees == 0) return bmp
        val m = Matrix().apply { postRotate(degrees.toFloat()) }
        val r = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, m, true)
        if (r != bmp) bmp.recycle()
        return r
    }

    override fun onDestroy() {
        worker.execute {
            tess?.recycle()
            tess = null
        }
        worker.shutdown()
        super.onDestroy()
    }
}
