// FirebaseUserManager.kt - Manages Firebase user authentication in native Android
package com.taro.mobileapp

import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.*
import kotlinx.coroutines.tasks.await

/**
 * Singleton class to manage Firebase user authentication and user data
 */
object FirebaseUserManager {
    
    private const val TAG = "FirebaseUserManager"
    private const val USERS_COLLECTION = "users"
    
    private val firebaseAuth = FirebaseAuth.getInstance()
    private val firestore = FirebaseFirestore.getInstance()
    
    /**
     * Data class for user information
     */
    data class UserInfo(
        val uid: String,
        val email: String?,
        val displayName: String?,
        val phoneNumber: String?,
        val isEmailVerified: Boolean,
        val photoUrl: String?,
        val customClaims: Map<String, Any>? = null,
        val additionalUserData: Map<String, Any>? = null
    )
    
    /**
     * Get current Firebase user
     */
    fun getCurrentUser(): FirebaseUser? {
        val user = firebaseAuth.currentUser
        Log.d(TAG, "Current user: ${user?.uid}")
        return user
    }
    
    /**
     * Check if user is authenticated
     */
    fun isUserAuthenticated(): Boolean {
        val isAuth = firebaseAuth.currentUser != null
        Log.d(TAG, "User authenticated: $isAuth")
        return isAuth
    }
    
    /**
     * Get current user info as UserInfo data class
     */
    suspend fun getCurrentUserInfo(): UserInfo? {
        return try {
            val user = getCurrentUser() ?: return null
            
            Log.d(TAG, "Getting user info for UID: ${user.uid}")
            
            // Get ID token to access custom claims
            val idTokenResult = user.getIdToken(false).await()
            val customClaims = idTokenResult.claims
            
            // Try to get additional user data from Firestore
            val additionalData = getUserDataFromFirestore(user.uid)
            
            UserInfo(
                uid = user.uid,
                email = user.email,
                displayName = user.displayName,
                phoneNumber = user.phoneNumber,
                isEmailVerified = user.isEmailVerified,
                photoUrl = user.photoUrl?.toString(),
                customClaims = customClaims,
                additionalUserData = additionalData
            )
            
        } catch (e: Exception) {
            Log.e(TAG, "Error getting current user info: ${e.message}", e)
            null
        }
    }
    
    /**
     * Get user data from Firestore users collection
     */
    private suspend fun getUserDataFromFirestore(uid: String): Map<String, Any>? {
        return try {
            Log.d(TAG, "Fetching user data from Firestore for UID: $uid")
            
            val document = firestore.collection(USERS_COLLECTION)
                .document(uid)
                .get()
                .await()
            
            if (document.exists()) {
                val data = document.data
                Log.d(TAG, "Found user data in Firestore: ${data?.keys}")
                data
            } else {
                Log.d(TAG, "No user document found in Firestore for UID: $uid")
                null
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching user data from Firestore: ${e.message}", e)
            null
        }
    }
    
    /**
     * Get user role or permissions from custom claims
     */
    suspend fun getUserRole(): String? {
        return try {
            val userInfo = getCurrentUserInfo()
            val role = userInfo?.customClaims?.get("role") as? String
            Log.d(TAG, "User role: $role")
            role
        } catch (e: Exception) {
            Log.e(TAG, "Error getting user role: ${e.message}", e)
            null
        }
    }
    
    /**
     * Get user permissions from custom claims
     */
    suspend fun getUserPermissions(): List<String> {
        return try {
            val userInfo = getCurrentUserInfo()
            val permissions = userInfo?.customClaims?.get("permissions") as? List<*>
            val permissionList = permissions?.mapNotNull { it as? String } ?: emptyList()
            Log.d(TAG, "User permissions: $permissionList")
            permissionList
        } catch (e: Exception) {
            Log.e(TAG, "Error getting user permissions: ${e.message}", e)
            emptyList()
        }
    }
    
    /**
     * Get specific user data field from Firestore
     */
    suspend fun getUserDataField(fieldName: String): Any? {
        return try {
            val user = getCurrentUser() ?: return null
            val userData = getUserDataFromFirestore(user.uid)
            val fieldValue = userData?.get(fieldName)
            Log.d(TAG, "User data field '$fieldName': $fieldValue")
            fieldValue
        } catch (e: Exception) {
            Log.e(TAG, "Error getting user data field '$fieldName': ${e.message}", e)
            null
        }
    }
    
    /**
     * Update FirebaseDataFetcher to use current user context
     */
    suspend fun getUserContextualData(phoneNumber: String): FirebaseDataFetcher.LeadWithProperties? {
        return try {
            val userInfo = getCurrentUserInfo()
            if (userInfo == null) {
                Log.e(TAG, "No authenticated user found")
                return null
            }
            
            Log.d(TAG, "Fetching data for user: ${userInfo.uid}, phone: $phoneNumber")
            
            // You can add user-specific filtering here if needed
            val dataFetcher = FirebaseDataFetcher()
            val result = dataFetcher.fetchLeadByPhoneNumber(phoneNumber)
            
            // Log for security/audit purposes
            if (result != null) {
                Log.d(TAG, "User ${userInfo.uid} accessed lead data for phone: $phoneNumber")
            }
            
            result
            
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching user contextual data: ${e.message}", e)
            null
        }
    }
    
    /**
     * Check if user has permission to access lead data
     */
    suspend fun canAccessLeadData(): Boolean {
        return try {
            val user = getCurrentUser()
            if (user == null) {
                Log.d(TAG, "No user authenticated - access denied")
                return false
            }
            
            // Check if user is verified
            if (!user.isEmailVerified && user.email != null) {
                Log.d(TAG, "User email not verified - access limited")
                return false
            }
            
            // Check custom claims for permissions
            val permissions = getUserPermissions()
            val hasAccess = permissions.contains("read_leads") || 
                           permissions.contains("admin") ||
                           permissions.isEmpty() // Allow if no permissions set (default access)
            
            Log.d(TAG, "User access to lead data: $hasAccess")
            hasAccess
            
        } catch (e: Exception) {
            Log.e(TAG, "Error checking lead data access: ${e.message}", e)
            false
        }
    }
    
    /**
     * Add authentication state listener
     */
    fun addAuthStateListener(listener: FirebaseAuth.AuthStateListener) {
        firebaseAuth.addAuthStateListener(listener)
        Log.d(TAG, "Auth state listener added")
    }
    
    /**
     * Remove authentication state listener
     */
    fun removeAuthStateListener(listener: FirebaseAuth.AuthStateListener) {
        firebaseAuth.removeAuthStateListener(listener)
        Log.d(TAG, "Auth state listener removed")
    }
    
    /**
     * Get user's display name or fallback to email
     */
    fun getUserDisplayName(): String {
        val user = getCurrentUser()
        return when {
            !user?.displayName.isNullOrEmpty() -> user?.displayName ?: "Unknown User"
            !user?.email.isNullOrEmpty() -> user?.email ?: "Unknown User"
            !user?.phoneNumber.isNullOrEmpty() -> user?.phoneNumber ?: "Unknown User"
            else -> "Unknown User"
        }
    }
}