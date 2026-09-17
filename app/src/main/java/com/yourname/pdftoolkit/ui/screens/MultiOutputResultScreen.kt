package com.yourname.pdftoolkit.ui.screens

import androidx.compose.ui.res.stringResource
import com.yourname.pdftoolkit.R

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import com.yourname.pdftoolkit.data.FileManager
import com.yourname.pdftoolkit.ui.components.ToolTopBar
import com.yourname.pdftoolkit.util.FileOpener
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File

/**
 * Data class representing an output file item.
 */
data class OutputFileItem(
    val uri: Uri,
    val name: String,
    val size: String,
    val index: Int
)

/**
 * Screen for displaying multiple output files with individual actions.
 * Used for split PDF (all pages), PDF to images, and other multi-output operations.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MultiOutputResultScreen(
    title: String,
    outputUris: List<Uri>,
    isImageOutput: Boolean = false,
    onNavigateBack: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val shareFailedMessage = stringResource(R.string.share_failed)
    val shareChooserTitle = stringResource(R.string.share_chooser_title)
    val shareChooserTitleMultiple = stringResource(R.string.share_chooser_title_multiple)

    // Build file items list
    val fileItems = remember(outputUris) {
        outputUris.mapIndexed { index, uri ->
            val fileInfo = FileManager.getFileInfo(context, uri)
            OutputFileItem(
                uri = uri,
                name = fileInfo?.name ?: context.getString(R.string.file_default_name, index + 1),
                size = fileInfo?.formattedSize ?: context.getString(R.string.file_unknown_size),
                index = index + 1
            )
        }
    }
    
    Scaffold(
        topBar = {
            ToolTopBar(
                title = title,
                onNavigateBack = onNavigateBack
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Header with count and open all button
            Surface(
                modifier = Modifier.fillMaxWidth(),
                tonalElevation = 2.dp
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = stringResource(R.string.multi_output_files_created, fileItems.size),
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = if (isImageOutput)
                            stringResource(R.string.multi_output_images_saved)
                        else
                            stringResource(R.string.multi_output_pdfs_saved),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Open all button
                    OutlinedButton(
                        onClick = {
                            scope.launch(Dispatchers.IO) {
                                if (isImageOutput) {
                                    FileOpener.openMultipleImages(context, outputUris)
                                } else {
                                    // For PDFs, open the first one
                                    outputUris.firstOrNull()?.let { 
                                        FileOpener.openPdf(context, it)
                                    }
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = if (isImageOutput) Icons.Default.PhotoLibrary else Icons.Default.PictureAsPdf,
                            contentDescription = null
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            if (isImageOutput) stringResource(R.string.action_open_all_gallery)
                            else stringResource(R.string.action_open_first_pdf)
                        )
                    }

                    // Share all button
                    OutlinedButton(
                        onClick = {
                            shareMultipleFiles(context, outputUris, shareChooserTitle, shareChooserTitleMultiple, shareFailedMessage)
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = Icons.Default.Share,
                            contentDescription = null
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(stringResource(R.string.action_share_all))
                    }
                }
            }
            
            // File list
            if (isImageOutput) {
                // Grid layout for images
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    itemsIndexed(
                        items = fileItems,
                        key = { _, item -> item.uri.toString() }
                    ) { _, item ->
                        ImageOutputCard(
                            item = item,
                            onOpen = { scope.launch(Dispatchers.IO) { FileOpener.openImage(context, item.uri) } },
                            onShare = { shareFile(context, item.uri, shareChooserTitle, shareFailedMessage) }
                        )
                    }
                }
            } else {
                // List layout for PDFs
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    itemsIndexed(
                        items = fileItems,
                        key = { _, item -> item.uri.toString() }
                    ) { _, item ->
                        PdfOutputCard(
                            item = item,
                            onOpen = { scope.launch(Dispatchers.IO) { FileOpener.openPdf(context, item.uri) } },
                            onShare = { shareFile(context, item.uri, shareChooserTitle, shareFailedMessage) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PdfOutputCard(
    item: OutputFileItem,
    onOpen: () -> Unit,
    onShare: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Page number badge
            Surface(
                shape = MaterialTheme.shapes.small,
                color = MaterialTheme.colorScheme.primaryContainer,
                modifier = Modifier.size(48.dp)
            ) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Text(
                        text = "${item.index}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            // File info
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = item.name,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    maxLines = 1
                )
                Text(
                    text = item.size,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            // Action buttons
            Row {
                IconButton(onClick = onShare) {
                    Icon(
                        imageVector = Icons.Default.Share,
                        contentDescription = stringResource(R.string.pdf_share),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
                
                IconButton(onClick = onOpen) {
                    Icon(
                        imageVector = Icons.Default.OpenInNew,
                        contentDescription = stringResource(R.string.action_open),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
}

@Composable
private fun ImageOutputCard(
    item: OutputFileItem,
    onOpen: () -> Unit,
    onShare: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
        ) {
            // Image thumbnail placeholder
            Surface(
                shape = MaterialTheme.shapes.small,
                color = MaterialTheme.colorScheme.surface,
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(1f)
            ) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Icon(
                        imageVector = Icons.Default.Image,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                    )
                    
                    // Index badge
                    Surface(
                        shape = MaterialTheme.shapes.small,
                        color = MaterialTheme.colorScheme.primaryContainer,
                        modifier = Modifier
                            .align(Alignment.TopStart)
                            .padding(8.dp)
                    ) {
                        Text(
                            text = "${item.index}",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // File name
            Text(
                text = item.name,
                style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.Medium,
                maxLines = 1,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
            
            Text(
                text = item.size,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Action buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                IconButton(onClick = onOpen) {
                    Icon(
                        imageVector = Icons.Default.OpenInNew,
                        contentDescription = stringResource(R.string.action_open),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
                
                IconButton(onClick = onShare) {
                    Icon(
                        imageVector = Icons.Default.Share,
                        contentDescription = stringResource(R.string.pdf_share),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
}

/**
 * Share a single file. Shows a toast if no app can handle the share intent.
 */
private fun shareFile(context: android.content.Context, uri: Uri, chooserTitle: String, failedMessage: String) {
    try {
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = context.contentResolver.getType(uri) ?: "*/*"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val chooser = Intent.createChooser(shareIntent, chooserTitle)
        context.startActivity(chooser)
    } catch (e: Exception) {
        android.widget.Toast.makeText(context, failedMessage, android.widget.Toast.LENGTH_SHORT).show()
    }
}

/**
 * Share multiple files. Shows a toast if no app can handle the share intent.
 */
private fun shareMultipleFiles(
    context: android.content.Context,
    uris: List<Uri>,
    chooserTitle: String,
    chooserTitleMultiple: String,
    failedMessage: String
) {
    if (uris.isEmpty()) return

    try {
        val shareIntent = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).apply {
                type = context.contentResolver.getType(uris[0]) ?: "*/*"
                putExtra(Intent.EXTRA_STREAM, uris[0])
            }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                type = "*/*"
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
            }
        }
        shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

        val chooser = Intent.createChooser(shareIntent, if (uris.size == 1) chooserTitle else chooserTitleMultiple)
        context.startActivity(chooser)
    } catch (e: Exception) {
        android.widget.Toast.makeText(context, failedMessage, android.widget.Toast.LENGTH_SHORT).show()
    }
}
