package com.toscanapost.ladyr

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import com.ryanheise.audioservice.AudioService
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private companion object {
        const val AUDIO_SERVICE_NOTIFICATION_ID = 1124
    }

    private var appLifecycleChannel: MethodChannel? = null
    private var isClosingFromRecents = false
    private var hasStoppedNativeAudio = false
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        appLifecycleChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "it.ladyradio/app_lifecycle"
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "it.ladyradio/native_video_player"
        ).setMethodCallHandler { call, result ->
            if (call.method != "open") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val url = call.argument<String>("url")
            if (url.isNullOrBlank()) {
                result.error("INVALID_ARGUMENTS", "Missing video URL", null)
                return@setMethodCallHandler
            }

            val title = call.argument<String>("title") ?: "Lady Radio Live"
            val intent = Intent(this, NativeVideoPlayerActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
                putExtra(NativeVideoPlayerActivity.EXTRA_URL, url)
                putExtra(NativeVideoPlayerActivity.EXTRA_TITLE, title)
            }
            startActivity(intent)
            overridePendingTransition(0, 0)
            result.success(true)
        }
    }

    override fun onDestroy() {
        if (isFinishing && !isClosingFromRecents) {
            isClosingFromRecents = true
            val fallback = Runnable { stopAudioServiceAndNotification() }
            mainHandler.postDelayed(fallback, 1200)

            appLifecycleChannel?.invokeMethod(
                "appClosedFromTask",
                null,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        mainHandler.removeCallbacks(fallback)
                        stopAudioServiceAndNotification()
                    }

                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        mainHandler.removeCallbacks(fallback)
                        stopAudioServiceAndNotification()
                    }

                    override fun notImplemented() {
                        mainHandler.removeCallbacks(fallback)
                        stopAudioServiceAndNotification()
                    }
                }
            )
        }
        super.onDestroy()
    }

    private fun stopAudioServiceAndNotification() {
        if (hasStoppedNativeAudio) return
        hasStoppedNativeAudio = true
        stopService(Intent(this, AudioService::class.java))
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(AUDIO_SERVICE_NOTIFICATION_ID)
    }
}
