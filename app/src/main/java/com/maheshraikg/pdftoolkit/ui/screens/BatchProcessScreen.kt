package com.maheshraikg.pdftoolkit.ui.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.maheshraikg.pdftoolkit.R
import com.maheshraikg.pdftoolkit.data.FileManager
import com.maheshraikg.pdftoolkit.domain.operations.CompressionLevel
import com.maheshraikg.pdftoolkit.domain.operations.PdfCompressor
import com.maheshraikg.pdftoolkit.domain.operations.PdfWatermarker
import com.maheshraikg.pdftoolkit.domain.operations.WatermarkConfig
import com.maheshraikg.pdftoolkit.domain.operations.WatermarkPosition
import com.maheshraikg.pdftoolkit.domain.operations.WatermarkType
import com.maheshraikg.pdftoolkit.ui.components.ToolTopBar
import com.maheshraikg.pdftoolkit.util.OutputFolderManager
import kotlinx.coroutines.launch

private enum class BatchOperation { COMPRESS, WATERMARK }

private data class BatchFileState(
    val uri: Uri,
    val name: String,
    val progress: Float = 0f,
    val done: Boolean = false,
    val error: String? = null
)

/**
 * Batch processing screen: runs one operation (compress or watermark) across
 * multiple selected PDFs, reusing the existing single-file PdfCompressor /
 * PdfWatermarker operation classes rather than duplicating their logic.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BatchProcessScreen(onNavigateBack: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var fileStates by remember { mutableStateOf<List<BatchFileState>>(emptyList()) }
    var operation by remember { mutableStateOf(BatchOperation.COMPRESS) }
    var watermarkText by remember { mutableStateOf("") }
    var isProcessing by remember { mutableStateOf(false) }
    var resultUris by remember { mutableStateOf<List<Uri>>(emptyList()) }
    var showResults by remember { mutableStateOf(false) }

    val filePicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenMultipleDocuments()
    ) { uris ->
        if (uris.isNotEmpty()) {
            val existing = fileStates.map { it.uri }.toSet()
            val newStates = uris.filter { it !in existing }.map { uri ->
                BatchFileState(uri = uri, name = FileManager.getFileInfo(context, uri)?.name ?: uri.lastPathSegment ?: "PDF")
            }
            fileStates = fileStates + newStates
        }
    }

    suspend fun runBatch() {
        isProcessing = true
        val outputs = mutableListOf<Uri>()
        val states = fileStates
        for (index in states.indices) {
            val state = states[index]
            try {
                when (operation) {
                    BatchOperation.COMPRESS -> {
                        val streamResult = OutputFolderManager.createOutputStream(context, "compressed_${state.name}")
                        if (streamResult != null) {
                            streamResult.outputStream.use { out ->
                                PdfCompressor().compressPdf(
                                    context = context,
                                    inputUri = state.uri,
                                    outputStream = out,
                                    level = CompressionLevel.MEDIUM,
                                    onProgress = { p ->
                                        fileStates = fileStates.toMutableList().also {
                                            it[index] = it[index].copy(progress = p)
                                        }
                                    }
                                )
                            }
                            outputs.add(streamResult.outputFile.contentUri)
                        }
                    }
                    BatchOperation.WATERMARK -> {
                        val outputFile = OutputFolderManager.createOutputFile(context, "watermarked_${state.name}")
                        if (outputFile != null) {
                            PdfWatermarker().addWatermark(
                                context = context,
                                inputUri = state.uri,
                                outputUri = outputFile.contentUri,
                                config = WatermarkConfig(
                                    type = WatermarkType.Text(content = watermarkText.ifBlank { "CONFIDENTIAL" }),
                                    position = WatermarkPosition.CENTER
                                ),
                                progressCallback = { p ->
                                    fileStates = fileStates.toMutableList().also {
                                        it[index] = it[index].copy(progress = p / 100f)
                                    }
                                }
                            )
                            outputs.add(outputFile.contentUri)
                        }
                    }
                }
                fileStates = fileStates.toMutableList().also {
                    it[index] = it[index].copy(done = true, progress = 1f)
                }
            } catch (e: Exception) {
                fileStates = fileStates.toMutableList().also {
                    it[index] = it[index].copy(done = true, error = e.message ?: "Failed")
                }
            }
        }
        resultUris = outputs
        isProcessing = false
        if (outputs.isNotEmpty()) {
            showResults = true
        }
    }

    if (showResults && resultUris.isNotEmpty()) {
        MultiOutputResultScreen(
            title = stringResource(R.string.batch_results_title),
            outputUris = resultUris,
            isImageOutput = false,
            onNavigateBack = {
                showResults = false
                resultUris = emptyList()
                fileStates = emptyList()
                onNavigateBack()
            }
        )
        return
    }

    Scaffold(
        topBar = { ToolTopBar(title = stringResource(R.string.batch_title), onNavigateBack = onNavigateBack) }
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
                    text = stringResource(R.string.batch_subtitle),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            item {
                OutlinedButton(
                    onClick = { filePicker.launch(arrayOf("application/pdf")) },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isProcessing
                ) {
                    Icon(Icons.Default.LibraryAdd, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        if (fileStates.isEmpty()) stringResource(R.string.batch_select_pdfs)
                        else stringResource(R.string.batch_add_more_pdfs)
                    )
                }
            }

            if (fileStates.isNotEmpty()) {
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(
                            text = stringResource(R.string.batch_choose_operation),
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold
                        )
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            FilterChip(
                                selected = operation == BatchOperation.COMPRESS,
                                onClick = { operation = BatchOperation.COMPRESS },
                                enabled = !isProcessing,
                                label = { Text(stringResource(R.string.tool_compress_pdf)) }
                            )
                            FilterChip(
                                selected = operation == BatchOperation.WATERMARK,
                                onClick = { operation = BatchOperation.WATERMARK },
                                enabled = !isProcessing,
                                label = { Text(stringResource(R.string.tool_add_watermark)) }
                            )
                        }
                    }
                }

                if (operation == BatchOperation.WATERMARK) {
                    item {
                        OutlinedTextField(
                            value = watermarkText,
                            onValueChange = { watermarkText = it },
                            label = { Text(stringResource(R.string.watermark_label_text)) },
                            placeholder = { Text("CONFIDENTIAL") },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = !isProcessing,
                            singleLine = true
                        )
                    }
                }

                item {
                    Text(
                        text = stringResource(R.string.batch_files_selected, fileStates.size),
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }

            items(fileStates, key = { it.uri.toString() }) { state ->
                BatchFileRow(state)
            }

            if (fileStates.isNotEmpty()) {
                item {
                    Button(
                        onClick = { scope.launch { runBatch() } },
                        modifier = Modifier.fillMaxWidth(),
                        enabled = !isProcessing
                    ) {
                        if (isProcessing) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(18.dp),
                                color = MaterialTheme.colorScheme.onPrimary,
                                strokeWidth = 2.dp
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(stringResource(R.string.batch_processing))
                        } else {
                            Text(stringResource(R.string.batch_start, fileStates.size))
                        }
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(40.dp)) }
        }
    }
}

@Composable
private fun BatchFileRow(state: BatchFileState) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = when {
                        state.error != null -> Icons.Default.Error
                        state.done -> Icons.Default.CheckCircle
                        else -> Icons.Default.PictureAsPdf
                    },
                    contentDescription = null,
                    tint = when {
                        state.error != null -> MaterialTheme.colorScheme.error
                        state.done -> MaterialTheme.colorScheme.primary
                        else -> MaterialTheme.colorScheme.onSurfaceVariant
                    }
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = state.name,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
            }
            if (!state.done && state.progress > 0f) {
                Spacer(modifier = Modifier.height(6.dp))
                LinearProgressIndicator(
                    progress = state.progress,
                    modifier = Modifier.fillMaxWidth()
                )
            }
            if (state.error != null) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = state.error,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}
