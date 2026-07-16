package com.pocketvibe.ide.termux

import android.os.Bundle
import android.os.Handler
import android.os.ResultReceiver

class TermuxCommandResult(handler: Handler?) : ResultReceiver(handler) {
    @Volatile
    var stdout: String = ""
        private set

    @Volatile
    var stderr: String = ""
        private set

    @Volatile
    var exitCode: Int = -1
        private set

    @Volatile
    var completed: Boolean = false
        private set

    @Volatile
    var error: String? = null
        private set

    override fun onReceiveResult(resultCode: Int, resultData: Bundle?) {
        super.onReceiveResult(resultCode, resultData)
        when (resultCode) {
            0 -> {
                stdout = resultData?.getString("stdout") ?: ""
                stderr = resultData?.getString("stderr") ?: ""
                exitCode = resultData?.getInt("exit_code") ?: -1
                completed = true
                error = null
            }
            else -> {
                error = "Unexpected result code: $resultCode"
                completed = true
            }
        }
    }
}
