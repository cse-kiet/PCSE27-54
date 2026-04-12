package com.example.frontend

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.example.frontend/sos"
    private val EVENT_CHANNEL = "com.example.frontend/sos_events"

    private var eventSink: EventChannel.EventSink? = null
    private var keywordReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel: start / stop service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startSos" -> {
                        startSosService()
                        result.success(null)
                    }
                    "stopSos" -> {
                        stopSosService()
                        result.success(null)
                    }
                    "isRunning" -> {
                        result.success(SosServiceState.isRunning)
                    }
                    else -> result.notImplemented()
                }
            }

        // Event channel: push keyword-detected events to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                    registerKeywordReceiver()
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterKeywordReceiver()
                }
            })
    }

    private fun startSosService() {
        val intent = Intent(this, SosListenerService::class.java).apply {
            action = SosListenerService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        SosServiceState.isRunning = true
    }

    private fun stopSosService() {
        val intent = Intent(this, SosListenerService::class.java).apply {
            action = SosListenerService.ACTION_STOP
        }
        startService(intent)
        SosServiceState.isRunning = false
    }

    private fun registerKeywordReceiver() {
        keywordReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                eventSink?.success("keyword_detected")
            }
        }
        val filter = IntentFilter(SosListenerService.BROADCAST_KEYWORD)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(keywordReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(keywordReceiver, filter)
        }
    }

    private fun unregisterKeywordReceiver() {
        keywordReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }
        keywordReceiver = null
    }

    override fun onDestroy() {
        unregisterKeywordReceiver()
        super.onDestroy()
    }
}

object SosServiceState {
    var isRunning: Boolean = false
}
