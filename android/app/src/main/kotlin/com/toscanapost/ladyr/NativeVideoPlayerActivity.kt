package com.toscanapost.ladyr

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.pm.ActivityInfo
import android.os.Build
import android.os.Bundle
import android.util.Rational
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView

class NativeVideoPlayerActivity : Activity() {
    companion object {
        const val EXTRA_URL = "url"
        const val EXTRA_TITLE = "title"
    }

    private var player: ExoPlayer? = null
    private var playerView: PlayerView? = null
    private var pipAspectRatio = Rational(16, 9)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        overridePendingTransition(0, 0)

        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_FULL_SENSOR
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val url = intent.getStringExtra(EXTRA_URL)
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "Lady Radio Live"

        if (url.isNullOrBlank()) {
            finish()
            return
        }

        val root = FrameLayout(this).apply {
            setBackgroundColor(android.graphics.Color.BLACK)
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        val view = PlayerView(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            setShowBuffering(PlayerView.SHOW_BUFFERING_WHEN_PLAYING)
            useController = true
        }
        root.addView(view)
        setContentView(root)
        playerView = view

        val mediaItem = MediaItem.Builder()
            .setUri(url)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle(title)
                    .setArtist("Lady Radio")
                    .build()
            )
            .build()

        player = ExoPlayer.Builder(this).build().also { exoPlayer ->
            view.player = exoPlayer
            exoPlayer.setMediaItem(mediaItem)
            exoPlayer.addListener(
                object : Player.Listener {
                    override fun onVideoSizeChanged(videoSize: VideoSize) {
                        updatePipAspectRatio(videoSize)
                    }
                }
            )
            exoPlayer.prepare()
            exoPlayer.playWhenReady = true
        }
        updatePipParams()
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        enterPipIfPossible()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: android.content.res.Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        playerView?.useController = !isInPictureInPictureMode
        window.decorView.systemUiVisibility = if (isInPictureInPictureMode) {
            View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
        } else {
            0
        }
    }

    override fun onStop() {
        super.onStop()
        if (!isCurrentlyInPictureInPictureMode() && !isChangingConfigurations) {
            player?.pause()
        }
    }

    override fun onDestroy() {
        playerView?.player = null
        playerView = null
        player?.release()
        player = null
        super.onDestroy()
    }

    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
    }

    private fun enterPipIfPossible() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val currentPlayer = player ?: return
        if (!currentPlayer.isPlaying) return

        updatePipParams()
        enterPictureInPictureMode(
            PictureInPictureParams.Builder()
                .setAspectRatio(pipAspectRatio)
                .build()
        )
    }

    private fun isCurrentlyInPictureInPictureMode(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && isInPictureInPictureMode
    }

    private fun updatePipParams() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(pipAspectRatio)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(true)
        }

        setPictureInPictureParams(builder.build())
    }

    private fun updatePipAspectRatio(videoSize: VideoSize) {
        val width = videoSize.width
        val height = videoSize.height
        if (width <= 0 || height <= 0) return

        val normalizedWidth = width.coerceAtMost(height * 239 / 100)
        val normalizedHeight = height.coerceAtMost(width * 239 / 100)
        pipAspectRatio = Rational(normalizedWidth, normalizedHeight)
        updatePipParams()
    }
}
