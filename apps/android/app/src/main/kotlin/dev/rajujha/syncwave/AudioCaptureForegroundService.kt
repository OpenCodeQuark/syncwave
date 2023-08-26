package dev.rajujha.syncwave

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.util.Base64
import androidx.core.app.NotificationCompat
import kotlin.concurrent.thread

class AudioCaptureForegroundService : Service() {
    companion object {
        const val ACTION_START = "dev.rajujha.syncwave.audio.START"
        const val ACTION_STOP = "dev.rajujha.syncwave.audio.STOP"

        const val EXTRA_USE_SYSTEM_AUDIO = "extra_use_system_audio"
        const val EXTRA_USE_MICROPHONE = "extra_use_microphone"

        const val NOTIFICATION_CHANNEL_ID = "syncwave_audio_capture"
        const val NOTIFICATION_ID = 41001
    }

    private var captureThread: Thread? = null
    private var running = false
    private var audioRecord: AudioRecord? = null
    private var mediaProjection: MediaProjection? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopCapture("stopped")
                stopSelf()
                return START_NOT_STICKY
            }

            ACTION_START -> {
                val useSystemAudio = intent.getBooleanExtra(EXTRA_USE_SYSTEM_AUDIO, true)
                val useMicrophone = intent.getBooleanExtra(EXTRA_USE_MICROPHONE, false)

                startForeground(
                    NOTIFICATION_ID,
                    buildNotification(useSystemAudio = useSystemAudio, useMicrophone = useMicrophone),
                )

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
        stopCapture("destroyed")
        super.onDestroy()
    }

    private fun buildNotification(useSystemAudio: Boolean, useMicrophone: Boolean): Notification {
        ensureNotificationChannel()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

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

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentTitle("SyncWave broadcast active")
            .setContentText(contentText)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(contentIntent)
            .build()
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
            return
        }

        if (!useSystemAudio && !useMicrophone) {
            AudioCaptureEventBus.emit(
                mapOf(
                    "type" to "error",
                    "message" to "Enable Audio Source or Microphone before starting broadcast.",
                ),
            )
            return
        }

        val sampleRate = 48000
        val channelMask = AudioFormat.CHANNEL_IN_MONO
        val encoding = AudioFormat.ENCODING_PCM_16BIT
        val minBuffer = AudioRecord.getMinBufferSize(sampleRate, channelMask, encoding)
        val bufferSize = if (minBuffer > 0) minBuffer * 2 else sampleRate

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
            record.startRecording()
            AudioCaptureEventBus.emit(
                mapOf(
                    "type" to "capture_started",
                    "sampleRate" to sampleRate,
                    "channelCount" to 1,
                    "encoding" to "pcm16",
                ),
            )

            captureThread = thread(start = true, name = "syncwave-audio-capture") {
                val chunk = ByteArray(4096)
                while (running) {
                    val read = record.read(chunk, 0, chunk.size)
                    if (read > 0) {
                        val raw = chunk.copyOf(read)
                        val encoded = Base64.encodeToString(raw, Base64.NO_WRAP)
                        AudioCaptureEventBus.emit(
                            mapOf(
                                "type" to "audio_chunk",
                                "data" to encoded,
                                "format" to "pcm16",
                                "sampleRate" to sampleRate,
                                "channelCount" to 1,
                            ),
                        )
                    }
                }
            }
        } catch (error: Exception) {
            stopCapture("error")
            AudioCaptureEventBus.emit(
                mapOf(
                    "type" to "error",
                    "message" to (error.message ?: "Audio capture failed."),
                ),
            )
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

        AudioCaptureEventBus.emit(
            mapOf(
                "type" to "capture_stopped",
                "reason" to reason,
            ),
        )
    }
}
