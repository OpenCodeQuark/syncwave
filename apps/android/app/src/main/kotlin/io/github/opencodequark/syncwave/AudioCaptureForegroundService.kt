package io.github.opencodequark.syncwave

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.Manifest
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.os.Process
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import kotlin.concurrent.thread

class AudioCaptureForegroundService : Service() {
    companion object {
        private const val TAG = "SyncWave.AudioCaptureService"

        const val ACTION_START = "io.github.opencodequark.syncwave.audio.START"
        const val ACTION_STOP = "io.github.opencodequark.syncwave.audio.STOP"

        const val EXTRA_USE_SYSTEM_AUDIO = "extra_use_system_audio"
        const val EXTRA_USE_MICROPHONE = "extra_use_microphone"

        const val NOTIFICATION_CHANNEL_ID = "syncwave_audio_capture"
        const val NOTIFICATION_ID = 41001
    }

    private var captureThread: Thread? = null
    private var running = false
    private var audioRecord: AudioRecord? = null
    private var mediaProjection: MediaProjection? = null
    private var isForegroundActive = false
    private var sequenceNumber: Long = 0
    private var streamStartedAtMs: Long = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                Log.d(TAG, "ACTION_STOP received")
                stopCapture("stopped")
                stopSelf()
                return START_NOT_STICKY
            }

            ACTION_START -> {
                val useSystemAudio = intent.getBooleanExtra(EXTRA_USE_SYSTEM_AUDIO, true)
                val useMicrophone = intent.getBooleanExtra(EXTRA_USE_MICROPHONE, false)
                Log.d(
                    TAG,
                    "ACTION_START useSystemAudio=$useSystemAudio useMicrophone=$useMicrophone",
                )

                val startedForeground = tryStartForeground(
                    useSystemAudio = useSystemAudio,
                    useMicrophone = useMicrophone,
                )
                if (!startedForeground) {
                    stopCapture("foreground_start_failed")
                    stopSelf()
                    return START_NOT_STICKY
                }

                startCapture(
                    useSystemAudio = useSystemAudio,
                    useMicrophone = useMicrophone,
                )
                return START_STICKY
            }

            else -> return START_NOT_STICKY
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "Service destroyed")
        stopCapture("destroyed")
        super.onDestroy()
    }

    private fun tryStartForeground(useSystemAudio: Boolean, useMicrophone: Boolean): Boolean {
        return try {
            val notification = buildNotification(
                useSystemAudio = useSystemAudio,
                useMicrophone = useMicrophone,
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                var serviceType = ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST
                if (useSystemAudio || useMicrophone) {
                    serviceType = 0
                    if (useSystemAudio) {
                        serviceType = serviceType or ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                    }
                    if (useMicrophone) {
                        serviceType = serviceType or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                    }
                }
                ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, serviceType)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }

            isForegroundActive = true
            true
        } catch (error: Exception) {
            Log.e(TAG, "Unable to enter foreground mode", error)
            AudioCaptureEventBus.emit(
                mapOf(
                    "type" to "error",
                    "message" to (error.message ?: "Unable to start foreground broadcast service."),
                ),
            )
            false
        }
    }

    private fun buildNotification(useSystemAudio: Boolean, useMicrophone: Boolean): Notification {
        ensureNotificationChannel()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        } else {
            null
        }

        val sources = mutableListOf<String>()
        if (useSystemAudio) {
            sources.add("System Audio")
        }
        if (useMicrophone) {
            sources.add("Microphone")
        }

        val contentText = if (sources.isEmpty()) {
            "Preparing audio capture"
        } else {
            "Capturing ${sources.joinToString(" + ")}"
        }

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentTitle("SyncWave broadcast active")
            .setContentText(contentText)
            .setOngoing(true)
            .setOnlyAlertOnce(true)

        if (contentIntent != null) {
            builder.setContentIntent(contentIntent)
        }

        return builder.build()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "SyncWave Audio Capture",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Foreground capture notification for active audio broadcast"
        }
        manager.createNotificationChannel(channel)
    }

    private fun startCapture(useSystemAudio: Boolean, useMicrophone: Boolean) {
        if (running) {
            Log.d(TAG, "Capture start ignored because capture is already running")
            return
        }

        if (!useSystemAudio && !useMicrophone) {
            AudioCaptureEventBus.emit(
                mapOf(
                    "type" to "error",
                    "message" to "Enable Audio Source or Microphone before starting broadcast.",
                ),
            )
            stopCapture("no_audio_source")
            stopSelf()
            return
        }

        if (useSystemAudio || useMicrophone) {
            val recordAudioGranted = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO,
            ) == PackageManager.PERMISSION_GRANTED
            if (!recordAudioGranted) {
                AudioCaptureEventBus.emit(
                    mapOf(
                        "type" to "error",
                        "message" to "Audio capture permission is not granted.",
                    ),
                )
                stopCapture("record_audio_permission_missing")
                stopSelf()
                return
            }
        }

        val sampleRate = 48000
        val channelMask = AudioFormat.CHANNEL_IN_MONO
        val encoding = AudioFormat.ENCODING_PCM_16BIT
        val minBuffer = AudioRecord.getMinBufferSize(sampleRate, channelMask, encoding)
        val frameBytes = 3840
        val bufferSize = if (minBuffer > 0) {
            maxOf(minBuffer * 4, frameBytes * 4)
        } else {
            sampleRate
        }

        try {
            val record = when {
                useSystemAudio -> buildSystemAudioRecord(
                    sampleRate = sampleRate,
                    channelMask = channelMask,
                    encoding = encoding,
                    bufferSize = bufferSize,
                )

                else -> buildMicrophoneAudioRecord(
                    sampleRate = sampleRate,
                    channelMask = channelMask,
                    encoding = encoding,
                    bufferSize = bufferSize,
                )
            }

            audioRecord = record
            running = true
            sequenceNumber = 0
            streamStartedAtMs = System.currentTimeMillis()
            record.startRecording()
            Log.d(TAG, "Audio capture started sampleRate=$sampleRate")
            AudioCaptureEventBus.emit(
                mapOf(
                    "type" to "capture_started",
                    "sampleRate" to sampleRate,
                    "channelCount" to 1,
                    "encoding" to "pcm16",
                    "streamStartedAt" to streamStartedAtMs,
                ),
            )

            captureThread = thread(start = true, name = "syncwave-audio-capture") {
                Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)
                // 40ms frame at 48kHz mono PCM16: 48_000 * 0.04 * 2 = 3_840 bytes.
                // Accumulating to exact frame boundaries reduces browser crackle from short reads.
                val readBuffer = ByteArray(frameBytes)
                val pendingFrame = ByteArray(frameBytes)
                var pendingLength = 0
                while (running) {
                    val read = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        record.read(readBuffer, 0, readBuffer.size, AudioRecord.READ_BLOCKING)
                    } else {
                        @Suppress("DEPRECATION")
                        record.read(readBuffer, 0, readBuffer.size)
                    }
                    if (read > 0) {
                        var offset = 0
                        while (offset < read) {
                            val toCopy = minOf(frameBytes - pendingLength, read - offset)
                            System.arraycopy(readBuffer, offset, pendingFrame, pendingLength, toCopy)
                            pendingLength += toCopy
                            offset += toCopy

                            if (pendingLength == frameBytes) {
                                emitAudioFrame(
                                    raw = pendingFrame.copyOf(frameBytes),
                                    sampleRate = sampleRate,
                                )
                                pendingLength = 0
                            }
                        }
                    } else if (read == AudioRecord.ERROR_INVALID_OPERATION || read == AudioRecord.ERROR_BAD_VALUE) {
                        throw IllegalStateException("AudioRecord read failed: $read")
                    }
                }
            }
        } catch (error: Exception) {
            Log.e(TAG, "Failed to start capture", error)
            stopCapture("error")
            AudioCaptureEventBus.emit(
                mapOf(
                    "type" to "error",
                    "message" to (error.message ?: "Audio capture failed."),
                ),
            )
            stopSelf()
        }
    }

    private fun buildSystemAudioRecord(
        sampleRate: Int,
        channelMask: Int,
        encoding: Int,
        bufferSize: Int,
    ): AudioRecord {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw IllegalStateException("System audio capture requires Android 10 or higher.")
        }

        val resultCode = MainActivity.mediaProjectionResultCode
        if (resultCode != Activity.RESULT_OK) {
            throw IllegalStateException("MediaProjection permission is not granted.")
        }
        val data = MainActivity.mediaProjectionData
            ?: throw IllegalStateException("MediaProjection permission is not granted.")

        val projectionManager =
            getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val projection = projectionManager.getMediaProjection(resultCode, data)
            ?: throw IllegalStateException("Unable to obtain MediaProjection instance.")
        mediaProjection = projection

        val config = AudioPlaybackCaptureConfiguration.Builder(projection)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME)
            .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
            .build()

        return AudioRecord.Builder()
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(encoding)
                    .setSampleRate(sampleRate)
                    .setChannelMask(channelMask)
                    .build(),
            )
            .setBufferSizeInBytes(bufferSize)
            .setAudioPlaybackCaptureConfig(config)
            .build()
    }

    private fun emitAudioFrame(raw: ByteArray, sampleRate: Int) {
        val sampleCount = raw.size / 2
        val durationMs = ((sampleCount.toDouble() / sampleRate.toDouble()) * 1000.0).toLong()
        val captureTimestamp = System.currentTimeMillis()
        AudioCaptureEventBus.emit(
            mapOf(
                "type" to "audio_chunk",
                "data" to raw,
                "format" to "pcm16",
                "sampleRate" to sampleRate,
                "channelCount" to 1,
                "durationMs" to durationMs,
                "sequence" to sequenceNumber,
                "captureTimestamp" to captureTimestamp,
                "hostTimestamp" to captureTimestamp,
                "streamStartedAt" to streamStartedAtMs,
            ),
        )
        sequenceNumber += 1
    }

    private fun buildMicrophoneAudioRecord(
        sampleRate: Int,
        channelMask: Int,
        encoding: Int,
        bufferSize: Int,
    ): AudioRecord {
        return AudioRecord.Builder()
            .setAudioSource(MediaRecorder.AudioSource.MIC)
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(encoding)
                    .setSampleRate(sampleRate)
                    .setChannelMask(channelMask)
                    .build(),
            )
            .setBufferSizeInBytes(bufferSize)
            .build()
    }

    private fun stopCapture(reason: String) {
        Log.d(TAG, "Stopping capture reason=$reason")
        running = false

        captureThread?.interrupt()
        captureThread = null

        try {
            audioRecord?.stop()
        } catch (_: Exception) {
        }

        try {
            audioRecord?.release()
        } catch (_: Exception) {
        }

        audioRecord = null

        try {
            mediaProjection?.stop()
        } catch (_: Exception) {
        }

        mediaProjection = null
        MainActivity.clearProjectionPermission()

        if (isForegroundActive) {
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
            isForegroundActive = false
        }

        AudioCaptureEventBus.emit(
            mapOf(
                "type" to "capture_stopped",
                "reason" to reason,
            ),
        )
    }
}
