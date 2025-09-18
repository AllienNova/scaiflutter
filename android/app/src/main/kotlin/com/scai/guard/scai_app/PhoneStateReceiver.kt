package com.scai.guard.scai_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

class PhoneStateReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "PhoneStateReceiver"

        // Phone state constants
        const val PHONE_STATE_IDLE = "IDLE"
        const val PHONE_STATE_RINGING = "RINGING"
        const val PHONE_STATE_OFFHOOK = "OFFHOOK"

        // Call state constants for Flutter
        const val CALL_STATE_IDLE = "CALL_IDLE"
        const val CALL_STATE_INCOMING = "CALL_INCOMING"
        const val CALL_STATE_STARTED = "CALL_STARTED"
        const val CALL_STATE_ENDED = "CALL_ENDED"

        // Static callback for phone state changes
        var onPhoneStateChanged: ((String, String?) -> Unit)? = null
    }
    
    private var lastState = TelephonyManager.CALL_STATE_IDLE
    private var isIncomingCall = false
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
            
            Log.d(TAG, "Phone state changed: $state, number: $phoneNumber")
            
            when (state) {
                TelephonyManager.EXTRA_STATE_IDLE -> {
                    handleIdleState(phoneNumber)
                }
                TelephonyManager.EXTRA_STATE_RINGING -> {
                    handleRingingState(phoneNumber)
                }
                TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                    handleOffHookState(phoneNumber)
                }
            }
        }
    }
    
    private fun handleIdleState(phoneNumber: String?) {
        Log.d(TAG, "Phone is idle")
        
        // If we were in a call, it has ended
        if (lastState == TelephonyManager.CALL_STATE_OFFHOOK) {
            Log.d(TAG, "Call ended")
            onPhoneStateChanged?.invoke(CALL_STATE_ENDED, phoneNumber)
        }
        
        lastState = TelephonyManager.CALL_STATE_IDLE
        isIncomingCall = false
    }
    
    private fun handleRingingState(phoneNumber: String?) {
        Log.d(TAG, "Phone is ringing, incoming call from: $phoneNumber")
        
        isIncomingCall = true
        lastState = TelephonyManager.CALL_STATE_RINGING
        
        // Notify Flutter about incoming call
        onPhoneStateChanged?.invoke(CALL_STATE_INCOMING, phoneNumber)
    }
    
    private fun handleOffHookState(phoneNumber: String?) {
        Log.d(TAG, "Phone is off hook")
        
        when (lastState) {
            TelephonyManager.CALL_STATE_RINGING -> {
                // Incoming call was answered
                Log.d(TAG, "Incoming call answered")
                onPhoneStateChanged?.invoke(CALL_STATE_STARTED, phoneNumber)
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                // Outgoing call was initiated
                Log.d(TAG, "Outgoing call started")
                isIncomingCall = false
                onPhoneStateChanged?.invoke(CALL_STATE_STARTED, phoneNumber)
            }
        }
        
        lastState = TelephonyManager.CALL_STATE_OFFHOOK
    }
}
