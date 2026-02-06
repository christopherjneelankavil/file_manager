package com.example.file_viewer

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.LinkedList
import java.util.Queue

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.file_viewer/usb"
    private val REQUEST_CODE_OPEN_DIRECTORY = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDirectory" -> {
                    pendingResult = result
                    openDirectory()
                }
                "getFiles" -> {
                    val uriString = call.argument<String>("uri")
                    val recursive = call.argument<Boolean>("recursive") ?: false
                    val startTimestamp = call.argument<Long>("startDate")
                    val endTimestamp = call.argument<Long>("endDate")

                    if (uriString == null) {
                        result.error("INVALID_ARGS", "URI is required", null)
                    } else {
                        Thread {
                            val files = listFiles(uriString, recursive, startTimestamp, endTimestamp)
                            runOnUiThread {
                                result.success(files)
                            }
                        }.start()
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openDirectory() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        startActivityForResult(intent, REQUEST_CODE_OPEN_DIRECTORY)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_OPEN_DIRECTORY) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                    pendingResult?.success(uri.toString())
                } else {
                    pendingResult?.error("URI_NULL", "Uri was null", null)
                }
            } else {
                pendingResult?.error("CANCELED", "User canceled", null)
            }
            pendingResult = null
        }
    }

    private fun listFiles(uriString: String, recursive: Boolean, start: Long?, end: Long?): List<Map<String, Any>> {
        val fileList = mutableListOf<Map<String, Any>>()
        val rootUri = Uri.parse(uriString)
        val rootDir = DocumentFile.fromTreeUri(applicationContext, rootUri)

        if (rootDir == null || !rootDir.exists()) {
            return fileList
        }

        // Use a queue for traversal (BFS or DFS doesn't strict matter here, but queue = BFS)
        val queue: Queue<DocumentFile> = LinkedList()
        
        // If recursive (search mode), we start with the root.
        // If not recursive (browse mode), we just list children of root.
        
        if (recursive) {
             // For recursive, we add root's children to queue to start processing
             // Or actually, just add root to queue and loop? 
             // DocumentFile.listFiles() returns array.
             // Let's just stack the children of the current folder.
            queue.addAll(rootDir.listFiles())
        } else {
             // Non-recursive: just list files now and return
             for (file in rootDir.listFiles()) {
                 if (shouldInclude(file, start, end)) {
                     fileList.add(fileToMap(file))
                 }
             }
             return fileList
        }

        // Recursive loop
        while (!queue.isEmpty()) {
            val file = queue.poll() ?: continue

            if (file.isDirectory()) {
                // If it's a directory, add its children to the queue
                queue.addAll(file.listFiles())
                // Optionally add the folder itself? Requirement says "filter files". 
                // Usually users search for files. I will skip adding folder to results if we are in "filter" mode.
            } else {
                if (shouldInclude(file, start, end)) {
                    fileList.add(fileToMap(file))
                }
            }
        }

        return fileList
    }

    private fun shouldInclude(file: DocumentFile, start: Long?, end: Long?): Boolean {
        // If it's a folder, we probably want to include it in "browse" mode (non-recursive),
        // but dependent on requirements. 
        // In "recursive" mode (filter by date), we typically look for files.
        // Let's assume filter only applies to files.
        
        if (file.isDirectory()) {
            // In list/browser mode (start/end null usually), we include folders.
            // In filter mode (start/end set), we probably skip folders or checking their date?
            // Requirement 4: "display only the files whose lastModified..." 
            // So in filter mode, skip directories.
            if (start != null || end != null) return false
            return true
        }

        val lastModified = file.lastModified()
        if (start != null && lastModified < start) return false
        if (end != null && lastModified > end) return false

        return true
    }

    private fun fileToMap(file: DocumentFile): Map<String, Any> {
        return mapOf(
            "name" to (file.getName() ?: "Unknown"),
            "uri" to file.getUri().toString(),
            "isDirectory" to file.isDirectory(),
            "lastModified" to file.lastModified(),
            "size" to file.length(),
            "type" to (file.getType() ?: "application/octet-stream")
        )
    }
}
