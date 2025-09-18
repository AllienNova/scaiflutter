package com.scai.guard.scai_app

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PHONE_STATE_CHANNEL = "com.scai.guard/phone_state"
    private val PHONE_STATE_EVENTS = "com.scai.guard/phone_state_events"

    private var phoneStateReceiver: PhoneStateReceiver? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel for phone state control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PHONE_STATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startPhoneStateMonitoring" -> {
                    startPhoneStateMonitoring()
                    result.success(true)
                }
                "stopPhoneStateMonitoring" -> {
                    stopPhoneStateMonitoring()
                    result.success(true)
                }
                "isPhoneStateMonitoringActive" -> {
                    result.success(phoneStateReceiver != null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Event channel for phone state events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PHONE_STATE_EVENTS).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun startPhoneStateMonitoring() {
        if (phoneStateReceiver == null) {
            // Set the static callback
            PhoneStateReceiver.onPhoneStateChanged = { phoneState, phoneNumber ->
                // Send phone state changes to Flutter
                eventSink?.success(mapOf(
                    "state" to phoneState,
                    "phoneNumber" to phoneNumber,
                    "timestamp" to System.currentTimeMillis()
                ))
            }

            phoneStateReceiver = PhoneStateReceiver()

            val filter = IntentFilter().apply {
                addAction(TelephonyManager.ACTION_PHONE_STATE_CHANGED)
                priority = 1000
            }

            registerReceiver(phoneStateReceiver, filter)
        }
    }

    private fun stopPhoneStateMonitoring() {
        phoneStateReceiver?.let {
            unregisterReceiver(it)
            phoneStateReceiver = null
        }
        // Clear the static callback
        PhoneStateReceiver.onPhoneStateChanged = null
    }

    override fun onDestroy() {
        super.onDestroy()
        stopPhoneStateMonitoring()
    }
}
