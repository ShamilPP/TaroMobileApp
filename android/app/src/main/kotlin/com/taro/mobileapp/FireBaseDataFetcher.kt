// FirebaseDataFetcher.kt - Service to fetch display data using phone number
package com.taro.mobileapp

import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import kotlinx.coroutines.*
import kotlinx.coroutines.tasks.await

/**
 * Service class to fetch lead and property data from Firebase using phone number
 */
class FirebaseDataFetcher {
    
    private val firestore = FirebaseFirestore.getInstance()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    companion object {
        private const val TAG = "FirebaseDataFetcher"
        private const val LEADS_COLLECTION = "leads"
        private const val RESIDENTIAL_COLLECTION = "Residential"
        private const val COMMERCIAL_COLLECTION = "Commercial"
        private const val PLOTS_COLLECTION = "Plots"
    }

    /**
     * Data classes to match Flutter models
     */
    data class LeadModel(
        val id: String?,
        val name: String,
        val phoneNumber: String,
        val leadType: String,
        val status: String,
        val createdAt: Long? = null,
        val updatedAt: Long? = null
    )

    data class BaseProperty(
        val id: String,
        val leadId: String,
        val propertyFor: String,
        val location: String?,
        val askingPrice: String?,
        val status: String,
        val type: String // "Residential", "Commercial", "Plots"
    )

    data class ResidentialProperty(
        val id: String,
        val leadId: String,
        val propertyFor: String,
        val location: String?,
        val askingPrice: String?,
        val status: String,
        val selectedBHK: String?,
        val propertyType: String?,
        val propertySubType: String?,
        val furnished: Boolean?,
        val preferUnfurnished: Boolean?,
        val preferSemiFurnished: Boolean?,
        val facilities: List<String>,
        val preferences: List<String>
    ) {
        fun toBaseProperty() = BaseProperty(id, leadId, propertyFor, location, askingPrice, status, "Residential")
    }

    data class CommercialProperty(
        val id: String,
        val leadId: String,
        val propertyFor: String,
        val location: String?,
        val askingPrice: String?,
        val status: String,
        val propertySubType: String,
        val squareFeet: String?,
        val facilities: String?,
        val furnished: String?
    ) {
        fun toBaseProperty() = BaseProperty(id, leadId, propertyFor, location, askingPrice, status, "Commercial")
    }

    data class LandProperty(
        val id: String,
        val leadId: String,
        val propertyFor: String,
        val location: String?,
        val askingPrice: String?,
        val status: String,
        val propertySubType: String,
        val cents: String?,
        val acres: String?,
        val additionalNotes: String?
    ) {
        fun toBaseProperty() = BaseProperty(id, leadId, propertyFor, location, askingPrice, status, "Plots")
    }

    data class LeadWithProperties(
        val lead: LeadModel,
        val properties: List<BaseProperty>
    )

    /**
     * Main function to fetch lead data by phone number
     */
    suspend fun fetchLeadByPhoneNumber(phoneNumber: String): LeadWithProperties? {
        return try {
            val cleanedNumber = cleanPhoneNumber(phoneNumber)
            Log.d(TAG, "Fetching lead data for phone number: $cleanedNumber")
            
            // First, find the lead by phone number
            val lead = findLeadByPhoneNumber(cleanedNumber)
            if (lead == null) {
                Log.d(TAG, "No lead found for phone number: $cleanedNumber")
                return null
            }
            
            Log.d(TAG, "Found lead: ${lead.name} (ID: ${lead.id})")
            
            // Then fetch all properties for this lead
            val properties = fetchPropertiesForLead(lead.id ?: "")
            
            Log.d(TAG, "Found ${properties.size} properties for lead: ${lead.name}")
            
            LeadWithProperties(lead, properties)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching lead data: ${e.message}", e)
            null
        }
    }

    /**
     * Find lead by phone number
     */
    private suspend fun findLeadByPhoneNumber(phoneNumber: String): LeadModel? {
        return try {
            val cleanedNumbers = generatePhoneNumberVariations(phoneNumber)
            Log.d(TAG, "Searching for phone number variations: $cleanedNumbers")
            
            for (number in cleanedNumbers) {
                val querySnapshot = firestore.collection(LEADS_COLLECTION)
                    .whereEqualTo("phoneNumber", number)
                    .limit(1)
                    .get()
                    .await()
                
                if (!querySnapshot.isEmpty) {
                    val document = querySnapshot.documents.first()
                    val data = document.data ?: continue
                    
                    return LeadModel(
                        id = document.id,
                        name = data["name"] as? String ?: "",
                        phoneNumber = data["phoneNumber"] as? String ?: "",
                        leadType = data["leadType"] as? String ?: "",
                        status = data["status"] as? String ?: "",
                        createdAt = data["createdAt"] as? Long,
                        updatedAt = data["updatedAt"] as? Long
                    )
                }
            }
            
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error finding lead by phone number: ${e.message}", e)
            null
        }
    }

