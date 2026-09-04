package com.example.fuel_log

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val audioChannelName = "com.ridelog.bd/intercom_audio"
    private val sessionChannelName = "com.ridelog.bd/intercom_session"
    private val sessionEventChannelName = "com.ridelog.bd/intercom_session_events"

    override fun onCreate(savedInstanceState: Bundle?) {
        androidx.core.view.WindowCompat.setDecorFitsSystemWindows(window, false)
        window.navigationBarColor = Color.TRANSPARENT
        window.statusBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSpeakerphoneOn" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val audioManager =
                            getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                        @Suppress("DEPRECATION")
                        audioManager.isSpeakerphoneOn = enabled
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sessionChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startSession" -> {
                        val tourName = call.argument<String>("tourName") ?: "Tour intercom"
                        val role = call.argument<String>("role") ?: "groupRider"
                        val isTransmitting = call.argument<Boolean>("isTransmitting") ?: false
                        val isMuted = call.argument<Boolean>("isMuted") ?: false
                        val openMic = call.argument<Boolean>("openMic") ?: true
                        startIntercomService(tourName, role, isTransmitting, isMuted, openMic)
                        result.success(true)
                    }
                    "updateSession" -> {
                        val tourName = call.argument<String>("tourName") ?: "Tour intercom"
                        val role = call.argument<String>("role") ?: "groupRider"
                        val isTransmitting = call.argument<Boolean>("isTransmitting") ?: false
                        val isMuted = call.argument<Boolean>("isMuted") ?: false
                        val openMic = call.argument<Boolean>("openMic") ?: true
                        updateIntercomService(tourName, role, isTransmitting, isMuted, openMic)
                        result.success(true)
                    }
                    "stopSession" -> {
                        stopIntercomService()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            sessionEventChannelName,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    IntercomForegroundService.eventSink = { event ->
                        events?.success(event)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    IntercomForegroundService.eventSink = null
                }
            },
        )
    }

    private fun startIntercomService(
        tourName: String,
        role: String,
        isTransmitting: Boolean,
        isMuted: Boolean,
        openMic: Boolean,
    ) {
        val intent = Intent(this, IntercomForegroundService::class.java).apply {
            action = IntercomForegroundService.ACTION_START
            putExtra(IntercomForegroundService.EXTRA_TOUR_NAME, tourName)
            putExtra(IntercomForegroundService.EXTRA_ROLE, role)
            putExtra(IntercomForegroundService.EXTRA_IS_TRANSMITTING, isTransmitting)
            putExtra(IntercomForegroundService.EXTRA_IS_MUTED, isMuted)
            putExtra(IntercomForegroundService.EXTRA_OPEN_MIC, openMic)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun updateIntercomService(
        tourName: String,
        role: String,
        isTransmitting: Boolean,
        isMuted: Boolean,
        openMic: Boolean,
    ) {
        val intent = Intent(this, IntercomForegroundService::class.java).apply {
            action = IntercomForegroundService.ACTION_UPDATE
            putExtra(IntercomForegroundService.EXTRA_TOUR_NAME, tourName)
            putExtra(IntercomForegroundService.EXTRA_ROLE, role)
            putExtra(IntercomForegroundService.EXTRA_IS_TRANSMITTING, isTransmitting)
            putExtra(IntercomForegroundService.EXTRA_IS_MUTED, isMuted)
            putExtra(IntercomForegroundService.EXTRA_OPEN_MIC, openMic)
        }
        startService(intent)
    }

    private fun stopIntercomService() {
        val intent = Intent(this, IntercomForegroundService::class.java).apply {
            action = IntercomForegroundService.ACTION_STOP
        }
        startService(intent)
    }
}
