package com.brombrom.app

import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.brombrom.app/saf"
    private val REQUEST_CODE_OPEN_DIR = 42
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestOsmandAccess" -> {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                        // Try to start at Android/data/net.osmand/files if possible (API 26+)
                        // We use a hacky URI construction that sometimes works
                        // content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fdata%2Fnet.osmand%2Ffiles
                    }
                    startActivityForResult(intent, REQUEST_CODE_OPEN_DIR)
                }
                "copyFileToSaf" -> {
                    val srcPath = call.argument<String>("srcPath")
                    val destFilename = call.argument<String>("destFilename")
                    val treeUriStr = call.argument<String>("treeUri")
                    val mimeType = call.argument<String>("mimeType")

                    if (srcPath == null || destFilename == null || treeUriStr == null) {
                        result.error("ARGS", "Missing arguments", null)
                        return@setMethodCallHandler
                    }

                    // Run in background thread to avoid ANR/Freeze on large files
                    Thread {
                        try {
                             copyFileToSaf(srcPath, destFilename, treeUriStr, mimeType ?: "application/octet-stream")
                             runOnUiThread { result.success(true) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("COPY_FAIL", e.message, null) }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_OPEN_DIR) {
            if (resultCode == RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    // Take persistent permission
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    )
                    pendingResult?.success(uri.toString())
                } else {
                    pendingResult?.error("NO_URI", "No URI returned", null)
                }
            } else {
                pendingResult?.error("CANCELED", "User canceled", null)
            }
            pendingResult = null
        }
    }

    private fun copyFileToSaf(srcPath: String, destFilename: String, treeUriStr: String, mimeType: String) {
        val treeUri = Uri.parse(treeUriStr)
        val pickedDir = DocumentFile.fromTreeUri(applicationContext, treeUri)
            ?: throw Exception("Invalid Tree URI")

        // 1. Check if file exists and delete
        val existing = pickedDir.findFile(destFilename)
        if (existing != null) {
            existing.delete()
        }

        // 2. Create new file
        val newFile = pickedDir.createFile(mimeType, destFilename)
            ?: throw Exception("Could not create file in target folder")

        // 3. Copy Stream
        contentResolver.openOutputStream(newFile.uri)?.use { output ->
            FileInputStream(File(srcPath)).use { input ->
                input.copyTo(output)
            }
        }
    }
}
