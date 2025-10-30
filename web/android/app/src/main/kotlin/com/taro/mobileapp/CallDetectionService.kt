// Updated CallDetectionService.kt - Send number to Flutter instead of showing popup
package com.taro.mobileapp

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.*

class CallDetectionService : Service() {
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "CallDetectionChannel"
    
    companion object {
        var isServiceRunning = false
        private const val TAG = "CallDetectionService"
        // Static reference to MainActivity for direct channel communication
        var mainActivity: MainActivity? = null
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate")
        createNotificationChannel()
        isServiceRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service onStartCommand")
        
        // Check if this is a trigger from broadcast receiver
        val triggerPopup = intent?.getBooleanExtra("trigger_popup", false) ?: false
        val incomingNumber = intent?.getStringExtra("incoming_number")
        val callEnded = intent?.getBooleanExtra("call_ended", false) ?: false
        
        if (triggerPopup && incomingNumber != null) {
            Log.d(TAG, "Triggered popup for number: $incomingNumber")
            handleIncomingCall(incomingNumber)
        }
        
        if (callEnded) {
            Log.d(TAG, "Call ended")
            notifyFlutterCallEnded()
        }
        
        // Start foreground service with proper type
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    startForeground(NOTIFICATION_ID, createNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL)
                } else {
                    startForeground(NOTIFICATION_ID, createNotification())
                }
            } else {
                startForeground(NOTIFICATION_ID, createNotification())
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground service: ${e.message}")
            try {
                startForeground(NOTIFICATION_ID, createNotification())
            } catch (e2: Exception) {
                Log.e(TAG, "Failed to start foreground service even without type: ${e2.message}")
                stopSelf()
                return START_NOT_STICKY
            }
        }
        
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service onDestroy")
        isServiceRunning = false
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d(TAG, "Service onTaskRemoved")
        super.onTaskRemoved(rootIntent)
        
        val restartServiceIntent = Intent(applicationContext, this.javaClass)
        restartServiceIntent.setPackage(packageName)
        
        val restartServicePendingIntent = PendingIntent.getService(
            applicationContext, 1, restartServiceIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) 
                PendingIntent.FLAG_IMMUTABLE 
            else 
                PendingIntent.FLAG_ONE_SHOT
        )
        
        val alarmService = applicationContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmService.set(
            AlarmManager.ELAPSED_REALTIME,
            1000,
            restartServicePendingIntent
        )
        
        super.onTaskRemoved(rootIntent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Call Detection Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors incoming calls"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) 
                PendingIntent.FLAG_IMMUTABLE 
            else 
                PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Call Detection Active")
            .setContentText("Monitoring incoming calls...")
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
    }

    private fun handleIncomingCall(phoneNumber: String) {
        Log.d(TAG, "Handling incoming call: $phoneNumber")
        
        // Clean the phone number - extract only digits
        val cleanedNumber = extractCleanPhoneNumber(phoneNumber)
        
        Log.d(TAG, "Original: $phoneNumber, Cleaned: $cleanedNumber")
        
        // Send the clean number to Flutter app
        notifyFlutterIncomingCall(cleanedNumber)
    }

    /**
     * Extract clean phone number with only digits
     * Removes country codes, formatting, and special characters
     */
    private fun extractCleanPhoneNumber(phoneNumber: String): String {
        // Remove all non-digits first
        var cleaned = phoneNumber.replace(Regex("[^\\d]"), "")
        
        Log.d(TAG, "After removing non-digits: $cleaned")
        
        // Handle different country code scenarios
        when {
            // Indian numbers with +91 or 91 prefix
            cleaned.startsWith("91") && cleaned.length == 12 -> {
                cleaned = cleaned.substring(2) // Remove 91 prefix
                Log.d(TAG, "Removed Indian country code: $cleaned")
            }
            // US numbers with +1 or 1 prefix
            cleaned.startsWith("1") && cleaned.length == 11 -> {
                cleaned = cleaned.substring(1) // Remove 1 prefix
                Log.d(TAG, "Removed US country code: $cleaned")
            }
            // Handle other common country codes if needed
            cleaned.startsWith("44") && cleaned.length > 10 -> {
                // UK numbers - remove 44 prefix
                cleaned = cleaned.substring(2)
                Log.d(TAG, "Removed UK country code: $cleaned")
            }
            // Add more country codes as needed
        }
        
        // Ensure we have at least 10 digits for a valid phone number
        if (cleaned.length < 10) {
            Log.w(TAG, "Phone number too short after cleaning: $cleaned")
            // Return original if cleaning made it invalid
            return phoneNumber.replace(Regex("[^\\d]"), "")
        }
        
        Log.d(TAG, "Final cleaned number: $cleaned")
        return cleaned
    }

    /**
     * Notify Flutter app about incoming call with clean number
     * Uses multiple methods to ensure delivery
     */
    private fun notifyFlutterIncomingCall(cleanPhoneNumber: String) {
        try {
            Log.d(TAG, "Notifying Flutter about incoming call: $cleanPhoneNumber")
            
            // Method 1: Direct channel communication if MainActivity is available
            mainActivity?.let { activity ->
                try {
                    activity.runOnUiThread {
                        activity.notifyIncomingCall(cleanPhoneNumber)
                    }
                    Log.d(TAG, "Sent to Flutter via direct channel: $cleanPhoneNumber")
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending via direct channel: ${e.message}")
                }
            }
            
            // Method 2: Broadcast intent as fallback
            val intent = Intent("com.taro.mobileapp.INCOMING_CALL").apply {
                putExtra("phoneNumber", cleanPhoneNumber)
                putExtra("callState", "RINGING")
                putExtra("timestamp", System.currentTimeMillis())
                addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES)
            }
            sendBroadcast(intent)
            Log.d(TAG, "Sent broadcast for incoming call: $cleanPhoneNumber")
            
            // Method 3: Try to bring app to foreground
            tryBringAppToForeground(cleanPhoneNumber)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error notifying Flutter about incoming call: ${e.message}")
        }
    }

    /**
     * Try to bring the app to foreground when call comes
     */
    private fun tryBringAppToForeground(phoneNumber: String) {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                       Intent.FLAG_ACTIVITY_CLEAR_TOP or
                       Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("incoming_call", true)
                putExtra("phoneNumber", phoneNumber)
                putExtra("timestamp", System.currentTimeMillis())
            }
            startActivity(intent)
            Log.d(TAG, "Attempted to bring app to foreground")
        } catch (e: Exception) {
            Log.e(TAG, "Error bringing app to foreground: ${e.message}")
        }
    }

    /**
     * Notify Flutter app that call ended
     */
    private fun notifyFlutterCallEnded() {
        try {
            Log.d(TAG, "Notifying Flutter about call end")
            
            // Method 1: Direct channel communication
            mainActivity?.let { activity ->
                try {
                    activity.runOnUiThread {
                        activity.notifyCallEnded()
                    }
                    Log.d(TAG, "Sent call ended to Flutter via direct channel")
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending call ended via direct channel: ${e.message}")
                }
            }
            
            // Method 2: Broadcast intent as fallback
            val intent = Intent("com.taro.mobileapp.CALL_ENDED").apply {
                putExtra("timestamp", System.currentTimeMillis())
                addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES)
            }
            sendBroadcast(intent)
            Log.d(TAG, "Sent broadcast for call ended")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error notifying Flutter about call end: ${e.message}")
        }
    }
}



