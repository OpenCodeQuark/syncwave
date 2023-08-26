package dev.rajujha.syncwave

import io.flutter.plugin.common.EventChannel

object AudioCaptureEventBus {
    private var sink: EventChannel.EventSink? = null

    fun attachSink(eventSink: EventChannel.EventSink?) {
        sink = eventSink
    }

    fun emit(event: Map<String, Any>) {
        sink?.success(event)
    }
}