    /**
     * Fetch all properties for a specific lead ID
     */
    private suspend fun fetchPropertiesForLead(leadId: String): List<BaseProperty> {
        val allProperties = mutableListOf<BaseProperty>()
        
        try {
            // Fetch from all three collections concurrently
            val deferredResults = listOf(
                scope.async { fetchResidentialProperties(leadId) },
                scope.async { fetchCommercialProperties(leadId) },
                scope.async { fetchLandProperties(leadId) }
            )
            
            val results = deferredResults.awaitAll()
            results.forEach { properties ->
                allProperties.addAll(properties)
            }
            
            Log.d(TAG, "Total properties fetched for leadId $leadId: ${allProperties.size}")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching properties for lead: ${e.message}", e)
        }
        
        return allProperties
    }

    /**
     * Fetch residential properties
     */
    private suspend fun fetchResidentialProperties(leadId: String): List<BaseProperty> {
        return try {
            val querySnapshot = firestore.collection(RESIDENTIAL_COLLECTION)
                .whereEqualTo("leadId", leadId)
                .whereNotEqualTo("status", "Inactive")
                .get()
                .await()
            
            querySnapshot.documents.mapNotNull { doc ->
                try {
                    val data = doc.data ?: return@mapNotNull null
                    
                    ResidentialProperty(
                        id = doc.id,
                        leadId = data["leadId"] as? String ?: "",
                        propertyFor = data["propertyFor"] as? String ?: "",
                        location = data["location"] as? String,
                        askingPrice = data["askingPrice"] as? String,
                        status = data["status"] as? String ?: "",
                        selectedBHK = data["selectedBHK"] as? String,
                        propertyType = data["propertyType"] as? String,
                        propertySubType = data["propertySubType"] as? String,
                        furnished = data["furnished"] as? Boolean,
                        preferUnfurnished = data["preferUnfurnished"] as? Boolean,
                        preferSemiFurnished = data["preferSemiFurnished"] as? Boolean,
                        facilities = (data["facilities"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList(),
                        preferences = (data["preferences"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
                    ).toBaseProperty()
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing residential property: ${e.message}")
                    null
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching residential properties: ${e.message}")
            emptyList()
        }
    }

    /**
     * Fetch commercial properties
     */
    private suspend fun fetchCommercialProperties(leadId: String): List<BaseProperty> {
        return try {
            val querySnapshot = firestore.collection(COMMERCIAL_COLLECTION)
                .whereEqualTo("leadId", leadId)
                .whereNotEqualTo("status", "Inactive")
                .get()
                .await()
            
            querySnapshot.documents.mapNotNull { doc ->
                try {
                    val data = doc.data ?: return@mapNotNull null
                    
                    CommercialProperty(
                        id = doc.id,
                        leadId = data["leadId"] as? String ?: "",
                        propertyFor = data["propertyFor"] as? String ?: "",
                        location = data["location"] as? String,
                        askingPrice = data["askingPrice"] as? String,
                        status = data["status"] as? String ?: "",
                        propertySubType = data["propertySubType"] as? String ?: "",
                        squareFeet = data["squareFeet"] as? String,
                        facilities = data["facilities"] as? String,
                        furnished = data["furnished"] as? String
                    ).toBaseProperty()
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing commercial property: ${e.message}")
                    null
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching commercial properties: ${e.message}")
            emptyList()
        }
    }

    /**
     * Fetch land properties
     */
    private suspend fun fetchLandProperties(leadId: String): List<BaseProperty> {
        return try {
            val querySnapshot = firestore.collection(PLOTS_COLLECTION)
                .whereEqualTo("leadId", leadId)
                .whereNotEqualTo("status", "Inactive")
                .get()
                .await()
            
            querySnapshot.documents.mapNotNull { doc ->
                try {
                    val data = doc.data ?: return@mapNotNull null
                    
                    LandProperty(
                        id = doc.id,
                        leadId = data["leadId"] as? String ?: "",
                        propertyFor = data["propertyFor"] as? String ?: "",
                        location = data["location"] as? String,
                        askingPrice = data["askingPrice"] as? String,
                        status = data["status"] as? String ?: "",
                        propertySubType = data["propertySubType"] as? String ?: "",
                        cents = data["cents"] as? String,
                        acres = data["acres"] as? String,
                        additionalNotes = data["additionalNotes"] as? String
                    ).toBaseProperty()
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing land property: ${e.message}")
                    null
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching land properties: ${e.message}")
            emptyList()
        }
    }

    /**
     * Clean and normalize phone number
     */
    private fun cleanPhoneNumber(phoneNumber: String): String {
        var cleaned = phoneNumber.replace(Regex("[^\\d]"), "")
        
        // Handle country codes
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
        
        return if (cleaned.length < 10) {
            phoneNumber.replace(Regex("[^\\d]"), "")
        } else {
            cleaned
        }
    }

    /**
     * Generate different variations of phone number to search
     */
    private fun generatePhoneNumberVariations(phoneNumber: String): List<String> {
        val cleaned = cleanPhoneNumber(phoneNumber)
        val variations = mutableSetOf<String>()
        
        // Add the cleaned number
        variations.add(cleaned)
        
        // Add with country codes
        if (cleaned.length == 10) {
            variations.add("91$cleaned") // India
            variations.add("1$cleaned")  // US
        }
        
        // Add formatted versions
        if (cleaned.length == 10) {
            variations.add("${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}")
            variations.add("${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}")
            variations.add("(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}")
        }
        
        // Add original number as well
        variations.add(phoneNumber)
        
        return variations.toList()
    }

    /**
     * Format display data for overlay
     */
    fun formatDisplayData(leadWithProperties: LeadWithProperties): DisplayData {
        val lead = leadWithProperties.lead
        val properties = leadWithProperties.properties
        
        return DisplayData(
            name = lead.name,
            phoneNumber = formatPhoneForDisplay(lead.phoneNumber),
            leadType = lead.leadType,
            status = lead.status,
            propertyCount = properties.size,
            primaryProperty = formatPrimaryProperty(properties.firstOrNull()),
            locationSummary = formatLocationSummary(properties),
            priceSummary = formatPriceSummary(properties)
        )
    }

    /**
     * Data class for formatted display data
     */
    data class DisplayData(
        val name: String,
        val phoneNumber: String,
        val leadType: String,
        val status: String,
        val propertyCount: Int,
        val primaryProperty: String,
        val locationSummary: String,
        val priceSummary: String
    )

    private fun formatPhoneForDisplay(phoneNumber: String): String {
        val cleaned = cleanPhoneNumber(phoneNumber)
        return when {
            cleaned.length == 10 -> {
                "${cleaned.substring(0, 3)}${cleaned.substring(3, 6)}${cleaned.substring(6)}"
            }
            cleaned.length > 10 -> {
                "+${cleaned.substring(0, cleaned.length - 10)} ${formatPhoneForDisplay(cleaned.substring(cleaned.length - 10))}"
            }
            else -> phoneNumber
        }
    }

    private fun formatPrimaryProperty(property: BaseProperty?): String {
        return when {
            property == null -> "No properties"
            property.type == "Residential" -> " ${property.propertyFor}"
            property.type == "Commercial" -> " ${property.propertyFor}"
            property.type == "Plots" -> " ${property.propertyFor}"
            else -> property.propertyFor
        }
    }

    private fun formatLocationSummary(properties: List<BaseProperty>): String {
        val locations = properties.mapNotNull { it.location }
            .map { it.split(",").first().trim().split(" ").first() }
            .distinct()
            .take(2)
        
        return if (locations.isNotEmpty()) {
            " ${locations.joinToString(", ")}"
        } else {
            "📍 Location not specified"
        }
    }

    private fun formatPriceSummary(properties: List<BaseProperty>): String {
        val prices = properties.mapNotNull { property ->
            property.askingPrice?.let { price ->
                formatPrice(price)
            }
        }.distinct().take(2)
        
        return if (prices.isNotEmpty()) {
            " ${prices.joinToString(", ")}"
        } else {
            "💰 Price on request"
        }
    }

    private fun formatPrice(price: String?): String {
        if (price.isNullOrEmpty()) return ""
        
        return try {
            val numericPrice = price.replace(Regex("[^\\d.]"), "").toDoubleOrNull()
            when {
                numericPrice == null -> price
                numericPrice >= 10000000 -> "₹${(numericPrice / 10000000).toInt()}Cr"
                numericPrice >= 100000 -> "₹${(numericPrice / 100000).toInt()}L"
                numericPrice >= 1000 -> "₹${(numericPrice / 1000).toInt()}K"
                else -> "₹${numericPrice.toInt()}"
            }
        } catch (e: Exception) {
            price
        }
    }

    /**
     * Cleanup resources
     */
    fun cleanup() {
        scope.cancel()
    }
}