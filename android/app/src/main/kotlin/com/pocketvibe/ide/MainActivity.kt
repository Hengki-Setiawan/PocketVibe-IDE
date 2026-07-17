package com.pocketvibe.ide

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.pocketvibe.ide.termux.TermuxBridge

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
                        bridge.runScript(path, args, background)
                        result.success(null)
                    }
                    "runCommand" -> {
                        val command = call.argument<String>("command") ?: ""
                        val args = (call.argument<List<String>>("args") ?: listOf()).toTypedArray()
                        val background = call.argument<Boolean>("background") ?: true
                        bridge.runCommand(command, args, background)
                        result.success(null)
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
}
