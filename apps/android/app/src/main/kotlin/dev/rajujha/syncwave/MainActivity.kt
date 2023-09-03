package dev.rajujha.syncwave

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val REQUEST_MEDIA_PROJECTION = 41002
        private const val TAG = "SyncWave.MainActivity"

        var mediaProjectionResultCode: Int = Activity.RESULT_CANCELED
        var mediaProjectionData: Intent? = null

        fun clearProjectionPermission() {
            mediaProjectionResultCode = Activity.RESULT_CANCELED
            mediaProjectionData = null
        }
    }

    private val methodChannelName = "dev.rajujha.syncwave/audio_capture"
    private val eventChannelName = "dev.rajujha.syncwave/audio_capture_events"

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> {
                        result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                    }

                    "requestCapturePermission" -> {
                        requestCapturePermission(result)
                    }

                    "startCapture" -> {
                        val useSystemAudio = call.argument<Boolean>("useSystemAudio") ?: true
                        val useMicrophone = call.argument<Boolean>("useMicrophone") ?: false
                        try {
                            Log.d(
                                TAG,
                                "startCapture requested useSystemAudio=$useSystemAudio useMicrophone=$useMicrophone",
                            )
                            startAudioCaptureService(
                                useSystemAudio = useSystemAudio,
                                useMicrophone = useMicrophone,
                            )
                            result.success(true)
                        } catch (error: Exception) {
                            Log.e(TAG, "Failed to start capture service", error)
                            result.error(
                                "start_capture_failed",
                                error.message ?: "Unable to start capture service.",
                                null,
                            )
                        }
                    }

                    "stopCapture" -> {
                        try {
                            Log.d(TAG, "stopCapture requested")
                            stopAudioCaptureService()
                            result.success(true)
                        } catch (error: Exception) {
                            Log.e(TAG, "Failed to stop capture service", error)
                            result.error(
                                "stop_capture_failed",
                                error.message ?: "Unable to stop capture service.",
                                null,
                            )
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        AudioCaptureEventBus.attachSink(events)
                    }

                    override fun onCancel(arguments: Any?) {
                        AudioCaptureEventBus.attachSink(null)
                    }
                },
            )
    }

    private fun requestCapturePermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            Log.w(TAG, "MediaProjection requested on unsupported Android version")
            result.success(false)
            return
        }

        if (pendingPermissionResult != null) {
            Log.w(TAG, "MediaProjection permission request already in progress")
            result.error("permission_in_progress", "Permission request already in progress.", null)
            return
        }

        val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        pendingPermissionResult = result
        Log.d(TAG, "Launching MediaProjection permission dialog")
        @Suppress("DEPRECATION")
        startActivityForResult(manager.createScreenCaptureIntent(), REQUEST_MEDIA_PROJECTION)
    }

    private fun startAudioCaptureService(useSystemAudio: Boolean, useMicrophone: Boolean) {
        val intent = Intent(this, AudioCaptureForegroundService::class.java).apply {
            action = AudioCaptureForegroundService.ACTION_START
            putExtra(AudioCaptureForegroundService.EXTRA_USE_SYSTEM_AUDIO, useSystemAudio)
            putExtra(AudioCaptureForegroundService.EXTRA_USE_MICROPHONE, useMicrophone)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopAudioCaptureService() {
        val intent = Intent(this, AudioCaptureForegroundService::class.java).apply {
            action = AudioCaptureForegroundService.ACTION_STOP
        }
        startService(intent)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != REQUEST_MEDIA_PROJECTION) {
            return
        }

        val granted = resultCode == Activity.RESULT_OK && data != null
        if (granted) {
            mediaProjectionResultCode = resultCode
            mediaProjectionData = data
            Log.d(TAG, "MediaProjection permission granted")
        } else {
            clearProjectionPermission()
            Log.w(TAG, "MediaProjection permission denied or canceled")
        }

        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }

    override fun onDestroy() {
        pendingPermissionResult?.success(false)
        pendingPermissionResult = null
        super.onDestroy()
    }
}
