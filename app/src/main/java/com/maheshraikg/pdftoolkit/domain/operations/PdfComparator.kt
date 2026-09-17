package com.maheshraikg.pdftoolkit.domain.operations

import android.content.Context
import android.net.Uri
import com.tom_roush.pdfbox.io.MemoryUsageSetting
import com.tom_roush.pdfbox.pdmodel.PDDocument
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext

/**
 * A single line in the aligned diff output.
 * [pageA]/[pageB] are the 1-indexed source page numbers the line came from
 * in each document (null when the line doesn't exist on that side).
 */
data class DiffLine(
    val type: DiffType,
    val text: String,
    val pageA: Int?,
    val pageB: Int?
)

enum class DiffType { EQUAL, ADDED, REMOVED }

data class ComparisonResult(
    val pageCountA: Int,
    val pageCountB: Int,
    val lines: List<DiffLine>,
    val addedCount: Int,
    val removedCount: Int,
    /** True when the documents were too large for a full line-level diff and a coarser per-page comparison was used instead. */
    val usedCoarseFallback: Boolean
)

/**
 * Compares the extracted text of two PDFs and produces a line-level diff,
 * similar in spirit to a text diff tool. Reuses [TextExtractor] for the
 * actual PDF text extraction rather than duplicating PDFBox text-stripping
 * logic.
 */
class PdfComparator {

    // Safety cap on the LCS DP table (rows * cols) to avoid excessive memory/time
    // on very large documents. Above this, we fall back to a coarser per-page
    // whole-text comparison instead of a full line-level diff.
    private val MAX_LCS_CELLS = 2_250_000L // e.g. ~1500 x 1500

