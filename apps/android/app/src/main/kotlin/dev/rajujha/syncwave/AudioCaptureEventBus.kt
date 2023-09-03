package dev.rajujha.syncwave

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel

object AudioCaptureEventBus {
    private const val TAG = "SyncWave.AudioEventBus"
    private var sink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun attachSink(eventSink: EventChannel.EventSink?) {
        sink = eventSink
    }

    fun emit(event: Map<String, Any>) {
        val target = sink ?: return
        if (Looper.myLooper() == Looper.getMainLooper()) {
            try {
                target.success(event)
            } catch (error: Exception) {
                Log.w(TAG, "Unable to emit event", error)
            }
            return
        }

        mainHandler.post {
            try {
                target.success(event)
            } catch (error: Exception) {
                Log.w(TAG, "Unable to emit event", error)
            }
        }
    }
}
