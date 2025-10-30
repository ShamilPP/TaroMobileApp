package com.taro.mobileapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telephony.TelephonyManager
import android.util.Log

class PhoneStateReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "PhoneStateReceiver"
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d(TAG, "PhoneStateReceiver onReceive: ${intent?.action}")
        
        if (intent?.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
            
            Log.d(TAG, "Phone state: $state, Number: $phoneNumber")
            
            when (state) {
                TelephonyManager.EXTRA_STATE_RINGING -> {
                    Log.d(TAG, "Incoming call detected")
                    phoneNumber?.let { number ->
                        // Start the service and pass the phone number
                        startCallDetectionService(context, number)
                    } ?: run {
                        Log.w(TAG, "Phone number is null")
                        // Still trigger service even if number is null
                        startCallDetectionService(context, "Unknown Number")
                    }
                }
                TelephonyManager.EXTRA_STATE_IDLE -> {
                    Log.d(TAG, "Call ended - notifying service")
                    // Notify service that call ended
                    notifyCallEnded(context)
                }
            }
        }
    }
    
    private fun startCallDetectionService(context: Context?, phoneNumber: String) {
        context?.let {
            try {
                val serviceIntent = Intent(it, CallDetectionService::class.java).apply {
                    putExtra("trigger_popup", true)
                    putExtra("incoming_number", phoneNumber)
                }
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    it.startForegroundService(serviceIntent)
                } else {
                    it.startService(serviceIntent)
                }
                
                Log.d(TAG, "Call detection service started for number: $phoneNumber")
            } catch (e: Exception) {
                Log.e(TAG, "Error starting call detection service", e)
            }
        }
    }
    
    private fun notifyCallEnded(context: Context?) {
        context?.let {
            try {
                val serviceIntent = Intent(it, CallDetectionService::class.java).apply {
                    putExtra("call_ended", true)
                }
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    it.startForegroundService(serviceIntent)
                } else {
                    it.startService(serviceIntent)
                }
                
                Log.d(TAG, "Notified service that call ended")
            } catch (e: Exception) {
                Log.e(TAG, "Error notifying service of call end", e)
            }
        }
    }
}