    suspend fun comparePdfs(
        context: Context,
        uriA: Uri,
        uriB: Uri,
        onProgress: (Float) -> Unit = {}
    ): Result<ComparisonResult> = withContext(Dispatchers.IO) {
        try {
            onProgress(0.05f)
            val pageCountA = countPages(context, uriA)
            val pageCountB = countPages(context, uriB)
            if (pageCountA == 0 || pageCountB == 0) {
                return@withContext Result.failure(IllegalStateException("One of the PDFs has no pages or could not be read"))
            }

            val extractor = TextExtractor()
            val linesA = extractLinesWithPages(extractor, context, uriA, pageCountA) { p -> onProgress(0.05f + p * 0.4f) }
            val linesB = extractLinesWithPages(extractor, context, uriB, pageCountB) { p -> onProgress(0.45f + p * 0.4f) }

            ensureActive()

            val cellCount = linesA.size.toLong() * linesB.size.toLong()
            val result = if (cellCount in 1..MAX_LCS_CELLS) {
                diffLines(linesA, linesB, pageCountA, pageCountB)
            } else {
                coarsePageDiff(context, extractor, uriA, uriB, pageCountA, pageCountB)
            }

            onProgress(1.0f)
            Result.success(result)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private fun countPages(context: Context, uri: Uri): Int {
        return try {
            context.contentResolver.openInputStream(uri)?.use { input ->
                PDDocument.load(input, MemoryUsageSetting.setupTempFileOnly()).use { it.numberOfPages }
            } ?: 0
        } catch (e: Exception) {
            0
        }
    }

    private suspend fun extractLinesWithPages(
        extractor: TextExtractor,
        context: Context,
        uri: Uri,
        pageCount: Int,
        onProgress: (Float) -> Unit
    ): List<Pair<String, Int>> {
        val lines = mutableListOf<Pair<String, Int>>()
        for (page in 1..pageCount) {
            currentCoroutineContext().ensureActive()
            val text = extractor.extractFromPage(context, uri, page)
            text.split("\n").forEach { rawLine ->
                val trimmed = rawLine.trimEnd()
                if (trimmed.isNotBlank()) {
                    lines.add(trimmed to page)
                }
            }
            onProgress(page.toFloat() / pageCount)
        }
        return lines
    }

    /**
     * Classic LCS-based line diff (like `diff`/`git diff`), producing an
     * ordered sequence of EQUAL/ADDED/REMOVED lines.
     */
    private suspend fun diffLines(
        a: List<Pair<String, Int>>,
        b: List<Pair<String, Int>>,
        pageCountA: Int,
        pageCountB: Int
    ): ComparisonResult {
        val n = a.size
        val m = b.size
        // dp[i][j] = length of LCS of a[i..n-1] and b[j..m-1]
        val dp = Array(n + 1) { IntArray(m + 1) }
        for (i in n - 1 downTo 0) {
            currentCoroutineContext().ensureActive()
            for (j in m - 1 downTo 0) {
                dp[i][j] = if (a[i].first == b[j].first) {
                    dp[i + 1][j + 1] + 1
                } else {
                    maxOf(dp[i + 1][j], dp[i][j + 1])
                }
            }
        }

        val result = mutableListOf<DiffLine>()
        var i = 0
        var j = 0
        var added = 0
        var removed = 0
        while (i < n && j < m) {
            currentCoroutineContext().ensureActive()
            when {
                a[i].first == b[j].first -> {
                    result.add(DiffLine(DiffType.EQUAL, a[i].first, a[i].second, b[j].second))
                    i++; j++
                }
                dp[i + 1][j] >= dp[i][j + 1] -> {
                    result.add(DiffLine(DiffType.REMOVED, a[i].first, a[i].second, null))
                    removed++
                    i++
                }
                else -> {
                    result.add(DiffLine(DiffType.ADDED, b[j].first, null, b[j].second))
                    added++
                    j++
                }
            }
        }
        while (i < n) {
            result.add(DiffLine(DiffType.REMOVED, a[i].first, a[i].second, null))
            removed++
            i++
        }
        while (j < m) {
            result.add(DiffLine(DiffType.ADDED, b[j].first, null, b[j].second))
            added++
            j++
        }

        return ComparisonResult(
            pageCountA = pageCountA,
            pageCountB = pageCountB,
            lines = result,
            addedCount = added,
            removedCount = removed,
            usedCoarseFallback = false
        )
    }

    /**
     * Fallback for very large documents: compares whole-page text instead of
     * individual lines, avoiding the O(n*m) cost of a full line-level diff.
     */
    private suspend fun coarsePageDiff(
        context: Context,
        extractor: TextExtractor,
        uriA: Uri,
        uriB: Uri,
        pageCountA: Int,
        pageCountB: Int
    ): ComparisonResult {
        val maxPages = maxOf(pageCountA, pageCountB)
        val lines = mutableListOf<DiffLine>()
        var added = 0
        var removed = 0
        for (page in 1..maxPages) {
            currentCoroutineContext().ensureActive()
            val textA = if (page <= pageCountA) extractor.extractFromPage(context, uriA, page).trim() else null
            val textB = if (page <= pageCountB) extractor.extractFromPage(context, uriB, page).trim() else null
            when {
                textA != null && textB != null && textA == textB -> {
                    lines.add(DiffLine(DiffType.EQUAL, "Page $page: identical", page, page))
                }
                textA != null && textB != null -> {
                    lines.add(DiffLine(DiffType.REMOVED, "Page $page (original): content differs", page, null))
                    lines.add(DiffLine(DiffType.ADDED, "Page $page (compared): content differs", null, page))
                    removed++
                    added++
                }
                textA != null -> {
                    lines.add(DiffLine(DiffType.REMOVED, "Page $page: only in original", page, null))
                    removed++
                }
                textB != null -> {
                    lines.add(DiffLine(DiffType.ADDED, "Page $page: only in compared PDF", null, page))
                    added++
                }
            }
        }
        return ComparisonResult(
            pageCountA = pageCountA,
            pageCountB = pageCountB,
            lines = lines,
            addedCount = added,
            removedCount = removed,
            usedCoarseFallback = true
        )
    }
}
