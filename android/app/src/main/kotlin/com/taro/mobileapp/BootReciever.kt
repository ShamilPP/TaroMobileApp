package com.taro.mobileapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d(TAG, "BootReceiver onReceive: ${intent?.action}")
        
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                Log.d(TAG, "Device boot completed or package replaced - starting call detection service")
                
                context?.let {
                    try {
                        val serviceIntent = Intent(it, CallDetectionService::class.java)
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            it.startForegroundService(serviceIntent)
                        } else {
                            it.startService(serviceIntent)
                        }
                        
                        Log.d(TAG, "Call detection service started after boot")
                    } catch (e: Exception) {
                        Log.e(TAG, "Error starting call detection service after boot", e)
                    }
                }
            }
        }
    }
}