package com.example.fuel_log

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import android.os.IBinder
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.view.KeyEvent
import androidx.core.app.NotificationCompat

class IntercomForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "intercom_live_v2"
        const val NOTIFICATION_ID = 42001
        const val EXTRA_TOUR_NAME = "tour_name"
        const val EXTRA_ROLE = "role"
        const val EXTRA_IS_TRANSMITTING = "is_transmitting"
        const val EXTRA_IS_MUTED = "is_muted"
        const val EXTRA_OPEN_MIC = "open_mic"

        const val ACTION_START = "com.example.fuel_log.intercom.START"
        const val ACTION_STOP = "com.example.fuel_log.intercom.STOP"
        const val ACTION_UPDATE = "com.example.fuel_log.intercom.UPDATE"
        const val ACTION_PTT_DOWN = "com.example.fuel_log.intercom.PTT_DOWN"
        const val ACTION_PTT_UP = "com.example.fuel_log.intercom.PTT_UP"
        const val ACTION_PTT_TOGGLE = "com.example.fuel_log.intercom.PTT_TOGGLE"
        const val ACTION_MUTE_TOGGLE = "com.example.fuel_log.intercom.MUTE_TOGGLE"
        const val ACTION_LEAVE = "com.example.fuel_log.intercom.LEAVE"
        const val ACTION_MEDIA_BUTTON = "com.example.fuel_log.intercom.MEDIA_BUTTON"

        var eventSink: ((String) -> Unit)? = null
    }

    private var mediaSession: MediaSessionCompat? = null
    private var tourName: String = "Tour intercom"
    private var role: String = "groupRider"
    private var isTransmitting: Boolean = false
    private var isMuted: Boolean = false
    private var openMic: Boolean = true

    private val mediaReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != ACTION_MEDIA_BUTTON) return
            @Suppress("DEPRECATION")
            val keyEvent =
                intent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT) ?: return
            if (keyEvent.action == KeyEvent.ACTION_DOWN && keyEvent.repeatCount == 0) {
                when (keyEvent.keyCode) {
                    KeyEvent.KEYCODE_HEADSETHOOK,
                    KeyEvent.KEYCODE_MEDIA_PLAY,
                    KeyEvent.KEYCODE_MEDIA_PAUSE,
                    KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                        eventSink?.invoke("ptt_down")
                    }
                }
            } else if (keyEvent.action == KeyEvent.ACTION_UP) {
                when (keyEvent.keyCode) {
                    KeyEvent.KEYCODE_HEADSETHOOK,
                    KeyEvent.KEYCODE_MEDIA_PLAY,
                    KeyEvent.KEYCODE_MEDIA_PAUSE,
                    KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                        eventSink?.invoke("ptt_up")
                    }
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        setupMediaSession()
        val filter = IntentFilter(ACTION_MEDIA_BUTTON)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(mediaReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(mediaReceiver, filter)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_PTT_DOWN -> eventSink?.invoke("ptt_down")
            ACTION_PTT_UP -> eventSink?.invoke("ptt_up")
            ACTION_PTT_TOGGLE -> eventSink?.invoke("ptt_toggle")
            ACTION_MUTE_TOGGLE -> eventSink?.invoke("mute_toggle")
            ACTION_LEAVE -> eventSink?.invoke("leave")
            ACTION_START, ACTION_UPDATE, null -> {
                tourName = intent?.getStringExtra(EXTRA_TOUR_NAME) ?: tourName
                role = intent?.getStringExtra(EXTRA_ROLE) ?: role
                isTransmitting = intent?.getBooleanExtra(EXTRA_IS_TRANSMITTING, isTransmitting)
                    ?: isTransmitting
                isMuted = intent?.getBooleanExtra(EXTRA_IS_MUTED, isMuted) ?: isMuted
                openMic = intent?.getBooleanExtra(EXTRA_OPEN_MIC, openMic) ?: openMic
            }
        }

        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION

        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        updateMediaSessionState()
        return START_STICKY
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(mediaReceiver)
        } catch (_: Exception) {
        }
        mediaSession?.isActive = false
        mediaSession?.release()
        mediaSession = null
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Tour Intercom Voice",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Live Tour Intercom voice connection"
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(null, null)
            enableVibration(false)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun setupMediaSession() {
        mediaSession = MediaSessionCompat(this, "FuelLogIntercom").apply {
            setFlags(
                MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or
                    MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS,
            )
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onMediaButtonEvent(mediaButtonEvent: Intent?): Boolean {
                    mediaButtonEvent?.let {
                        val clone = Intent(ACTION_MEDIA_BUTTON).apply {
                            putExtras(it)
                        }
                        mediaReceiver.onReceive(this@IntercomForegroundService, clone)
                    }
                    return true
                }
            })
            isActive = true
        }
    }

    private fun updateMediaSessionState() {
        val state = PlaybackStateCompat.Builder()
            .setActions(
                PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_PLAY_PAUSE,
            )
            .setState(
                if (isTransmitting) PlaybackStateCompat.STATE_PLAYING
                else PlaybackStateCompat.STATE_PAUSED,
                PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN,
                1f,
            )
            .build()
        mediaSession?.setPlaybackState(state)
    }

    private fun pendingAction(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, IntercomForegroundService::class.java).apply {
            this.action = action
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getService(this, requestCode, intent, flags)
    }

    private fun launchPendingIntent(): PendingIntent {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getActivity(this, 0, launchIntent, flags)
    }

    private fun buildNotification(): Notification {
        val roleLabel = when (role) {
            "sameBikeDriver" -> "Driver"
            "sameBikePillion" -> "Pillion"
            else -> "Group"
        }
        val statusText = when {
            isMuted -> "Mic muted"
            openMic -> "Hands-free active"
            isTransmitting -> "Transmitting"
            else -> "Push-to-talk ready"
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentTitle(tourName)
            .setContentText("$roleLabel · $statusText")
            .setSubText("Tap to open intercom")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(launchPendingIntent())
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)

        if (!openMic) {
            builder.addAction(
                NotificationCompat.Action(
                    android.R.drawable.ic_btn_speak_now,
                    if (isTransmitting) "Release" else "Hold PTT",
                    pendingAction(
                        if (isTransmitting) ACTION_PTT_UP else ACTION_PTT_DOWN,
                        1,
                    ),
                ),
            )
        }

        builder.addAction(
            NotificationCompat.Action(
                if (isMuted) android.R.drawable.ic_lock_silent_mode_off
                else android.R.drawable.ic_lock_silent_mode,
                if (isMuted) "Unmute" else "Mute",
                pendingAction(ACTION_MUTE_TOGGLE, 2),
            ),
        )
        builder.addAction(
            NotificationCompat.Action(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Leave",
                pendingAction(ACTION_LEAVE, 3),
            ),
        )

        return builder.build()
    }
}
