package com.pocketvibe.ide.termux

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import android.util.Log
import androidx.core.content.ContextCompat
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class TermuxBridge(private val context: Context) {

    companion object {
        private const val TAG = "TermuxBridge"
    }

    fun runScript(
        scriptPath: String,
        args: Array<String> = arrayOf(),
        background: Boolean = true,
        receiver: ResultReceiver? = null
    ) {
        val intent = Intent().apply {
            setClassName(
                TermuxConstants.TERMUX_PACKAGE,
                TermuxConstants.RUN_COMMAND_SERVICE
            )
            action = TermuxConstants.ACTION_RUN_COMMAND
            putExtra(TermuxConstants.EXTRA_COMMAND_PATH, scriptPath)
            putExtra(TermuxConstants.EXTRA_ARGUMENTS, args)
            putExtra(TermuxConstants.EXTRA_BACKGROUND, background)
            if (receiver != null) {
                putExtra(TermuxConstants.EXTRA_RESULT_RECEIVER, receiver)
            }
        }
        try {
            ContextCompat.startForegroundService(context, intent)
        } catch (e: SecurityException) {
            Log.e(TAG, "Termux:API tidak memiliki izin RUN_COMMAND: ${e.message}")
            receiver?.send(-1, null)
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Termux belum diinisialisasi: ${e.message}")
            receiver?.send(-2, null)
        } catch (e: Exception) {
            Log.e(TAG, "Gagal menjalankan script: ${e.message}")
            receiver?.send(-3, null)
        }
    }

    fun runCommand(
        command: String,
        args: Array<String> = arrayOf(),
        background: Boolean = true,
        receiver: ResultReceiver? = null
    ) {
        val intent = Intent().apply {
            setClassName(
                TermuxConstants.TERMUX_PACKAGE,
                TermuxConstants.RUN_COMMAND_SERVICE
            )
            action = TermuxConstants.ACTION_RUN_COMMAND
            putExtra(
                TermuxConstants.EXTRA_COMMAND_PATH,
                "/data/data/com.termux/files/usr/bin/bash"
            )
            putExtra(
                TermuxConstants.EXTRA_ARGUMENTS,
                arrayOf("-c", command) + args
            )
            putExtra(TermuxConstants.EXTRA_BACKGROUND, background)
            if (receiver != null) {
                putExtra(TermuxConstants.EXTRA_RESULT_RECEIVER, receiver)
            }
        }
        try {
            ContextCompat.startForegroundService(context, intent)
        } catch (e: SecurityException) {
            Log.e(TAG, "Termux:API tidak memiliki izin RUN_COMMAND: ${e.message}")
            receiver?.send(-1, null)
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Termux belum diinisialisasi: ${e.message}")
            receiver?.send(-2, null)
        } catch (e: Exception) {
            Log.e(TAG, "Gagal menjalankan perintah: ${e.message}")
            receiver?.send(-3, null)
        }
    }

    fun isTermuxInstalled(): Boolean {
        return try {
            context.packageManager.getPackageInfo(TermuxConstants.TERMUX_PACKAGE, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun isTermuxApiInstalled(): Boolean {
        return try {
            context.packageManager.getPackageInfo(TermuxConstants.TERMUX_API_PACKAGE, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun createCommandResult(): TermuxCommandResult {
        return TermuxCommandResult(
            Handler(Looper.getMainLooper())
        )
    }

    fun checkFileExists(path: String, timeoutSec: Long = 5): Boolean {
        val latch = CountDownLatch(1)
        val result = BooleanArray(1)

        val receiver = object : ResultReceiver(Handler(Looper.getMainLooper())) {
            override fun onReceiveResult(resultCode: Int, resultData: Bundle?) {
                if (resultCode == 0) {
                    val exitCode = resultData?.getInt("exit_code") ?: -1
                    result[0] = exitCode == 0
                }
                latch.countDown()
            }
        }

        runCommand("test -f \"$path\"", receiver = receiver)
        return try {
            latch.await(timeoutSec, TimeUnit.SECONDS)
            result[0]
        } catch (e: Exception) {
            Log.e(TAG, "checkFileExists timed out: ${e.message}")
            false
        }
    }
}
