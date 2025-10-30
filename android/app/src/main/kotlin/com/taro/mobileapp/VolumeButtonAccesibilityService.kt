// VolumeButtonAccessibilityService.kt
package com.taro.mobileapp

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import android.util.Log
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

class VolumeButtonAccessibilityService : AccessibilityService() {
    
    companion object {
        private const val TAG = "VolumeAccessibilityService"
        private const val HOLD_DURATION = 1000L // 1 second hold
        var isServiceConnected = false
        var instance: VolumeButtonAccessibilityService? = null
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private var volumeUpPressed = false
    private var volumeDownPressed = false
    private var volumeUpHoldRunnable: Runnable? = null
    private var volumeDownHoldRunnable: Runnable? = null
    private var isInCall = false
    private var currentPhoneNumber: String? = null
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Accessibility Service Connected")
        isServiceConnected = true
        instance = this
        
        // Configure the service
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                   AccessibilityServiceInfo.FLAG_REQUEST_ENHANCED_WEB_ACCESSIBILITY or
                   AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 100
        }
        serviceInfo = info
        
        // Monitor call state
        monitorCallState()
    }
    
    override fun onUnbind(intent: Intent?): Boolean {
        Log.d(TAG, "Accessibility Service Disconnected")
        isServiceConnected = false
        instance = null
        return super.onUnbind(intent)
    }
    
    override fun onKeyEvent(event: KeyEvent): Boolean {
        val keyCode = event.keyCode
        val action = event.action
        
        Log.d(TAG, "Key event: code=$keyCode, action=$action, inCall=$isInCall")
        
        // Only process volume keys during calls
        if (!isInCall) {
            return false
        }
        
        when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> {
                return handleVolumeUpKey(action)
            }
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                return handleVolumeDownKey(action)
            }
        }
        
        return false
    }
    
    private fun handleVolumeUpKey(action: Int): Boolean {
        when (action) {
            KeyEvent.ACTION_DOWN -> {
                if (!volumeUpPressed) {
                    volumeUpPressed = true
                    Log.d(TAG, "Volume UP pressed")
                    
                    // Start hold timer
                    volumeUpHoldRunnable = Runnable {
                        Log.d(TAG, "Volume UP held for $HOLD_DURATION ms")
                        onVolumeUpHold()
                    }
                    handler.postDelayed(volumeUpHoldRunnable!!, HOLD_DURATION)
                }
                return true // Consume the event to prevent volume change
            }
            KeyEvent.ACTION_UP -> {
                volumeUpPressed = false
                Log.d(TAG, "Volume UP released")
                
                // Cancel hold timer
                volumeUpHoldRunnable?.let { handler.removeCallbacks(it) }
                volumeUpHoldRunnable = null
                return true
            }
        }
        return false
    }
    
    private fun handleVolumeDownKey(action: Int): Boolean {
        when (action) {
            KeyEvent.ACTION_DOWN -> {
                if (!volumeDownPressed) {
                    volumeDownPressed = true
                    Log.d(TAG, "Volume DOWN pressed")
                    
                    // Start hold timer
                    volumeDownHoldRunnable = Runnable {
                        Log.d(TAG, "Volume DOWN held for $HOLD_DURATION ms")
                        onVolumeDownHold()
                    }
                    handler.postDelayed(volumeDownHoldRunnable!!, HOLD_DURATION)
                }
                return true // Consume the event to prevent volume change
            }
            KeyEvent.ACTION_UP -> {
                volumeDownPressed = false
                Log.d(TAG, "Volume DOWN released")
                
                // Cancel hold timer
                volumeDownHoldRunnable?.let { handler.removeCallbacks(it) }
                volumeDownHoldRunnable = null
                return true
            }
        }
        return false
    }
    
    private fun onVolumeUpHold() {
        Log.d(TAG, "Volume UP hold detected during call")
        
        // Get current phone number from call log or dialer
        val phoneNumber = getCurrentCallPhoneNumber()
        
        if (phoneNumber != null) {
            triggerCallOverlay(phoneNumber, "volume_up_hold")
        } else {
            Log.w(TAG, "Could not get phone number for volume up hold")
            // Show overlay anyway with unknown number
            triggerCallOverlay("Unknown", "volume_up_hold")
        }
    }
    
    private fun onVolumeDownHold() {
        Log.d(TAG, "Volume DOWN hold detected during call")
        
        // Get current phone number from call log or dialer
        val phoneNumber = getCurrentCallPhoneNumber()
        
        if (phoneNumber != null) {
            triggerCallOverlay(phoneNumber, "volume_down_hold")
        } else {
            Log.w(TAG, "Could not get phone number for volume down hold")
            // Show overlay anyway with unknown number
            triggerCallOverlay("Unknown", "volume_down_hold")
        }
    }
    
    private fun triggerCallOverlay(phoneNumber: String, trigger: String) {
        try {
            Log.d(TAG, "Triggering overlay for: $phoneNumber (trigger: $trigger)")
            
            // Start CallDetectionService with overlay trigger
            val intent = Intent(this, CallDetectionService::class.java).apply {
                putExtra("trigger_popup", true)
                putExtra("incoming_number", phoneNumber)
                putExtra("trigger_source", trigger)
            }
            startService(intent)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error triggering overlay: ${e.message}")
        }
    }
    
    private fun getCurrentCallPhoneNumber(): String? {
        return try {
            // Try to get from stored current number
            currentPhoneNumber ?: getLastCallLogNumber()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting current call number: ${e.message}")
            null
        }
    }
    
    private fun getLastCallLogNumber(): String? {
        return try {
            val cursor = contentResolver.query(
                android.provider.CallLog.Calls.CONTENT_URI,
                arrayOf(android.provider.CallLog.Calls.NUMBER),
                null, null,
                android.provider.CallLog.Calls.DATE + " DESC LIMIT 1"
            )
            
            cursor?.use {
                if (it.moveToFirst()) {
                    val numberIndex = it.getColumnIndex(android.provider.CallLog.Calls.NUMBER)
                    if (numberIndex >= 0) {
                        return it.getString(numberIndex)
                    }
                }
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error getting last call log number: ${e.message}")
            null
        }
    }
    
    private fun monitorCallState() {
        // Monitor call state through TelephonyManager if available
        try {
            val telephonyManager = getSystemService(TELEPHONY_SERVICE) as? TelephonyManager
            Log.d(TAG, "Telephony manager initialized for call monitoring")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing telephony manager: ${e.message}")
        }
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            when (it.eventType) {
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                    handleWindowStateChanged(it)
                }
                AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED -> {
                    handleNotificationStateChanged(it)
                }
            }
        }
    }
    
    private fun handleWindowStateChanged(event: AccessibilityEvent) {
        val className = event.className?.toString()
        Log.d(TAG, "Window state changed: $className")
        
        // Detect phone app or dialer
        when {
            className?.contains("dialer", true) == true ||
            className?.contains("phone", true) == true ||
            className?.contains("call", true) == true -> {
                Log.d(TAG, "Phone/Dialer app detected")
                checkCallState()
            }
            className?.contains("incallui", true) == true -> {
                Log.d(TAG, "In-call UI detected")
                isInCall = true
                extractPhoneNumberFromEvent(event)
            }
        }
    }
    
    private fun handleNotificationStateChanged(event: AccessibilityEvent) {
        val text = event.text?.toString()
        Log.d(TAG, "Notification: $text")
        
        // Look for incoming call notifications
        if (text?.contains("incoming", true) == true || 
            text?.contains("calling", true) == true) {
            Log.d(TAG, "Incoming call notification detected")
            isInCall = true
            extractPhoneNumberFromNotification(text)
        }
    }
    
    private fun extractPhoneNumberFromEvent(event: AccessibilityEvent) {
        try {
            val text = event.text?.joinToString(" ") ?: ""
            val phoneNumber = extractPhoneNumber(text)
            if (phoneNumber != null) {
                currentPhoneNumber = phoneNumber
                Log.d(TAG, "Extracted phone number from event: $phoneNumber")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting phone number from event: ${e.message}")
        }
    }
    
    private fun extractPhoneNumberFromNotification(text: String) {
        try {
            val phoneNumber = extractPhoneNumber(text)
            if (phoneNumber != null) {
                currentPhoneNumber = phoneNumber
                Log.d(TAG, "Extracted phone number from notification: $phoneNumber")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting phone number from notification: ${e.message}")
        }
    }
    
    private fun extractPhoneNumber(text: String): String? {
        // Regex patterns for phone numbers
        val patterns = listOf(
            Regex("\\+?\\d{1,3}[\\s\\-]?\\(?\\d{3}\\)?[\\s\\-]?\\d{3}[\\s\\-]?\\d{4}"), // +1 (123) 456-7890
            Regex("\\(?\\d{3}\\)?[\\s\\-]?\\d{3}[\\s\\-]?\\d{4}"), // (123) 456-7890
            Regex("\\d{10,}"), // 1234567890 or longer
            Regex("\\+\\d{10,}") // +1234567890
        )
        
        for (pattern in patterns) {
            val match = pattern.find(text)
            if (match != null) {
                return match.value.replace(Regex("[^\\d+]"), "")
            }
        }
        
        return null
    }
    
    private fun checkCallState() {
        try {
            val telephonyManager = getSystemService(TELEPHONY_SERVICE) as? TelephonyManager
            val callState = telephonyManager?.callState
            
            when (callState) {
                TelephonyManager.CALL_STATE_RINGING -> {
                    Log.d(TAG, "Call state: RINGING")
                    isInCall = true
                }
                TelephonyManager.CALL_STATE_OFFHOOK -> {
                    Log.d(TAG, "Call state: OFFHOOK (in call)")
                    isInCall = true
                }
                TelephonyManager.CALL_STATE_IDLE -> {
                    Log.d(TAG, "Call state: IDLE")
                    isInCall = false
                    currentPhoneNumber = null
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking call state: ${e.message}")
        }
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "Accessibility service interrupted")
    }
    
    // Method to manually set call state (can be called from CallDetectionService)
    fun setCallState(inCall: Boolean, phoneNumber: String? = null) {
        isInCall = inCall
        if (phoneNumber != null) {
            currentPhoneNumber = phoneNumber
        }
        Log.d(TAG, "Call state set: inCall=$inCall, number=$phoneNumber")
    }
}