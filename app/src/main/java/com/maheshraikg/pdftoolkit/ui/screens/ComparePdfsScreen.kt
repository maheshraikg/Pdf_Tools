package com.maheshraikg.pdftoolkit.ui.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.maheshraikg.pdftoolkit.R
import com.maheshraikg.pdftoolkit.data.FileManager
import com.maheshraikg.pdftoolkit.domain.operations.ComparisonResult
import com.maheshraikg.pdftoolkit.domain.operations.DiffLine
import com.maheshraikg.pdftoolkit.domain.operations.DiffType
import com.maheshraikg.pdftoolkit.domain.operations.PdfComparator
import com.maheshraikg.pdftoolkit.ui.components.ToolTopBar
import kotlinx.coroutines.launch

private data class PickedFile(val uri: Uri, val name: String)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ComparePdfsScreen(onNavigateBack: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var fileA by remember { mutableStateOf<PickedFile?>(null) }
    var fileB by remember { mutableStateOf<PickedFile?>(null) }
    var isComparing by remember { mutableStateOf(false) }
    var progress by remember { mutableStateOf(0f) }
    var result by remember { mutableStateOf<ComparisonResult?>(null) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val pickerA = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        uri?.let {
            fileA = PickedFile(it, FileManager.getFileInfo(context, it)?.name ?: it.lastPathSegment ?: "PDF")
            result = null
            errorMessage = null
        }
    }
    val pickerB = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        uri?.let {
            fileB = PickedFile(it, FileManager.getFileInfo(context, it)?.name ?: it.lastPathSegment ?: "PDF")
            result = null
            errorMessage = null
        }
    }

    suspend fun runCompare() {
        val a = fileA ?: return
        val b = fileB ?: return
        isComparing = true
        errorMessage = null
        progress = 0f
        val outcome = PdfComparator().comparePdfs(context, a.uri, b.uri) { p -> progress = p }
        outcome.onSuccess { result = it }
        outcome.onFailure { errorMessage = it.message ?: "Comparison failed" }
        isComparing = false
    }

    Scaffold(
        topBar = { ToolTopBar(title = stringResource(R.string.compare_title), onNavigateBack = onNavigateBack) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Text(
                    text = stringResource(R.string.compare_subtitle),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            item {
                FilePickerRow(
                    label = stringResource(R.string.compare_original_pdf),
                    file = fileA,
                    enabled = !isComparing,
                    onPick = { pickerA.launch(arrayOf("application/pdf")) }
                )
            }
            item {
                FilePickerRow(
                    label = stringResource(R.string.compare_second_pdf),
                    file = fileB,
                    enabled = !isComparing,
                    onPick = { pickerB.launch(arrayOf("application/pdf")) }
                )
            }

            item {
                Button(
                    onClick = { scope.launch { runCompare() } },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isComparing && fileA != null && fileB != null
                ) {
                    if (isComparing) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(18.dp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            strokeWidth = 2.dp
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(stringResource(R.string.compare_comparing))
                    } else {
                        Text(stringResource(R.string.compare_start))
                    }
                }
            }

            if (isComparing) {
                item {
                    LinearProgressIndicator(progress = progress, modifier = Modifier.fillMaxWidth())
                }
            }

            errorMessage?.let { msg ->
                item {
                    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
                        Text(
                            text = msg,
                            modifier = Modifier.padding(12.dp),
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                    }
                }
            }

            result?.let { r ->
                item {
                    ComparisonSummary(r)
                }
                items(r.lines) { line ->
                    DiffLineRow(line)
                }
            }

            item { Spacer(modifier = Modifier.height(40.dp)) }
        }
    }
}

@Composable
private fun FilePickerRow(
    label: String,
    file: PickedFile?,
    enabled: Boolean,
    onPick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(Icons.Default.PictureAsPdf, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(
                    text = file?.name ?: stringResource(R.string.compare_no_file_selected),
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            OutlinedButton(onClick = onPick, enabled = enabled) {
                Text(if (file == null) stringResource(R.string.action_select) else stringResource(R.string.compare_change))
            }
        }
    }
}

@Composable
private fun ComparisonSummary(result: ComparisonResult) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = stringResource(R.string.compare_summary_pages, result.pageCountA, result.pageCountB),
                style = MaterialTheme.typography.bodyMedium
            )
            Text(
                text = stringResource(R.string.compare_summary_diff, result.addedCount, result.removedCount),
                style = MaterialTheme.typography.bodyMedium
            )
            if (result.usedCoarseFallback) {
                Text(
                    text = stringResource(R.string.compare_coarse_fallback_notice),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun DiffLineRow(line: DiffLine) {
    val (background, prefix) = when (line.type) {
        DiffType.ADDED -> MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f) to "+ "
        DiffType.REMOVED -> MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.4f) to "- "
        DiffType.EQUAL -> androidx.compose.ui.graphics.Color.Transparent to "  "
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(4.dp))
            .background(background)
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Text(
            text = prefix + line.text,
            style = MaterialTheme.typography.bodySmall,
            fontFamily = FontFamily.Monospace,
            maxLines = 4,
            overflow = TextOverflow.Ellipsis
        )
    }
}
