package com.pocketvibe.ide

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.pocketvibe.ide.termux.TermuxBridge
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val TERMUX_CHANNEL = "pocketvibe/termux_bridge"
    private val STORAGE_CHANNEL = "pocketvibe/storage"
    private lateinit var bridge: TermuxBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = TermuxBridge(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TERMUX_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTermuxInstalled" -> {
                        result.success(bridge.isTermuxInstalled())
                    }
                    "isTermuxApiInstalled" -> {
                        result.success(bridge.isTermuxApiInstalled())
                    }
                    "runScript" -> {
                        val path = call.argument<String>("path") ?: ""
                        val args = (call.argument<List<String>>("args") ?: listOf()).toTypedArray()
                        val background = call.argument<Boolean>("background") ?: true
                        runTermuxCommand(path, args, background, result, isScript = true)
                    }
                    "runCommand" -> {
                        val command = call.argument<String>("command") ?: ""
                        val args = (call.argument<List<String>>("args") ?: listOf()).toTypedArray()
                        val background = call.argument<Boolean>("background") ?: true
                        runTermuxCommand(command, args, background, result, isScript = false)
                    }
                    "checkFileExists" -> {
                        val path = call.argument<String>("path") ?: ""
                        Thread {
                            val exists = bridge.checkFileExists(path)
                            result.success(exists)
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSharedStoragePath" -> {
                        result.success(Environment.getExternalStorageDirectory()?.absolutePath)
                    }
                    "hasFullStorageAccess" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            result.success(Environment.isExternalStorageManager())
                        } else {
                            result.success(true)
                        }
                    }
                    "requestFullStorageAccess" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            if (!Environment.isExternalStorageManager()) {
                                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                                    data = android.net.Uri.parse("package:${context.packageName}")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                context.startActivity(intent)
                                result.success(false)
                            } else {
                                result.success(true)
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun runTermuxCommand(
        input: String,
        args: Array<String>,
        background: Boolean,
        result: MethodChannel.Result,
        isScript: Boolean
    ) {
        Thread {
            val latch = CountDownLatch(1)
            var errorCode: String? = null
            var errorMsg: String? = null

            val receiver = object : ResultReceiver(Handler(Looper.getMainLooper())) {
                override fun onReceiveResult(resultCode: Int, resultData: Bundle?) {
                    when (resultCode) {
                        0 -> {
                            val exitCode = resultData?.getInt("exit_code") ?: 0
                            if (exitCode != 0) {
                                val stderr = resultData?.getString("stderr") ?: ""
                                if (stderr.contains("allow-external-apps")) {
                                    errorCode = "TERMUX_ALLOW_EXTERNAL_APPS"
                                    errorMsg = "Termux butuh izin 'allow-external-apps=true'. Jalankan: echo 'allow-external-apps=true' >> ~/.termux/termux.properties"
                                } else {
                                    errorCode = "TERMUX_FAILED"
                                    errorMsg = if (stderr.isNotBlank()) stderr else "Exit code: $exitCode"
                                }
                            }
                        }
                        -1 -> {
                            errorCode = "TERMUX_RUN_COMMAND_NOT_ENABLED"
                            errorMsg = "Izin RUN_COMMAND belum diberikan. Buka Termux, tap notifikasi 'bootstrap_complete', pilih Allow."
                        }
                        -2 -> {
                            errorCode = "TERMUX_NOT_INITIALIZED"
                            errorMsg = "Termux belum diinisialisasi. Buka Termux sekali dan tunggu 5 detik."
                        }
                        else -> {
                            errorCode = "TERMUX_FAILED"
                            errorMsg = "Perintah gagal dijalankan (kode: $resultCode)"
                        }
                    }
                    latch.countDown()
                }
            }

            try {
                if (isScript) {
                    bridge.runScript(input, args, background, receiver)
                } else {
                    bridge.runCommand(input, args, background, receiver)
                }
            } catch (e: Exception) {
                errorCode = "TERMUX_ERROR"
                errorMsg = e.message ?: "Unknown error"
                latch.countDown()
            }

            if (!latch.await(60, TimeUnit.SECONDS)) {
                errorCode = "TERMUX_TIMEOUT"
                errorMsg = "Perintah tidak merespon setelah 60 detik"
            }

            if (errorCode != null) {
                result.error(errorCode, errorMsg, null)
            } else {
                result.success(null)
            }
        }.start()
    }
}
