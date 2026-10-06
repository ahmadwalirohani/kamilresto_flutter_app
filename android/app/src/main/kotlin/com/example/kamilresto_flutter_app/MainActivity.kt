package com.example.kamilresto_flutter_app

import android.Manifest
import android.content.ContentValues
import android.content.ContentUris
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val logWorker = Executors.newSingleThreadExecutor()
    private var permissionResult: MethodChannel.Result? = null
    private val logPath = "${Environment.DIRECTORY_DOWNLOADS}/KamilResto/logs/"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kamilresto/public_logs")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        if (Build.VERSION.SDK_INT in 23..28 &&
                            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                            permissionResult = result
                            requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), 7101)
                        } else {
                            result.success("/storage/emulated/0/$logPath")
                        }
                    }
                    "append" -> {
                        val day = call.argument<String>("day")
                        val entry = call.argument<String>("entry")
                        if (day == null || !Regex("\\d{4}-\\d{2}-\\d{2}").matches(day) || entry == null) {
                            result.error("INVALID_LOG", "Invalid log entry", null)
                        } else {
                            logWorker.execute {
                                try {
                                    appendPublicLog("kamilresto-$day.log", "$entry\n")
                                    runOnUiThread { result.success(null) }
                                } catch (error: Exception) {
                                    runOnUiThread { result.error("LOG_WRITE_FAILED", error.toString(), null) }
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 7101) {
            val result = permissionResult
            permissionResult = null
            if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
                result?.success("/storage/emulated/0/$logPath")
            } else {
                result?.error("STORAGE_PERMISSION", "Allow storage permission to save public logs", null)
            }
        }
    }

    private fun appendPublicLog(name: String, entry: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
            var uri: android.net.Uri? = null
            contentResolver.query(collection, arrayOf(MediaStore.Downloads._ID),
                "${MediaStore.Downloads.DISPLAY_NAME} = ? AND ${MediaStore.Downloads.RELATIVE_PATH} = ?",
                arrayOf(name, logPath), null)?.use { cursor ->
                if (cursor.moveToFirst()) uri = ContentUris.withAppendedId(collection, cursor.getLong(0))
            }
            if (uri == null) {
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, name)
                    put(MediaStore.Downloads.MIME_TYPE, "text/plain")
                    put(MediaStore.Downloads.RELATIVE_PATH, logPath)
                }
                uri = contentResolver.insert(collection, values)
                    ?: throw IllegalStateException("Could not create daily log")
            }
            val stream = contentResolver.openOutputStream(uri!!, "wa")
                ?: throw IllegalStateException("Could not open daily log")
            stream.use { it.write(entry.toByteArray(Charsets.UTF_8)) }
        } else {
            @Suppress("DEPRECATION")
            val directory = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "KamilResto/logs")
            if (!directory.isDirectory && !directory.mkdirs()) {
                throw IllegalStateException("Could not create public logs folder")
            }
            File(directory, name).appendText(entry, Charsets.UTF_8)
        }
    }

    override fun onDestroy() {
        logWorker.shutdown()
        super.onDestroy()
    }
}
