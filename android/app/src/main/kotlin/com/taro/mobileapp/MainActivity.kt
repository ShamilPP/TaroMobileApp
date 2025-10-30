package com.taro.mobileapp

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.taro.mobileapp/call_detection"
    private lateinit var channel: MethodChannel
    private var callBroadcastReceiver: BroadcastReceiver? = null
    
    companion object {
        private const val TAG = "MainActivity"
        private const val PERMISSION_REQUEST_CODE = 100
        private const val OVERLAY_REQUEST_CODE = 101
        private const val BATTERY_OPTIMIZATION_REQUEST_CODE = 102
        
        private val REQUIRED_PERMISSIONS = arrayOf(
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.READ_CALL_LOG,
            Manifest.permission.CALL_PHONE
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set static reference for service communication
        CallDetectionService.mainActivity = this
        
        // Register broadcast receiver for call events
        registerCallBroadcastReceiver()
        
        // Handle intent if app was opened by service
        handleIncomingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleNavigationIntent(intent)

        handleIncomingIntent(intent)
    }

    private fun handleIncomingIntent(intent: Intent?) {
        intent?.let {
            if (it.getBooleanExtra("incoming_call", false)) {
                val phoneNumber = it.getStringExtra("phoneNumber")
                val timestamp = it.getLongExtra("timestamp", 0)
                
                Log.d(TAG, "App opened by incoming call: $phoneNumber")
                
                // Notify Flutter about the incoming call
                phoneNumber?.let { number ->
                    notifyIncomingCall(number)
                }
            }
        }
    }

    private fun registerCallBroadcastReceiver() {
        if (callBroadcastReceiver == null) {
            callBroadcastReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    when (intent?.action) {
                        "com.taro.mobileapp.INCOMING_CALL" -> {
                            val phoneNumber = intent.getStringExtra("phoneNumber")
                            val callState = intent.getStringExtra("callState")
                            val timestamp = intent.getLongExtra("timestamp", 0)
                            
                            Log.d(TAG, "Received incoming call broadcast: $phoneNumber")
                            
                            phoneNumber?.let { number ->
                                notifyIncomingCall(number)
                            }
                        }
                        "com.taro.mobileapp.CALL_ENDED" -> {
                            val timestamp = intent.getLongExtra("timestamp", 0)
                            
                            Log.d(TAG, "Received call ended broadcast")
                            notifyCallEnded()
                        }
                    }
                }
            }
            
            val filter = IntentFilter().apply {
                addAction("com.taro.mobileapp.INCOMING_CALL")
                addAction("com.taro.mobileapp.CALL_ENDED")
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(callBroadcastReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(callBroadcastReceiver, filter)
            }
            
            Log.d(TAG, "Call broadcast receiver registered")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        
        // Clear static reference
        CallDetectionService.mainActivity = null
        
        // Unregister broadcast receiver
        callBroadcastReceiver?.let {
            try {
                unregisterReceiver(it)
                callBroadcastReceiver = null
                Log.d(TAG, "Call broadcast receiver unregistered")
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering broadcast receiver: ${e.message}")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "checkPermissions" -> {
                        val permissions = checkAllPermissions()
                        Log.d(TAG, "Checking permissions: $permissions")
                        result.success(permissions)
                    }
                    "requestPermissions" -> {
                        Log.d(TAG, "Requesting runtime permissions")
                        requestRuntimePermissions()
                        result.success(true)
                    }
                    "requestOverlayPermission" -> {
                        Log.d(TAG, "Requesting overlay permission")
                        requestOverlayPermission()
                        result.success(true)
                    }
                    "openPermissionSettings" -> {
                        Log.d(TAG, "Opening permission settings")
                        openPermissionSettings()
                        result.success(true)
                    }
                    "startCallDetection" -> {
                        if (hasAllRequiredPermissions()) {
                            Log.d(TAG, "Starting call detection service")
                            startCallDetectionService()
                            result.success(true)
                        } else {
                            Log.e(TAG, "Cannot start service - permissions not granted")
                            result.error("PERMISSION_DENIED", "Required permissions not granted", null)
                        }
                    }
                    "stopCallDetection" -> {
                        Log.d(TAG, "Stopping call detection service")
                        stopCallDetectionService()
                        result.success(true)
                    }
                    "isCallDetectionRunning" -> {
                        val isRunning = isCallDetectionServiceRunning()
                        Log.d(TAG, "Service running status: $isRunning")
                        result.success(isRunning)
                    }
                    "testCallPopup" -> {
                        val phoneNumber = call.argument<String>("phoneNumber") ?: "1234567890"
                        Log.d(TAG, "Testing call popup for: $phoneNumber")
                        testCallPopup(phoneNumber)
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling method call: ${call.method}", e)
                result.error("ERROR", "Error handling method call: ${e.message}", null)
            }
        }
    }

    /**
     * Notify Flutter app about incoming call
     * This method is called from the service
     */
    fun notifyIncomingCall(phoneNumber: String) {
        try {
            Log.d(TAG, "Notifying Flutter about incoming call: $phoneNumber")
            
            val callData = mapOf(
                "phoneNumber" to phoneNumber,
                "callState" to "RINGING",
                "timestamp" to System.currentTimeMillis()
            )
            
            channel.invokeMethod("onIncomingCall", callData)
            Log.d(TAG, "Successfully notified Flutter about incoming call")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error notifying Flutter about incoming call: ${e.message}")
        }
    }

    /**
     * Notify Flutter app that call ended
     * This method is called from the service
     */
    fun notifyCallEnded() {
        try {
            Log.d(TAG, "Notifying Flutter about call end")
            
            val callData = mapOf(
                "timestamp" to System.currentTimeMillis()
            )
            
            channel.invokeMethod("onCallEnded", callData)
            Log.d(TAG, "Successfully notified Flutter about call end")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error notifying Flutter about call end: ${e.message}")
        }
    }

    private fun checkAllPermissions(): Map<String, Boolean> {
        val permissionStatus = mutableMapOf<String, Boolean>()
        
        Log.d(TAG, "Checking all permissions...")
        
        // Check each runtime permission individually
        for (permission in REQUIRED_PERMISSIONS) {
            val granted = ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
            permissionStatus[permission] = granted
            Log.d(TAG, "Permission $permission: $granted")
        }
        
        // Check overlay permission
        val overlayGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
        permissionStatus["overlay"] = overlayGranted
        Log.d(TAG, "Overlay permission: $overlayGranted")
        
        // Check battery optimization
        val batteryOptimized = isBatteryOptimizationIgnored()
        permissionStatus["batteryOptimization"] = batteryOptimized
        Log.d(TAG, "Battery optimization ignored: $batteryOptimized")
        
        // Check if all runtime permissions are granted
        val allRuntimeGranted = REQUIRED_PERMISSIONS.all { permission ->
            ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
        }
        
        // Overall status
        permissionStatus["allGranted"] = allRuntimeGranted && overlayGranted
        
        Log.d(TAG, "All permissions granted: ${permissionStatus["allGranted"]}")
        return permissionStatus
    }

    private fun hasAllRequiredPermissions(): Boolean {
        val runtimePermissions = REQUIRED_PERMISSIONS.all { permission ->
            val granted = ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
            Log.d(TAG, "Runtime permission $permission: $granted")
            granted
        }
        
        val overlayPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
        
        Log.d(TAG, "Runtime permissions: $runtimePermissions, Overlay: $overlayPermission")
        return runtimePermissions && overlayPermission
    }

    private fun requestRuntimePermissions() {
        val permissionsToRequest = mutableListOf<String>()
        
        for (permission in REQUIRED_PERMISSIONS) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(permission)
                Log.d(TAG, "Need to request permission: $permission")
            }
        }
        
        if (permissionsToRequest.isNotEmpty()) {
            Log.d(TAG, "Requesting permissions: ${permissionsToRequest.joinToString()}")
            ActivityCompat.requestPermissions(
                this,
                permissionsToRequest.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        } else {
            Log.d(TAG, "All runtime permissions already granted")
            notifyPermissionResult(true, "runtime")
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                Log.d(TAG, "Requesting overlay permission via settings")
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                try {
                    startActivityForResult(intent, OVERLAY_REQUEST_CODE)
                } catch (e: Exception) {
                    Log.e(TAG, "Error opening overlay permission settings", e)
                    notifyPermissionResult(false, "overlay")
                }
            } else {
                Log.d(TAG, "Overlay permission already granted")
                notifyPermissionResult(true, "overlay")
            }
        } else {
            Log.d(TAG, "Overlay permission not required for this Android version")
            notifyPermissionResult(true, "overlay")
        }
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }

    private fun requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            try {
                startActivityForResult(intent, BATTERY_OPTIMIZATION_REQUEST_CODE)
            } catch (e: Exception) {
                Log.e(TAG, "Error requesting battery optimization exemption", e)
            }
        }
    }

    private fun openPermissionSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
        }
        try {
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening app settings", e)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        Log.d(TAG, "Permission result - Request code: $requestCode")
        
        when (requestCode) {
            PERMISSION_REQUEST_CODE -> {
                val allGranted = grantResults.isNotEmpty() && 
                    grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                
                Log.d(TAG, "Runtime permissions result: $allGranted")
                
                // Log individual permission results
                for (i in permissions.indices) {
                    val permission = permissions[i]
                    val granted = grantResults.getOrNull(i) == PackageManager.PERMISSION_GRANTED
                    Log.d(TAG, "Permission $permission: $granted")
                }
                
                notifyPermissionResult(allGranted, "runtime")
                updatePermissionStatus()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        Log.d(TAG, "Activity result - Request code: $requestCode, Result code: $resultCode")
        
        when (requestCode) {
            OVERLAY_REQUEST_CODE -> {
                val overlayGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    Settings.canDrawOverlays(this)
                } else {
                    true
                }
                
                Log.d(TAG, "Overlay permission result: $overlayGranted")
                notifyPermissionResult(overlayGranted, "overlay")
                updatePermissionStatus()
            }
            BATTERY_OPTIMIZATION_REQUEST_CODE -> {
                val batteryOptimized = isBatteryOptimizationIgnored()
                Log.d(TAG, "Battery optimization result: $batteryOptimized")
                updatePermissionStatus()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume - updating permission status")
        // Update permission status when app resumes
        updatePermissionStatus()
        handleNavigationIntent(intent)

        // Set static reference again in case it was cleared
        CallDetectionService.mainActivity = this
    }

    override fun onPause() {
        super.onPause()
        // Don't clear the static reference on pause, only on destroy
        // This allows background service to still communicate
    }

    private fun notifyPermissionResult(granted: Boolean, type: String) {
        Log.d(TAG, "Notifying permission result: $type = $granted")
        try {
            channel.invokeMethod("onPermissionResult", mapOf(
                "granted" to granted,
                "type" to type
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error notifying permission result", e)
        }
    }

    private fun updatePermissionStatus() {
        try {
            val permissionStatus = checkAllPermissions()
            Log.d(TAG, "Updating permission status: $permissionStatus")
            channel.invokeMethod("onPermissionStatusUpdate", permissionStatus)
        } catch (e: Exception) {
            Log.e(TAG, "Error updating permission status", e)
        }
    }

    private fun startCallDetectionService() {
        try {
            if (hasAllRequiredPermissions()) {
                val intent = Intent(this, CallDetectionService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
                Log.d(TAG, "Call detection service started")
            } else {
                Log.e(TAG, "Cannot start service - missing permissions")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting call detection service", e)
        }
    }

    private fun stopCallDetectionService() {
        try {
            val intent = Intent(this, CallDetectionService::class.java)
            stopService(intent)
            Log.d(TAG, "Call detection service stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping call detection service", e)
        }
    }

    private fun isCallDetectionServiceRunning(): Boolean {
        return CallDetectionService.isServiceRunning
    }

    private fun testCallPopup(phoneNumber: String) {
        try {
            if (hasAllRequiredPermissions()) {
                // Send intent to service to trigger popup
                val intent = Intent(this, CallDetectionService::class.java).apply {
                    putExtra("trigger_popup", true)
                    putExtra("incoming_number", phoneNumber)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
                Log.d(TAG, "Testing call popup for number: $phoneNumber")
            } else {
                Log.e(TAG, "Cannot show popup - missing permissions")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error testing call popup", e)
        }
    }

    private fun handleNavigationIntent(intent: Intent?) {
        intent?.let { intentData ->
            val action = intentData.getStringExtra("action")
            val phoneNumber = intentData.getStringExtra("phoneNumber")
            val leadId = intentData.getStringExtra("leadId")
            val navigateTo = intentData.getStringExtra("navigate_to")
            val editMode = intentData.getBooleanExtra("edit_mode", false)

            Log.d("MainActivity", "Handling intent - Action: $action, NavigateTo: $navigateTo, LeadId: $leadId")

            when (action) {
                "show_lead_details" -> {
                    if (leadId != null) {
                        navigateToLeadDetails(leadId, phoneNumber, false)
                    }
                }
                "edit_lead" -> {
                    if (leadId != null) {
                        navigateToLeadDetails(leadId, phoneNumber, true)
                    }
                }
                "show_call_details" -> {
                    if (phoneNumber != null) {
                        navigateToCallDetails(phoneNumber)
                    }
                }
                "new_lead" -> {
                    if (phoneNumber != null) {
                        navigateToNewLead(phoneNumber)
                    }
                }
            }

            // Clear the intent extras to prevent re-processing
            intent.replaceExtras(Bundle())
        }
    }

    private fun navigateToLeadDetails(leadId: String, phoneNumber: String?, editMode: Boolean) {
        try {
            // Send to Flutter via method channel
            val arguments = mapOf(
                "action" to "navigate_to_lead_details",
                "leadId" to leadId,
                "phoneNumber" to phoneNumber,
                "editMode" to editMode,
                "timestamp" to System.currentTimeMillis()
            )

            channel.invokeMethod("navigateToLeadDetails", arguments)
            Log.d("MainActivity", "Sent lead details navigation to Flutter: $leadId")

        } catch (e: Exception) {
            Log.e("MainActivity", "Error navigating to lead details: ${e.message}")
        }
    }

    private fun navigateToCallDetails(phoneNumber: String) {
        try {
            val arguments = mapOf(
                "action" to "navigate_to_call_details",
                "phoneNumber" to phoneNumber,
                "timestamp" to System.currentTimeMillis()
            )

            channel.invokeMethod("navigateToCallDetails", arguments)
            Log.d("MainActivity", "Sent call details navigation to Flutter: $phoneNumber")

        } catch (e: Exception) {
            Log.e("MainActivity", "Error navigating to call details: ${e.message}")
        }
    }

    private fun navigateToNewLead(phoneNumber: String) {
        try {
            val arguments = mapOf(
                "action" to "navigate_to_new_lead",
                "phoneNumber" to phoneNumber,
                "timestamp" to System.currentTimeMillis()
            )

            channel.invokeMethod("navigateToNewLead", arguments)
            Log.d("MainActivity", "Sent new lead navigation to Flutter: $phoneNumber")

        } catch (e: Exception) {
            Log.e("MainActivity", "Error navigating to new lead: ${e.message}")
        }
    }
}