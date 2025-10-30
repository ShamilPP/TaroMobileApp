// Enhanced CallDetectionService.kt - Minimal notification approach
package com.taro.mobileapp

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.*

class CallDetectionService : Service() {
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "CallDetectionChannel"
    
    // Overlay related variables
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isOverlayShowing = false
    private var overlayJob: Job? = null
    
    // Firebase data fetcher
    private lateinit var dataFetcher: FirebaseDataFetcher
    private var fetchJob: Job? = null
    
    companion object {
        var isServiceRunning = false
        private const val TAG = "CallDetectionService"
        var mainActivity: MainActivity? = null
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate")
        createNotificationChannel()
        isServiceRunning = true
        
        // Initialize WindowManager and Firebase data fetcher
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        dataFetcher = FirebaseDataFetcher()
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
            hideOverlay()
            notifyFlutterCallEnded()
        }
        
        // Start foreground service with minimal notification
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    startForeground(NOTIFICATION_ID, createMinimalNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL)
                } else {
                    startForeground(NOTIFICATION_ID, createMinimalNotification())
                }
            } else {
                startForeground(NOTIFICATION_ID, createMinimalNotification())
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground service: ${e.message}")
            try {
                startForeground(NOTIFICATION_ID, createMinimalNotification())
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
        hideOverlay()
        fetchJob?.cancel()
        dataFetcher.cleanup()
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

    /**
     * Create notification channel with minimal importance
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Background Service", // Generic name
                NotificationManager.IMPORTANCE_MIN // Minimal importance - won't make sound or show heads-up
            ).apply {
                description = "App background service"
                setShowBadge(false) // Don't show badge
                enableLights(false) // No LED
                enableVibration(false) // No vibration
                setSound(null, null) // No sound
                lockscreenVisibility = Notification.VISIBILITY_SECRET // Hide on lock screen
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Create minimal notification that's barely visible
     */
    private fun createMinimalNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) 
                PendingIntent.FLAG_IMMUTABLE 
            else 
                PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("") // Empty title
            .setContentText("") // Empty text
            .setSmallIcon(android.R.drawable.ic_media_pause) // Very minimal icon
            .setContentIntent(pendingIntent)
            .setOngoing(true) // Can't be swiped away
            .setVisibility(NotificationCompat.VISIBILITY_SECRET) // Hide from lock screen
            .setSilent(true) // No sound
            .setShowWhen(false) // No timestamp
            .setAutoCancel(false) // Don't auto-cancel
            .setPriority(NotificationCompat.PRIORITY_MIN) // Lowest priority
            .setCategory(NotificationCompat.CATEGORY_SERVICE) // Service category
            .setLocalOnly(true) // Don't sync to wearables
            .build()
    }

    // Alternative: Create completely invisible notification (may not work on all devices)
    private fun createInvisibleNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_pause)
            .setContentTitle("")
            .setContentText("")
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setShowWhen(false)
            .setSilent(true)
            .setOngoing(true)
            .setAutoCancel(false)
            .setLocalOnly(true)
            .setColor(Color.TRANSPARENT)
            .build()
    }

    // Method to temporarily show notification when actually needed
    private fun showTemporaryNotification(message: String) {
        val tempNotification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Call Detection")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
            
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(999, tempNotification) // Different ID
        
        // Auto-remove after 3 seconds
        CoroutineScope(Dispatchers.Main).launch {
            delay(3000)
            notificationManager.cancel(999)
        }
    }

    private fun handleIncomingCall(phoneNumber: String) {
        Log.d(TAG, "Handling incoming call: $phoneNumber")
        
        // Clean the phone number
        val cleanedNumber = extractCleanPhoneNumber(phoneNumber)
        Log.d(TAG, "Original: $phoneNumber, Cleaned: $cleanedNumber")
        
        // Show overlay with Firebase data
        fetchDataAndShowOverlay(cleanedNumber)
        
        // Send notification to Flutter app via broadcast only (no app opening)
        notifyFlutterIncomingCallSilent(cleanedNumber)
    }

    /**
     * Fetch data from Firebase and show overlay
     */
   private fun fetchDataAndShowOverlay(phoneNumber: String) {
    // Cancel any existing fetch job
    fetchJob?.cancel()
    
    // Show loading overlay first
    showLoadingOverlay(phoneNumber)
    
    // Fetch data from Firebase
    fetchJob = CoroutineScope(Dispatchers.IO).launch {
        try {
            Log.d(TAG, "Fetching Firebase data for: $phoneNumber")
            
            // DEBUG: Check current user first
            val currentUser = FirebaseUserManager.getCurrentUser()
            Log.d(TAG, "DEBUG: Current user: ${currentUser?.uid}")
            Log.d(TAG, "DEBUG: User email: ${currentUser?.email}")
            Log.d(TAG, "DEBUG: Email verified: ${currentUser?.isEmailVerified}")
            
            // DEBUG: Get user info
            val userInfo = FirebaseUserManager.getCurrentUserInfo()
            Log.d(TAG, "DEBUG: User info: $userInfo")
            Log.d(TAG, "DEBUG: Custom claims: ${userInfo?.customClaims}")
            
            // DEBUG: Get user permissions
            val permissions = FirebaseUserManager.getUserPermissions()
            Log.d(TAG, "DEBUG: User permissions: $permissions")
            
            // Fetch lead data with user context
            val leadWithProperties = FirebaseUserManager.getUserContextualData(phoneNumber)
            
            withContext(Dispatchers.Main) {
                if (leadWithProperties != null) {
                    Log.d(TAG, "Found lead data: ${leadWithProperties.lead.name}")
                    showOverlayWithData(phoneNumber, leadWithProperties)
                } else {
                    Log.d(TAG, "No lead data found for: $phoneNumber")
                    showBasicOverlay(phoneNumber)
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching Firebase data: ${e.message}", e)
            withContext(Dispatchers.Main) {
                showBasicOverlay(phoneNumber)
            }
        }
    }
}

    /**
     * Show loading overlay while fetching data
     */
    private fun showLoadingOverlay(phoneNumber: String) {
        if (!canDrawOverlays()) {
            showToast("Incoming call: $phoneNumber")
            return
        }
        
        try {
            hideOverlay()
            
            overlayView = createLoadingOverlay(phoneNumber)
            
            val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                layoutFlag,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or 
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
                x = 0
                y = 0
            }
            
            windowManager?.addView(overlayView, params)
            isOverlayShowing = true
            
            Log.d(TAG, "Loading overlay shown for: $phoneNumber")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error showing loading overlay: ${e.message}")
            showToast("Incoming call: $phoneNumber")
        }
    }

    /**
     * Create loading overlay
     */
    private fun createLoadingOverlay(phoneNumber: String): View {
        val inflater = LayoutInflater.from(this)
        val view = inflater.inflate(R.layout.overlay_incoming_call, null)
        
        // Set loading state
        val tvName = view.findViewById<TextView>(R.id.tv_name)
        val tvOwnerLabel = view.findViewById<TextView>(R.id.tv_owner_label)
        val tvPropertyType = view.findViewById<TextView>(R.id.tv_property_type)
        val tvLocation = view.findViewById<TextView>(R.id.tv_location)
        val tvPrice = view.findViewById<TextView>(R.id.tv_price)
        val tvTargetAudience = view.findViewById<TextView>(R.id.tv_target_audience)
        val btnNewLead = view.findViewById<TextView>(R.id.btn_new_lead)
        val tvShowMore = view.findViewById<TextView>(R.id.tv_show_more)
        val btnDone = view.findViewById<TextView>(R.id.btn_done)
        
        tvName.text = formatPhoneNumber(phoneNumber)
        tvOwnerLabel.text = " (Incoming Call)"
        tvPropertyType.text = "Loading..."
        tvLocation.text = "Fetching lead details..."
        tvPrice.text = "Please wait..."
        tvTargetAudience.text = "Checking database..."
        
        // Set up button listeners
        btnNewLead.setOnClickListener {
            handleNewLead(phoneNumber)
            hideOverlay()
        }
        
        tvShowMore.setOnClickListener {
            handleShowMore(phoneNumber)
            hideOverlay()
        }
        
        btnDone.setOnClickListener {
            hideOverlay()
        }
        
        setupDragListener(view)
        
        return view
    }

    /**
     * Show overlay with Firebase data
     */
  private fun showOverlayWithData(phoneNumber: String, leadWithProperties: FirebaseDataFetcher.LeadWithProperties) {
    if (!canDrawOverlays()) {
        showToast("Lead found: ${leadWithProperties.lead.name}")
        return
    }

    try {
        hideOverlay()

        overlayView = createLeadCardOverlayWithData(phoneNumber, leadWithProperties)

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT, // Full screen width
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER 
            x = 0
            y = 0
        }

        windowManager?.addView(overlayView, params)
        isOverlayShowing = true

        Log.d(TAG, "Data overlay shown for lead: ${leadWithProperties.lead.name}")

        // Auto-hide after 45 seconds for data-rich overlay
        overlayJob = CoroutineScope(Dispatchers.Main).launch {
            delay(45000)
            hideOverlay()
        }

    } catch (e: Exception) {
        Log.e(TAG, "Error showing data overlay: ${e.message}")
        showBasicOverlay(phoneNumber)
    }
}

    /**
     * Create lead card overlay with Firebase data
     */
    private fun createLeadCardOverlayWithData(phoneNumber: String, leadWithProperties: FirebaseDataFetcher.LeadWithProperties): View {
        val inflater = LayoutInflater.from(this)
        val view = inflater.inflate(R.layout.overlay_incoming_call, null)
        
        val lead = leadWithProperties.lead
        val properties = leadWithProperties.properties
        val displayData = dataFetcher.formatDisplayData(leadWithProperties)
        
        // Get references to views
        val tvName = view.findViewById<TextView>(R.id.tv_name)
        val tvOwnerLabel = view.findViewById<TextView>(R.id.tv_owner_label)
        val btnNewLead = view.findViewById<TextView>(R.id.btn_new_lead)
        val tvPropertyType = view.findViewById<TextView>(R.id.tv_property_type)
        val tvLocation = view.findViewById<TextView>(R.id.tv_location)
        val tvPrice = view.findViewById<TextView>(R.id.tv_price)
        val tvTargetAudience = view.findViewById<TextView>(R.id.tv_target_audience)
        val tvShowMore = view.findViewById<TextView>(R.id.tv_show_more)
        val btnDone = view.findViewById<TextView>(R.id.btn_done)
        
        // Set data from Firebase
        tvName.text = lead.name
        tvOwnerLabel.text = " (${lead.leadType} - ${lead.status})"
        
        // Update button text based on lead status
        btnNewLead.text = if (lead.status.lowercase() == "active") "Update Lead" else "New Lead"
        
        // Set property details
        tvPropertyType.text = displayData.primaryProperty
        tvLocation.text = displayData.locationSummary
        tvPrice.text = displayData.priceSummary
        
        // Show property count and additional info
        val propertyCountText = when (properties.size) {
            0 -> "No properties listed"
            1 -> "1 property listed"
            else -> "${properties.size} properties listed"
        }
        tvTargetAudience.text = "📊 $propertyCountText"
        
        // Set up button listeners
        btnNewLead.setOnClickListener {
            Log.d(TAG, "Lead action clicked for: ${lead.name}")
            handleExistingLead(phoneNumber, lead.id ?: "")
            hideOverlay()
        }
        
        tvShowMore.setOnClickListener {
            Log.d(TAG, "Show more clicked for lead: ${lead.name}")
            handleShowLeadDetails(phoneNumber, lead.id ?: "")
            hideOverlay()
        }
        
        btnDone.setOnClickListener {
            Log.d(TAG, "Done button clicked")
            hideOverlay()
        }
        
        setupDragListener(view)
        
        return view
    }

    /**
     * Show basic overlay when no Firebase data is found
     */
    private fun showBasicOverlay(phoneNumber: String) {
        if (!canDrawOverlays()) {
            showToast("Incoming call: $phoneNumber")
            return
        }
        
        try {
            hideOverlay()
            
            overlayView = createBasicOverlay(phoneNumber)
            
            val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                layoutFlag,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or 
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
                x = 0
                y = 0
            }
            
            windowManager?.addView(overlayView, params)
            isOverlayShowing = true
            
            Log.d(TAG, "Basic overlay shown for: $phoneNumber")
            
            // Auto-hide after 40 seconds
            overlayJob = CoroutineScope(Dispatchers.Main).launch {
                delay(40000)
                hideOverlay()
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error showing basic overlay: ${e.message}")
            showToast("Incoming call: $phoneNumber")
        }
    }

    /**
     * Create basic overlay for unknown numbers
     */
    private fun createBasicOverlay(phoneNumber: String): View {
        val inflater = LayoutInflater.from(this)
        val view = inflater.inflate(R.layout.overlay_incoming_call, null)
        
        val contactInfo = getContactInfo(phoneNumber)
        
        val tvName = view.findViewById<TextView>(R.id.tv_name)
        val tvOwnerLabel = view.findViewById<TextView>(R.id.tv_owner_label)
        val btnNewLead = view.findViewById<TextView>(R.id.btn_new_lead)
        val tvPropertyType = view.findViewById<TextView>(R.id.tv_property_type)
        val tvLocation = view.findViewById<TextView>(R.id.tv_location)
        val tvPrice = view.findViewById<TextView>(R.id.tv_price)
        val tvTargetAudience = view.findViewById<TextView>(R.id.tv_target_audience)
        val tvShowMore = view.findViewById<TextView>(R.id.tv_show_more)
        val btnDone = view.findViewById<TextView>(R.id.btn_done)
        
        // Set basic call info
        tvName.text = contactInfo.name ?: formatPhoneNumber(phoneNumber)
        tvOwnerLabel.text = if (contactInfo.name != null) " (Contact)" else " (Unknown Number)"
        
        // Set default property details
        tvPropertyType.text = "📞 New Incoming Call"
        tvLocation.text = "From: ${formatPhoneNumber(phoneNumber)}"
        tvPrice.text = "⏰ Active Call"
        tvTargetAudience.text = "💼 Potential Lead"
        
        // Set up button listeners
        btnNewLead.setOnClickListener {
            Log.d(TAG, "New Lead button clicked for: $phoneNumber")
            handleNewLead(phoneNumber)
            hideOverlay()
        }
        
        tvShowMore.setOnClickListener {
            Log.d(TAG, "Show more clicked for: $phoneNumber")
            handleShowMore(phoneNumber)
            hideOverlay()
        }
        
        btnDone.setOnClickListener {
            Log.d(TAG, "Done button clicked")
            hideOverlay()
        }
        
        setupDragListener(view)
        
        return view
    }

    /**
     * Handle existing lead button click
     */
    private fun handleExistingLead(phoneNumber: String, leadId: String) {
        try {
            Log.d(TAG, "Handling existing lead: $leadId for: $phoneNumber")

            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("action", "edit_lead")
                putExtra("phoneNumber", phoneNumber)
                putExtra("leadId", leadId)
                putExtra("navigate_to", "lead_details")
                putExtra("edit_mode", true)
                putExtra("timestamp", System.currentTimeMillis())
            }
            startActivity(intent)

            showToast("Opening lead for editing...")

        } catch (e: Exception) {
            Log.e(TAG, "Error handling existing lead: ${e.message}")
            showToast("Could not open lead")
        }
    }

    /**
     * Handle show lead details button click
     */
    private fun handleShowLeadDetails(phoneNumber: String, leadId: String) {
        try {
            Log.d(TAG, "Show lead details for: $leadId")

            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("action", "show_lead_details")
                putExtra("phoneNumber", phoneNumber)
                putExtra("leadId", leadId)
                putExtra("navigate_to", "lead_details")
                putExtra("timestamp", System.currentTimeMillis())
            }
            startActivity(intent)

            // Also send broadcast for any listening components
            val broadcastIntent = Intent("com.taro.mobileapp.SHOW_LEAD_DETAILS").apply {
                putExtra("phoneNumber", phoneNumber)
                putExtra("leadId", leadId)
                putExtra("timestamp", System.currentTimeMillis())
                addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES)
            }
            sendBroadcast(broadcastIntent)

            showToast("Opening lead details...")

        } catch (e: Exception) {
            Log.e(TAG, "Error showing lead details: ${e.message}")
            showToast("Could not open lead details")
        }
    }

    /**
     * Data class for contact information
     */
    private data class ContactInfo(
        val name: String?,
        val type: String?
    )

    /**
     * Get contact info from phone number
     */
    private fun getContactInfo(phoneNumber: String): ContactInfo {
        return try {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) 
                != PackageManager.PERMISSION_GRANTED) {
                return ContactInfo(null, null)
            }
            
            val uri = android.net.Uri.withAppendedPath(
                android.provider.ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                android.net.Uri.encode(phoneNumber)
            )
            
            val cursor = contentResolver.query(
                uri,
                arrayOf(
                    android.provider.ContactsContract.PhoneLookup.DISPLAY_NAME,
                    android.provider.ContactsContract.PhoneLookup.TYPE
                ),
                null, null, null
            )
            
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(android.provider.ContactsContract.PhoneLookup.DISPLAY_NAME)
                    val typeIndex = it.getColumnIndex(android.provider.ContactsContract.PhoneLookup.TYPE)
                    
                    val name = if (nameIndex >= 0) it.getString(nameIndex) else null
                    val type = if (typeIndex >= 0) it.getString(typeIndex) else null
                    
                    return ContactInfo(name, type)
                }
            }
            ContactInfo(null, null)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting contact info: ${e.message}")
            ContactInfo(null, null)
        }
    }

    /**
     * Format phone number for display
     */
    private fun formatPhoneNumber(phoneNumber: String): String {
        return when {
            phoneNumber.length == 10 -> {
                "${phoneNumber.substring(0, 3)}-${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6)}"
            }
            phoneNumber.length > 10 -> {
                "+${phoneNumber.substring(0, phoneNumber.length - 10)} ${formatPhoneNumber(phoneNumber.substring(phoneNumber.length - 10))}"
            }
            else -> phoneNumber
        }
    }

    /**
     * Handle new lead button click
     */
    private fun handleNewLead(phoneNumber: String) {
        try {
            Log.d(TAG, "Creating new lead for: $phoneNumber")
            
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "new_lead")
                putExtra("phoneNumber", phoneNumber)
            }
            startActivity(intent)
            
            showToast("Creating new lead for $phoneNumber")
        } catch (e: Exception) {
            Log.e(TAG, "Error creating new lead: ${e.message}")
            showToast("Could not create lead")
        }
    }

    /**
     * Handle show more button click
     */
    private fun handleShowMore(phoneNumber: String) {
        try {
            Log.d(TAG, "Show more clicked for: $phoneNumber")

            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("action", "show_call_details")
                putExtra("phoneNumber", phoneNumber)
                putExtra("navigate_to", "call_details")
                putExtra("timestamp", System.currentTimeMillis())
            }
            startActivity(intent)

            showToast("Opening call details...")

        } catch (e: Exception) {
            Log.e(TAG, "Error showing call details: ${e.message}")
        }
    }

    /**
     * Setup drag listener for overlay
     */
    private fun setupDragListener(view: View) {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        
        view.setOnTouchListener { v, event ->
            when (event.action) {
                android.view.MotionEvent.ACTION_DOWN -> {
                    val params = v.layoutParams as WindowManager.LayoutParams
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                android.view.MotionEvent.ACTION_MOVE -> {
                    val params = v.layoutParams as WindowManager.LayoutParams
                    params.x = initialX + (event.rawX - initialTouchX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    windowManager?.updateViewLayout(v, params)
                    true
                }
                else -> false
            }
        }
    }
    /**
     * Hide the overlay
     */
    private fun hideOverlay() {
        try {
            overlayJob?.cancel()
            fetchJob?.cancel()
            if (isOverlayShowing && overlayView != null) {
                windowManager?.removeView(overlayView)
                overlayView = null
                isOverlayShowing = false
                Log.d(TAG, "Overlay hidden")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding overlay: ${e.message}")
        }
    }

    /**
     * Check if app can draw overlays
     */
    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            android.provider.Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    /**
     * Show toast as fallback
     */
    private fun showToast(message: String) {
        try {
            CoroutineScope(Dispatchers.Main).launch {
                Toast.makeText(this@CallDetectionService, message, Toast.LENGTH_LONG).show()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error showing toast: ${e.message}")
        }
    }

    private fun extractCleanPhoneNumber(phoneNumber: String): String {
        var cleaned = phoneNumber.replace(Regex("[^\\d]"), "")
        
        when {
            cleaned.startsWith("91") && cleaned.length == 12 -> {
                cleaned = cleaned.substring(2)
            }
            cleaned.startsWith("1") && cleaned.length == 11 -> {
                cleaned = cleaned.substring(1)
            }
            cleaned.startsWith("44") && cleaned.length > 10 -> {
                cleaned = cleaned.substring(2)
            }
        }
        
        if (cleaned.length < 10) {
            return phoneNumber.replace(Regex("[^\\d]"), "")
        }
        
        return cleaned
    }

    /**
     * Notify Flutter app about incoming call WITHOUT opening the app
     */
    private fun notifyFlutterIncomingCallSilent(cleanPhoneNumber: String) {
        try {
            mainActivity?.let { activity ->
                try {
                    activity.runOnUiThread {
                        activity.notifyIncomingCall(cleanPhoneNumber)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending via direct channel: ${e.message}")
                }
            }
            
            val intent = Intent("com.taro.mobileapp.INCOMING_CALL").apply {
                putExtra("phoneNumber", cleanPhoneNumber)
                putExtra("callState", "RINGING")
                putExtra("timestamp", System.currentTimeMillis())
                addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES)
            }
            sendBroadcast(intent)
            
            Log.d(TAG, "Silent notification sent for: $cleanPhoneNumber")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error notifying Flutter about incoming call: ${e.message}")
        }
    }

   
    private fun notifyFlutterCallEnded() {
        try {
            mainActivity?.let { activity ->
                try {
                    activity.runOnUiThread {
                        activity.notifyCallEnded()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending call ended via direct channel: ${e.message}")
                }
            }
            
            val intent = Intent("com.taro.mobileapp.CALL_ENDED").apply {
                putExtra("timestamp", System.currentTimeMillis())
                addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES)
            }
            sendBroadcast(intent)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error notifying Flutter about call end: ${e.message}")
        }
    }
}