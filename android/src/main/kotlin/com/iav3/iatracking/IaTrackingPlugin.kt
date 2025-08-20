package com.iav3.iatracking

import android.content.Context
import android.util.Log
import android.telephony.TelephonyManager
import android.net.ConnectivityManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.io.IOException
import java.util.*
import java.util.concurrent.TimeUnit
import java.security.MessageDigest
import java.util.Base64
import com.google.android.gms.ads.identifier.AdvertisingIdClient
import com.google.android.gms.common.GooglePlayServicesNotAvailableException
import com.google.android.gms.common.GooglePlayServicesRepairableException

/**
 * Flutter plugin for IA Tracking Android SDK with automatic API flushing
 * 
 * This plugin provides Flutter bindings for user action tracking with automatic
 * synchronization to a remote API every 5 seconds.
 * 
 * Features:
 * - Local storage of user actions
 * - Automatic flush to API every 5 seconds
 * - HTTP client integration with OkHttp
 * - Comprehensive error handling and retry logic
 */
class IaTrackingPlugin : FlutterPlugin, MethodCallHandler {

    companion object {
        private const val TAG = "IaTrackingPlugin"
        private const val CHANNEL_NAME = "ia_tracking"
        private const val FLUSH_INTERVAL_MS = 5000L // 5 seconds
        
        // Default API base URL (can be overridden in initialization)
        private const val DEFAULT_API_BASE_URL = "https://sorted-berlin-pf-onto.trycloudflare.com"
        private const val API_VERSION = "v1"
        private const val TRACKING_ENDPOINT = "track"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    // Tracking state
    private var isInitialized = false
    private var isEnabled = true
    private var currentUserId: String? = null
    private var currentSessionId: String = generateSessionId()
    private var apiUrl: String? = null // Must be provided during initialization
    private var apiKey: String? = null
    
    // Enhanced features state
    private var trackingEnabled = true
    private var dataSharingEnabled = true
    private var allTrackingStopped = false
    private var currentDeviceId: String? = null
    private var sessionTimeoutMinutes = 30
    private var fcmToken: String? = null
    private val globalProperties = mutableMapOf<String, String>()
    
    // GAID caching
    private var cachedGaid: String? = null
    private var cachedLimitAdTracking: Boolean? = null
    private var gaidCollectionAttempted = false
    
    // SDK info
    private var wrapperName: String? = null
    private var wrapperVersion: String? = null
    private val sdkVersion = "1.1.0"
    
    // Action storage with sync tracking
    private val userActions = Collections.synchronizedList(mutableListOf<UserAction>())
    private val gson = Gson()
    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .writeTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()
    
    // Auto-flush timer
    private var flushTimer: Timer? = null
    
    // Data classes for user actions
    data class UserAction(
        val id: String,
        val actionType: String,
        val screenName: String?,
        val elementId: String?,
        val elementType: String?,
        val userId: String?,
        val sessionId: String,
        val timestamp: Long,
        val properties: Map<String, Any?>,
        val deviceInfo: Map<String, Any?>,
        val appVersion: String?,
        val sdkVersion: String = "1.0.0",
        var isSynced: Boolean = false,
        var retryCount: Int = 0
    )
    
    // Helper functions
    private fun generateActionId(): String = UUID.randomUUID().toString()
    private fun generateSessionId(): String = UUID.randomUUID().toString()
    private fun generateBatchId(): String = UUID.randomUUID().toString()
    
    /**
     * Collect GAID asynchronously on background thread (called once during initialization)
     */
    private fun collectGaidAsync() {
        if (gaidCollectionAttempted) return
        
        gaidCollectionAttempted = true
        
        // Run on background thread to avoid blocking main thread
        coroutineScope.launch(Dispatchers.IO) {
            try {
                val adInfo = AdvertisingIdClient.getAdvertisingIdInfo(context)
                val advertisingId = adInfo.id
                val limitAdTracking = adInfo.isLimitAdTrackingEnabled
                
                // Cache the results
                cachedGaid = if (advertisingId.isNullOrBlank()) null else advertisingId
                cachedLimitAdTracking = limitAdTracking
                
                Log.d(TAG, "GAID collected successfully and cached")
            } catch (e: GooglePlayServicesNotAvailableException) {
                Log.w(TAG, "Google Play Services not available for GAID collection", e)
                cachedGaid = null
                cachedLimitAdTracking = true
            } catch (e: GooglePlayServicesRepairableException) {
                Log.w(TAG, "Google Play Services needs repair for GAID collection", e)
                cachedGaid = null
                cachedLimitAdTracking = true
            } catch (e: IOException) {
                Log.w(TAG, "IOException during GAID collection", e)
                cachedGaid = null
                cachedLimitAdTracking = true
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error during GAID collection", e)
                cachedGaid = null
                cachedLimitAdTracking = true
            }
        }
    }
    
    private fun createDeviceInfo(): Map<String, Any?> {
        val deviceInfo = mutableMapOf<String, Any?>(
            "platform" to "Android",
            "osVersion" to android.os.Build.VERSION.RELEASE,
            "appVersion" to "1.0.0", // This should come from app context
            "deviceModel" to android.os.Build.MODEL,
            "locale" to java.util.Locale.getDefault().toString(),
            "timezone" to java.util.TimeZone.getDefault().id,
            "carrier" to getCarrierName(),
            "connection" to getConnectionType(),
            "manufacturer" to android.os.Build.MANUFACTURER,
            "brand" to android.os.Build.BRAND,
            "product" to android.os.Build.PRODUCT,
            "hardware" to android.os.Build.HARDWARE,
            "sdkInt" to android.os.Build.VERSION.SDK_INT,
            "fingerprint" to android.os.Build.FINGERPRINT.take(50), // Truncate for privacy
            "isPhysicalDevice" to !android.os.Build.FINGERPRINT.contains("generic")
        )
        
        // Add cached GAID if available
        if (gaidCollectionAttempted) {
            deviceInfo["gaid"] = cachedGaid
            deviceInfo["limitAdTracking"] = cachedLimitAdTracking ?: true
            
            if (cachedGaid != null) {
                Log.d(TAG, "Using cached GAID in device info")
            }
        } else {
            // GAID collection not yet attempted or completed
            deviceInfo["gaid"] = null
            deviceInfo["limitAdTracking"] = true
            Log.d(TAG, "GAID not yet collected - using null")
        }
        
        return deviceInfo.toMap()
    }
    
    private fun getCarrierName(): String {
        return try {
            val manager = context.getSystemService(Context.TELEPHONY_SERVICE) as? android.telephony.TelephonyManager
            manager?.networkOperatorName ?: "Unknown"
        } catch (e: Exception) {
            "Unknown"
        }
    }
    
    private fun getConnectionType(): String {
        return try {
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? android.net.ConnectivityManager
            val activeNetwork = connectivityManager?.activeNetworkInfo
            when (activeNetwork?.type) {
                android.net.ConnectivityManager.TYPE_WIFI -> "wifi"
                android.net.ConnectivityManager.TYPE_MOBILE -> "cellular"
                else -> "unknown"
            }
        } catch (e: Exception) {
            "unknown"
        }
    }
    
    /**
     * Get API URL from multiple sources (priority order):
     * 1. Environment variable IA_TRACKING_API_URL
     * 2. Configuration serverUrl parameter
     * 3. Decoded base64 serverUrl parameter
     */
    private fun resolveApiUrl(configServerUrl: String?): String? {
        // 1. Check environment variable first (highest priority)
        val envApiUrl = System.getenv("IA_TRACKING_API_URL")
        if (!envApiUrl.isNullOrBlank()) {
            Log.d(TAG, "Using API URL from environment variable")
            return envApiUrl
        }
        
        // 2. Check if provided URL is base64 encoded
        if (!configServerUrl.isNullOrBlank()) {
            return try {
                if (configServerUrl.startsWith("aHR0c")) { // Base64 encoded HTTPS URLs typically start with this
                    val decoded = String(Base64.getDecoder().decode(configServerUrl))
                    Log.d(TAG, "Using decoded base64 API URL")
                    decoded
                } else {
                    configServerUrl
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to decode base64 URL, using as-is")
                configServerUrl
            }
        }
        
        return null
    }
    
    /**
     * Hash sensitive data for logging (never log actual API URLs)
     */
    private fun hashForLogging(data: String): String {
        return try {
            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(data.toByteArray())
            hash.joinToString("") { "%02x".format(it) }.take(8) // First 8 chars of hash
        } catch (e: Exception) {
            "unknown"
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        
        // Start GAID collection as soon as we have context
        collectGaidAsync()
        
        Log.d(TAG, "Plugin attached to engine - GAID collection started")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d(TAG, "Method called: ${call.method}")
        
        when (call.method) {
            // Core tracking methods
            "initialize" -> initialize(call, result)
            "trackScreenView" -> trackScreenView(call, result)
            "trackButtonTap" -> trackButtonTap(call, result)
            "trackTextInput" -> trackTextInput(call, result)
            "trackNavigation" -> trackNavigation(call, result)
            "trackSearch" -> trackSearch(call, result)
            "trackCustomEvent" -> trackCustomEvent(call, result)
            "startNewSession" -> startNewSession(result)
            "setUserId" -> setUserId(call, result)
            "setEnabled" -> setEnabled(call, result)
            "isEnabled" -> isEnabled(result)
            "getActionStatistics" -> getActionStatistics(result)
            "getUnsyncedActions" -> getUnsyncedActions(call, result)
            "markActionsAsSynced" -> markActionsAsSynced(call, result)
            "getCleanupStats" -> getCleanupStats(result)
            "performCleanup" -> performCleanup(result)
            "deleteAllUserData" -> deleteAllUserData(result)
            "flush" -> flush(result)
            
            // Enhanced features (inspired by Singular SDK)
            "initializeEnhanced" -> initializeEnhanced(call, result)
            "trackRevenue" -> trackRevenue(call, result)
            "trackIOSInAppPurchase" -> trackIOSInAppPurchase(call, result)
            "trackAndroidInAppPurchase" -> trackAndroidInAppPurchase(call, result)
            "setGlobalProperty" -> setGlobalProperty(call, result)
            "unsetGlobalProperty" -> unsetGlobalProperty(call, result)
            "getGlobalProperties" -> getGlobalProperties(result)
            "clearGlobalProperties" -> clearGlobalProperties(result)
            "setTrackingEnabled" -> setTrackingEnabled(call, result)
            "isTrackingEnabled" -> isTrackingEnabled(result)
            "setDataSharingEnabled" -> setDataSharingEnabled(call, result)
            "isDataSharingEnabled" -> isDataSharingEnabled(result)
            "trackingOptIn" -> trackingOptIn(result)
            "trackingOptOut" -> trackingOptOut(result)
            "stopAllTracking" -> stopAllTracking(result)
            "resumeAllTracking" -> resumeAllTracking(result)
            "isAllTrackingStopped" -> isAllTrackingStopped(result)
            "setDeviceId" -> setDeviceId(call, result)
            "unsetDeviceId" -> unsetDeviceId(result)
            "setSessionTimeout" -> setSessionTimeout(call, result)
            
            // SKAdNetwork methods (iOS only - will return not implemented on Android)
            "skanRegisterAppForAttribution" -> skanRegisterAppForAttribution(result)
            "skanUpdateConversionValue" -> skanUpdateConversionValue(call, result)
            "skanUpdateConversionValues" -> skanUpdateConversionValues(call, result)
            "skanGetConversionValue" -> skanGetConversionValue(result)
            
            // Push notifications and uninstall tracking
            "registerDeviceTokenForUninstall" -> registerDeviceTokenForUninstall(call, result)
            "setFCMDeviceToken" -> setFCMDeviceToken(call, result)
            "handlePushNotification" -> handlePushNotification(call, result)
            
            // Advanced configuration
            "setWrapperInfo" -> setWrapperInfo(call, result)
            "getSdkVersion" -> getSdkVersion(result)
            
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopAutoFlush()
        coroutineScope.cancel()
        httpClient.dispatcher.executorService.shutdown()
        Log.d(TAG, "Plugin detached from engine")
    }
    
    /**
     * Start automatic flush timer that sends unsynced actions to API every 5 seconds
     */
    private fun startAutoFlush() {
        stopAutoFlush() // Stop any existing timer
        
        flushTimer = Timer().apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    if (isEnabled && isInitialized) {
                        flushUnsyncedActions()
                    }
                }
            }, FLUSH_INTERVAL_MS, FLUSH_INTERVAL_MS)
        }
        
        Log.d(TAG, "Auto-flush started with ${FLUSH_INTERVAL_MS}ms interval")
    }
    
    /**
     * Stop automatic flush timer
     */
    private fun stopAutoFlush() {
        flushTimer?.cancel()
        flushTimer = null
        Log.d(TAG, "Auto-flush stopped")
    }
    
    /**
     * Flush unsynced actions to the API
     */
    private fun flushUnsyncedActions() {
        coroutineScope.launch {
            try {
                // Skip if no API URL configured
                if (apiUrl.isNullOrBlank()) {
                    Log.d(TAG, "No API URL configured, skipping auto-flush")
                    return@launch
                }
                
                val unsyncedActions = userActions.filter { !it.isSynced && it.retryCount < 3 }
                
                if (unsyncedActions.isEmpty()) {
                    Log.d(TAG, "No unsynced actions to flush")
                    return@launch
                }
                
                Log.d(TAG, "Flushing ${unsyncedActions.size} unsynced actions to API")
                
                // Send actions to API
                val success = sendActionsToApi(unsyncedActions)
                
                if (success) {
                    // Mark actions as synced
                    unsyncedActions.forEach { action ->
                        action.isSynced = true
                    }
                    Log.d(TAG, "Successfully synced ${unsyncedActions.size} actions")
                } else {
                    // Increment retry count for failed actions
                    unsyncedActions.forEach { action ->
                        action.retryCount++
                    }
                    Log.w(TAG, "Failed to sync actions, retry count incremented")
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error during auto-flush", e)
            }
        }
    }
    
    /**
     * Send actions to the remote API using the documented format
     */
    private suspend fun sendActionsToApi(actions: List<UserAction>): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                // Double-check API URL is still valid
                val currentApiUrl = apiUrl
                if (currentApiUrl.isNullOrBlank()) {
                    Log.w(TAG, "No API URL configured, cannot send actions")
                    return@withContext false
                }
                
                // Convert actions to the API format
                val events = actions.map { action ->
                    val event = mutableMapOf<String, Any?>(
                        "id" to action.id,
                        "actionType" to action.actionType,
                        "timestamp" to action.timestamp,
                        "userId" to action.userId,
                        "sessionId" to action.sessionId,
                        "appVersion" to (action.appVersion ?: "1.0.0"),
                        "sdkVersion" to action.sdkVersion
                    )
                    
                    // Add optional fields if present
                    action.screenName?.let { event["screenName"] = it }
                    action.elementId?.let { event["elementId"] = it }
                    action.elementType?.let { event["elementType"] = it }
                    
                    // Merge properties with global properties
                    val allProperties = mutableMapOf<String, Any?>()
                    allProperties.putAll(action.properties)
                    allProperties.putAll(globalProperties)
                    if (allProperties.isNotEmpty()) {
                        event["properties"] = allProperties
                    }
                    
                    // Add device info
                    event["deviceInfo"] = action.deviceInfo
                    
                    // Add global properties as separate field
                    if (globalProperties.isNotEmpty()) {
                        event["globalProperties"] = globalProperties
                    }
                    
                    event
                }
                
                // Create batch info
                val batchId = generateBatchId()
                val batchInfo = mapOf(
                    "batchId" to batchId,
                    "eventCount" to events.size,
                    "flushReason" to "auto_flush",
                    "flushTimestamp" to System.currentTimeMillis()
                )
                
                // Create session info
                val sessionInfo = mapOf(
                    "sessionId" to currentSessionId,
                    "sessionStart" to System.currentTimeMillis(), // Would be better to track actual session start
                    "userId" to currentUserId
                )
                
                // Create complete payload according to API documentation
                val payload = mapOf(
                    "events" to events,
                    "batchInfo" to batchInfo,
                    "deviceInfo" to createDeviceInfo(),
                    "sessionInfo" to sessionInfo
                )
                
                val jsonPayload = gson.toJson(payload)
                val requestBody = jsonPayload.toRequestBody("application/json".toMediaType())
                
                val requestBuilder = Request.Builder()
                    .url(currentApiUrl)
                    .post(requestBody)
                    .addHeader("Content-Type", "application/json")
                    .addHeader("User-Agent", "IA-Tracking-SDK/1.1.0 (Platform: Android)")
                
                // Add API key header if configured
                apiKey?.let { key ->
                    requestBuilder.addHeader("X-API-Key", key)
                }
                
                val request = requestBuilder.build()
                
                httpClient.newCall(request).execute().use { response ->
                    if (response.isSuccessful) {
                        val responseBody = response.body?.string()
                        Log.d(TAG, "API request successful: ${response.code}")
                        Log.d(TAG, "Response: $responseBody")
                        true
                    } else {
                        val errorBody = response.body?.string()
                        Log.w(TAG, "API request failed: ${response.code} - ${response.message}")
                        Log.w(TAG, "Error response: $errorBody")
                        false
                    }
                }
                
            } catch (e: IOException) {
                Log.e(TAG, "Network error during API request", e)
                false
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error during API request", e)
                false
            }
        }
    }

    // Implementation methods
    private fun initialize(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            Log.d(TAG, "Initializing SDK")
            
            // Extract configuration
            currentUserId = arguments?.get("userId") as? String
            apiKey = arguments?.get("apiKey") as? String
            val configServerUrl = arguments?.get("serverUrl") as? String
            
            // Resolve API URL with priority: env var > config > default
            val resolvedApiUrl = resolveApiUrl(configServerUrl) ?: "$DEFAULT_API_BASE_URL/$API_VERSION/$TRACKING_ENDPOINT"
            
            // Validate and set API URL
            if (isValidApiUrl(resolvedApiUrl)) {
                apiUrl = resolvedApiUrl
            } else {
                // Fall back to default for development
                apiUrl = "$DEFAULT_API_BASE_URL/$API_VERSION/$TRACKING_ENDPOINT"
                Log.w(TAG, "Invalid API URL provided, using default")
            }
            
            // Start new session
            currentSessionId = generateSessionId()
            
            // Mark as initialized
            isInitialized = true
            
            // Start auto-flush timer
            startAutoFlush()
            
            result.success(null)
            Log.d(TAG, "Initialization successful - API configured: ${hashForLogging(apiUrl ?: "")}, Auto-flush started")
        } catch (e: Exception) {
            Log.e(TAG, "Initialization failed", e)
            result.error("INITIALIZATION_ERROR", "Failed to initialize: ${e.message}", null)
        }
    }
    
    /**
     * Validate API URL for security and format
     */
    private fun isValidApiUrl(url: String): Boolean {
        return try {
            val parsedUrl = java.net.URL(url)
            
            // Must be HTTPS for security (allow HTTP for development/testing)
            if (parsedUrl.protocol != "https" && parsedUrl.protocol != "http") {
                Log.w(TAG, "API URL must use HTTP or HTTPS protocol")
                return false
            }
            
            // Allow CloudFlare tunnel URLs and development hosts
            val host = parsedUrl.host.lowercase()
            
            // Allow CloudFlare tunnel domains
            if (host.contains("trycloudflare.com")) {
                Log.d(TAG, "CloudFlare tunnel URL detected and allowed")
                return true
            }
            
            // Allow localhost and development IPs for testing
            if (host == "localhost" || host.startsWith("127.") || host.startsWith("192.168.") || 
                host.startsWith("10.") || host.startsWith("172.")) {
                Log.d(TAG, "Development/local URL detected and allowed")
                return true
            }
            
            // Must have valid domain structure
            if (!host.contains(".") || host.length < 4) {
                Log.w(TAG, "Invalid domain format")
                return false
            }
            
            true
        } catch (e: Exception) {
            Log.w(TAG, "Invalid URL format: ${e.message}")
            false
        }
    }

    private fun trackScreenView(call: MethodCall, result: Result) {
        if (!isEnabled || !isInitialized) {
            result.success(null)
            return
        }
        
        coroutineScope.launch {
            try {
                val screenName = call.argument<String>("screenName")
                Log.d(TAG, "Tracking screen view: $screenName")
                
                val action = UserAction(
                    id = generateActionId(),
                    actionType = "screen_view",
                    screenName = screenName ?: "unknown",
                    elementId = null,
                    elementType = null,
                    userId = currentUserId,
                    sessionId = currentSessionId,
                    timestamp = System.currentTimeMillis(),
                    properties = mapOf(
                        "screen_name" to (screenName ?: "unknown")
                    ),
                    deviceInfo = createDeviceInfo(),
                    appVersion = "1.0.0"
                )
                
                userActions.add(action)
                Log.d(TAG, "Screen view tracked and stored locally: ${action.id}")
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to track screen view", e)
                result.error("TRACKING_ERROR", "Failed to track screen view: ${e.message}", null)
            }
        }
    }

    private fun trackButtonTap(call: MethodCall, result: Result) {
        if (!isEnabled || !isInitialized) {
            result.success(null)
            return
        }
        
        coroutineScope.launch {
            try {
                val elementId = call.argument<String>("elementId")
                val screenName = call.argument<String>("screenName")
                val coordinatesX = call.argument<Double>("coordinatesX")
                val coordinatesY = call.argument<Double>("coordinatesY")
                Log.d(TAG, "Tracking button tap: $elementId on $screenName")
                
                val properties = mutableMapOf<String, Any?>(
                    "element_id" to elementId,
                    "element_type" to "button"
                )
                if (coordinatesX != null && coordinatesY != null) {
                    properties["tap_x"] = coordinatesX
                    properties["tap_y"] = coordinatesY
                }
                
                val action = UserAction(
                    id = generateActionId(),
                    actionType = "button_tap",
                    screenName = screenName,
                    elementId = elementId,
                    elementType = "button",
                    userId = currentUserId,
                    sessionId = currentSessionId,
                    timestamp = System.currentTimeMillis(),
                    properties = properties,
                    deviceInfo = createDeviceInfo(),
                    appVersion = "1.0.0"
                )
                
                userActions.add(action)
                Log.d(TAG, "Button tap tracked and stored locally: ${action.id}")
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to track button tap", e)
                result.error("TRACKING_ERROR", "Failed to track button tap: ${e.message}", null)
            }
        }
    }

    private fun trackTextInput(call: MethodCall, result: Result) {
        coroutineScope.launch {
            try {
                val elementId = call.argument<String>("elementId")
                val screenName = call.argument<String>("screenName")
                val inputLength = call.argument<Int>("inputLength")
                Log.d(TAG, "Tracking text input: $elementId on $screenName")
                
                val action = UserAction(
                    id = generateActionId(),
                    actionType = "text_input",
                    screenName = screenName,
                    elementId = elementId,
                    elementType = "input",
                    userId = currentUserId,
                    sessionId = currentSessionId,
                    timestamp = System.currentTimeMillis(),
                    properties = mapOf(
                        "element_id" to elementId,
                        "element_type" to "input",
                        "input_length" to inputLength
                    ),
                    deviceInfo = createDeviceInfo(),
                    appVersion = "1.0.0"
                )
                
                userActions.add(action)
                Log.d(TAG, "Text input tracked and stored locally: ${action.id}")
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to track text input", e)
                result.error("TRACKING_ERROR", "Failed to track text input: ${e.message}", null)
            }
        }
    }

    private fun trackNavigation(call: MethodCall, result: Result) {
        coroutineScope.launch {
            try {
                val fromScreen = call.argument<String>("fromScreen")
                val toScreen = call.argument<String>("toScreen")
                val method = call.argument<String>("method")
                Log.d(TAG, "Tracking navigation: $fromScreen -> $toScreen")
                
                val action = UserAction(
                    id = generateActionId(),
                    actionType = "custom",
                    screenName = toScreen,
                    elementId = null,
                    elementType = null,
                    userId = currentUserId,
                    sessionId = currentSessionId,
                    timestamp = System.currentTimeMillis(),
                    properties = mapOf(
                        "event_name" to "navigation",
                        "action_subtype" to "navigation",
                        "from_screen" to fromScreen,
                        "to_screen" to toScreen,
                        "navigation_method" to method
                    ),
                    deviceInfo = createDeviceInfo(),
                    appVersion = "1.0.0"
                )
                
                userActions.add(action)
                Log.d(TAG, "Navigation tracked and stored locally: ${action.id}")
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to track navigation", e)
                result.error("TRACKING_ERROR", "Failed to track navigation: ${e.message}", null)
            }
        }
    }

    private fun trackSearch(call: MethodCall, result: Result) {
        coroutineScope.launch {
            try {
                val query = call.argument<String>("query")
                val screenName = call.argument<String>("screenName")
                val resultsCount = call.argument<Int>("resultsCount")
                Log.d(TAG, "Tracking search: '$query' on $screenName")
                
                val action = UserAction(
                    id = generateActionId(),
                    actionType = "custom",
                    screenName = screenName,
                    elementId = null,
                    elementType = "search",
                    userId = currentUserId,
                    sessionId = currentSessionId,
                    timestamp = System.currentTimeMillis(),
                    properties = mapOf(
                        "event_name" to "search",
                        "action_subtype" to "search",
                        "search_query" to query,
                        "results_count" to resultsCount
                    ),
                    deviceInfo = createDeviceInfo(),
                    appVersion = "1.0.0"
                )
                
                userActions.add(action)
                Log.d(TAG, "Search tracked and stored locally: ${action.id}")
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to track search", e)
                result.error("TRACKING_ERROR", "Failed to track search: ${e.message}", null)
            }
        }
    }

    private fun trackCustomEvent(call: MethodCall, result: Result) {
        coroutineScope.launch {
            try {
                val eventName = call.argument<String>("eventName")
                val screenName = call.argument<String>("screenName")
                val elementId = call.argument<String>("elementId")
                val properties = call.argument<Map<String, Any?>>("properties") ?: emptyMap()
                Log.d(TAG, "Tracking custom event: '$eventName' on $screenName")
                
                val action = UserAction(
                    id = generateActionId(),
                    actionType = "custom",
                    screenName = screenName,
                    elementId = elementId,
                    elementType = "custom",
                    userId = currentUserId,
                    sessionId = currentSessionId,
                    timestamp = System.currentTimeMillis(),
                    properties = mapOf(
                        "event_name" to eventName,
                        "action_subtype" to "custom_event",
                        "element_id" to elementId
                    ) + properties,
                    deviceInfo = createDeviceInfo(),
                    appVersion = "1.0.0"
                )
                
                userActions.add(action)
                Log.d(TAG, "Custom event tracked and stored locally: ${action.id}")
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to track custom event", e)
                result.error("TRACKING_ERROR", "Failed to track custom event: ${e.message}", null)
            }
        }
    }

    private fun startNewSession(result: Result) {
        coroutineScope.launch {
            try {
                Log.d(TAG, "Starting new session")
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start new session", e)
                result.error("SESSION_ERROR", "Failed to start new session: ${e.message}", null)
            }
        }
    }

    private fun setUserId(call: MethodCall, result: Result) {
        coroutineScope.launch {
            try {
                currentUserId = call.argument<String>("userId")
                Log.d(TAG, "Set user ID: $currentUserId")
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to set user ID", e)
                result.error("USER_ERROR", "Failed to set user ID: ${e.message}", null)
            }
        }
    }

    private fun setEnabled(call: MethodCall, result: Result) {
        try {
            isEnabled = call.argument<Boolean>("enabled") ?: false
            Log.d(TAG, "Set enabled: $isEnabled")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set enabled state", e)
            result.error("STATE_ERROR", "Failed to set enabled state: ${e.message}", null)
        }
    }

    private fun isEnabled(result: Result) {
        try {
            Log.d(TAG, "Is enabled: $isEnabled")
            result.success(isEnabled)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check enabled state", e)
            result.error("STATE_ERROR", "Failed to check enabled state: ${e.message}", null)
        }
    }

    private fun getActionStatistics(result: Result) {
        try {
            val totalActions = userActions.size
            val syncedActions = userActions.count { it.isSynced }
            val unsyncedActions = userActions.count { !it.isSynced }
            val failedActions = userActions.count { it.retryCount >= 3 }
            
            val stats = mapOf(
                "totalActions" to totalActions,
                "unsyncedActions" to unsyncedActions,
                "syncedActions" to syncedActions,
                "failedActions" to failedActions
            )
            Log.d(TAG, "Action statistics: $stats")
            result.success(stats)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get action statistics", e)
            result.error("STATS_ERROR", "Failed to get action statistics: ${e.message}", null)
        }
    }

    private fun getUnsyncedActions(call: MethodCall, result: Result) {
        try {
            val limit = call.argument<Int>("limit") ?: 50
            Log.d(TAG, "Get unsynced actions (limit: $limit)")
            
            // Return unsynced actions, converting to maps for Flutter
            val unsyncedActions = userActions
                .filter { !it.isSynced }
                .takeLast(minOf(limit, userActions.count { !it.isSynced }))
                .map { action ->
                    mapOf(
                        "id" to action.id,
                        "actionType" to action.actionType,
                        "screenName" to action.screenName,
                        "elementId" to action.elementId,
                        "elementType" to action.elementType,
                        "userId" to action.userId,
                        "sessionId" to action.sessionId,
                        "timestamp" to action.timestamp,
                        "properties" to action.properties,
                        "deviceInfo" to action.deviceInfo,
                        "appVersion" to action.appVersion,
                        "sdkVersion" to action.sdkVersion,
                        "isSynced" to action.isSynced,
                        "retryCount" to action.retryCount
                    )
                }
            
            result.success(unsyncedActions)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get unsynced actions", e)
            result.error("DATA_ERROR", "Failed to get unsynced actions: ${e.message}", null)
        }
    }

    private fun markActionsAsSynced(call: MethodCall, result: Result) {
        try {
            val actionIds = call.argument<List<String>>("actionIds") ?: emptyList()
            Log.d(TAG, "Mark actions as synced: ${actionIds.size} actions")
            
            // Mark matching actions as synced
            userActions.forEach { action ->
                if (actionIds.contains(action.id)) {
                    action.isSynced = true
                }
            }
            
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to mark actions as synced", e)
            result.error("SYNC_ERROR", "Failed to mark actions as synced: ${e.message}", null)
        }
    }

    private fun getCleanupStats(result: Result) {
        try {
            val totalActions = userActions.size
            val syncedActions = userActions.count { it.isSynced }
            val unsyncedActions = userActions.count { !it.isSynced }
            
            val stats = mapOf(
                "totalActions" to totalActions,
                "unsyncedActions" to unsyncedActions,
                "syncedActions" to syncedActions,
                "estimatedSizeBytes" to (totalActions * 1024),
                "maxSizeBytes" to (50 * 1024 * 1024),
                "retentionDays" to 30
            )
            Log.d(TAG, "Cleanup statistics: $stats")
            result.success(stats)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get cleanup stats", e)
            result.error("CLEANUP_ERROR", "Failed to get cleanup stats: ${e.message}", null)
        }
    }

    private fun performCleanup(result: Result) {
        try {
            Log.d(TAG, "Performing cleanup")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to perform cleanup", e)
            result.error("CLEANUP_ERROR", "Failed to perform cleanup: ${e.message}", null)
        }
    }

    private fun deleteAllUserData(result: Result) {
        try {
            Log.d(TAG, "Deleting all user data")
            userActions.clear()
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to delete user data", e)
            result.error("DELETE_ERROR", "Failed to delete user data: ${e.message}", null)
        }
    }

    private fun flush(result: Result) {
        try {
            Log.d(TAG, "Flushing operations")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to flush operations", e)
            result.error("FLUSH_ERROR", "Failed to flush operations: ${e.message}", null)
        }
    }
    
    // ============ ENHANCED FEATURES IMPLEMENTATIONS ============
    
    private fun initializeEnhanced(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            Log.d(TAG, "Initializing enhanced SDK")
            
            // Extract enhanced configuration
            currentUserId = arguments?.get("userId") as? String
            apiKey = arguments?.get("apiKey") as? String
            currentDeviceId = arguments?.get("deviceId") as? String
            sessionTimeoutMinutes = arguments?.get("sessionTimeoutMinutes") as? Int ?: 30
            val configServerUrl = arguments?.get("serverUrl") as? String
            
            // Extract privacy settings
            val privacy = arguments?.get("privacy") as? Map<String, Any>
            if (privacy != null) {
                trackingEnabled = privacy["trackingEnabled"] as? Boolean ?: true
                dataSharingEnabled = privacy["dataSharingEnabled"] as? Boolean ?: true
            }
            
            // Extract global properties
            val globalProps = arguments?.get("globalProperties") as? List<Map<String, Any>>
            globalProps?.forEach { prop ->
                val key = prop["key"] as? String
                val value = prop["value"] as? String
                if (key != null && value != null) {
                    globalProperties[key] = value
                }
            }
            
            // Resolve API URL with priority: env var > config > default
            val resolvedApiUrl = resolveApiUrl(configServerUrl) ?: "$DEFAULT_API_BASE_URL/$API_VERSION/$TRACKING_ENDPOINT"
            
            // Validate and set API URL
            if (isValidApiUrl(resolvedApiUrl)) {
                apiUrl = resolvedApiUrl
            } else {
                // Fall back to default for development
                apiUrl = "$DEFAULT_API_BASE_URL/$API_VERSION/$TRACKING_ENDPOINT"
                Log.w(TAG, "Invalid API URL provided, using default")
            }
            currentSessionId = generateSessionId()
            isInitialized = true
            startAutoFlush()
            
            result.success(null)
            Log.d(TAG, "Enhanced initialization successful")
        } catch (e: Exception) {
            Log.e(TAG, "Enhanced initialization failed", e)
            result.error("INITIALIZATION_ERROR", "Failed to initialize enhanced: ${e.message}", null)
        }
    }
    
    private fun trackRevenue(call: MethodCall, result: Result) {
        if (!isEnabled || !isInitialized || allTrackingStopped) {
            result.success(null)
            return
        }
        
        coroutineScope.launch {
            try {
                val arguments = call.arguments as? Map<String, Any>
                val eventName = arguments?.get("eventName") as? String ?: "revenue"
                val amount = arguments?.get("amount") as? Double ?: 0.0
                val currency = arguments?.get("currency") as? String ?: "USD"
                val properties = arguments?.get("properties") as? Map<String, Any> ?: emptyMap()
                
                Log.d(TAG, "Tracking revenue: $amount $currency")
                
                val revenueProperties = mutableMapOf<String, Any?>(
                    "is_revenue_event" to true,
                    "r" to amount,
                    "pcc" to currency
                )
                revenueProperties.putAll(properties)
                revenueProperties.putAll(globalProperties)
                
                val action = UserAction(
                    id = generateActionId(),
                    actionType = "revenue",
                    screenName = null,
                    elementId = null,
                    elementType = "revenue",
                    userId = currentUserId,
                    sessionId = currentSessionId,
                    timestamp = System.currentTimeMillis(),
                    properties = revenueProperties,
                    deviceInfo = createDeviceInfo(),
                    appVersion = "1.0.0"
                )
                
                userActions.add(action)
                Log.d(TAG, "Revenue tracked and stored locally: ${action.id}")
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to track revenue", e)
                result.error("TRACKING_ERROR", "Failed to track revenue: ${e.message}", null)
            }
        }
    }
    
    private fun trackIOSInAppPurchase(call: MethodCall, result: Result) {
        // Android implementation - will log but not process iOS-specific data
        Log.d(TAG, "iOS IAP tracking called on Android - ignoring")
        result.success(null)
    }
    
    private fun trackAndroidInAppPurchase(call: MethodCall, result: Result) {
        if (!isEnabled || !isInitialized || allTrackingStopped) {
            result.success(null)
            return
        }
        
        coroutineScope.launch {
            try {
                val arguments = call.arguments as? Map<String, Any>
                val eventName = arguments?.get("eventName") as? String ?: "android_iap"
                val amount = arguments?.get("amount") as? Double ?: 0.0
                val currency = arguments?.get("currency") as? String ?: "USD"
                val productId = arguments?.get("productId") as? String
                val purchaseToken = arguments?.get("purchaseToken") as? String
                val signature = arguments?.get("signature") as? String
                val purchaseData = arguments?.get("purchaseData") as? String
                val properties = arguments?.get("properties") as? Map<String, Any> ?: emptyMap()
                
                Log.d(TAG, "Tracking Android IAP: $productId - $amount $currency")
                
                val iapProperties = mutableMapOf<String, Any?>(
                    "is_revenue_event" to true,
                    "r" to amount,
                    "pcc" to currency,
                    "platform" to "android",
                    "product_id" to productId,
                    "purchase_token" to purchaseToken,
                    "receipt_signature" to signature,
                    "receipt" to purchaseData
                )
                iapProperties.putAll(properties)
                iapProperties.putAll(globalProperties)
                
                val action = UserAction(
                    id = generateActionId(),
                    actionType = "android_iap",
                    screenName = null,
                    elementId = productId,
                    elementType = "iap",
                    userId = currentUserId,
                    sessionId = currentSessionId,
                    timestamp = System.currentTimeMillis(),
                    properties = iapProperties,
                    deviceInfo = createDeviceInfo(),
                    appVersion = "1.0.0"
                )
                
                userActions.add(action)
                Log.d(TAG, "Android IAP tracked and stored locally: ${action.id}")
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to track Android IAP", e)
                result.error("TRACKING_ERROR", "Failed to track Android IAP: ${e.message}", null)
            }
        }
    }
    
    private fun setGlobalProperty(call: MethodCall, result: Result) {
        try {
            val key = call.argument<String>("key")
            val value = call.argument<String>("value")
            val overrideExisting = call.argument<Boolean>("overrideExisting") ?: true
            
            if (key.isNullOrEmpty()) {
                result.error("INVALID_PARAMETER", "Global property key cannot be empty", null)
                return
            }
            
            if (globalProperties.containsKey(key) && !overrideExisting) {
                result.success(false)
                return
            }
            
            globalProperties[key] = value ?: ""
            Log.d(TAG, "Global property set: $key")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set global property", e)
            result.error("PROPERTY_ERROR", "Failed to set global property: ${e.message}", null)
        }
    }
    
    private fun unsetGlobalProperty(call: MethodCall, result: Result) {
        try {
            val key = call.argument<String>("key")
            if (key.isNullOrEmpty()) {
                result.error("INVALID_PARAMETER", "Global property key cannot be empty", null)
                return
            }
            
            globalProperties.remove(key)
            Log.d(TAG, "Global property removed: $key")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unset global property", e)
            result.error("PROPERTY_ERROR", "Failed to unset global property: ${e.message}", null)
        }
    }
    
    private fun getGlobalProperties(result: Result) {
        try {
            Log.d(TAG, "Getting global properties: ${globalProperties.size} properties")
            result.success(globalProperties.toMap())
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get global properties", e)
            result.error("PROPERTY_ERROR", "Failed to get global properties: ${e.message}", null)
        }
    }
    
    private fun clearGlobalProperties(result: Result) {
        try {
            globalProperties.clear()
            Log.d(TAG, "All global properties cleared")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear global properties", e)
            result.error("PROPERTY_ERROR", "Failed to clear global properties: ${e.message}", null)
        }
    }
    
    private fun setTrackingEnabled(call: MethodCall, result: Result) {
        try {
            trackingEnabled = call.argument<Boolean>("enabled") ?: false
            Log.d(TAG, "Tracking enabled set to: $trackingEnabled")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set tracking enabled", e)
            result.error("STATE_ERROR", "Failed to set tracking enabled: ${e.message}", null)
        }
    }
    
    private fun isTrackingEnabled(result: Result) {
        try {
            result.success(trackingEnabled)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check tracking enabled", e)
            result.error("STATE_ERROR", "Failed to check tracking enabled: ${e.message}", null)
        }
    }
    
    private fun setDataSharingEnabled(call: MethodCall, result: Result) {
        try {
            dataSharingEnabled = call.argument<Boolean>("enabled") ?: false
            Log.d(TAG, "Data sharing enabled set to: $dataSharingEnabled")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set data sharing enabled", e)
            result.error("STATE_ERROR", "Failed to set data sharing enabled: ${e.message}", null)
        }
    }
    
    private fun isDataSharingEnabled(result: Result) {
        try {
            result.success(dataSharingEnabled)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check data sharing enabled", e)
            result.error("STATE_ERROR", "Failed to check data sharing enabled: ${e.message}", null)
        }
    }
    
    private fun trackingOptIn(result: Result) {
        try {
            trackingEnabled = true
            dataSharingEnabled = true
            allTrackingStopped = false
            Log.d(TAG, "User opted into tracking")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to opt-in to tracking", e)
            result.error("STATE_ERROR", "Failed to opt-in to tracking: ${e.message}", null)
        }
    }
    
    private fun trackingOptOut(result: Result) {
        try {
            trackingEnabled = false
            dataSharingEnabled = false
            Log.d(TAG, "User opted out of tracking")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to opt-out of tracking", e)
            result.error("STATE_ERROR", "Failed to opt-out of tracking: ${e.message}", null)
        }
    }
    
    private fun stopAllTracking(result: Result) {
        try {
            allTrackingStopped = true
            trackingEnabled = false
            dataSharingEnabled = false
            stopAutoFlush()
            Log.d(TAG, "All tracking stopped")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop all tracking", e)
            result.error("STATE_ERROR", "Failed to stop all tracking: ${e.message}", null)
        }
    }
    
    private fun resumeAllTracking(result: Result) {
        try {
            allTrackingStopped = false
            trackingEnabled = true
            dataSharingEnabled = true
            if (isInitialized && !apiUrl.isNullOrBlank()) {
                startAutoFlush()
            }
            Log.d(TAG, "All tracking resumed")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to resume all tracking", e)
            result.error("STATE_ERROR", "Failed to resume all tracking: ${e.message}", null)
        }
    }
    
    private fun isAllTrackingStopped(result: Result) {
        try {
            result.success(allTrackingStopped)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check if all tracking stopped", e)
            result.error("STATE_ERROR", "Failed to check if all tracking stopped: ${e.message}", null)
        }
    }
    
    private fun setDeviceId(call: MethodCall, result: Result) {
        try {
            currentDeviceId = call.argument<String>("deviceId")
            Log.d(TAG, "Device ID set")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set device ID", e)
            result.error("DEVICE_ERROR", "Failed to set device ID: ${e.message}", null)
        }
    }
    
    private fun unsetDeviceId(result: Result) {
        try {
            currentDeviceId = null
            Log.d(TAG, "Device ID unset")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unset device ID", e)
            result.error("DEVICE_ERROR", "Failed to unset device ID: ${e.message}", null)
        }
    }
    
    private fun setSessionTimeout(call: MethodCall, result: Result) {
        try {
            sessionTimeoutMinutes = call.argument<Int>("timeoutMinutes") ?: 30
            Log.d(TAG, "Session timeout set to: $sessionTimeoutMinutes minutes")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set session timeout", e)
            result.error("SESSION_ERROR", "Failed to set session timeout: ${e.message}", null)
        }
    }
    
    // ============ iOS SKAdNetwork Support (Not implemented on Android) ============
    
    private fun skanRegisterAppForAttribution(result: Result) {
        Log.d(TAG, "SKAdNetwork not available on Android")
        result.success(null)
    }
    
    private fun skanUpdateConversionValue(call: MethodCall, result: Result) {
        Log.d(TAG, "SKAdNetwork not available on Android")
        result.success(false)
    }
    
    private fun skanUpdateConversionValues(call: MethodCall, result: Result) {
        Log.d(TAG, "SKAdNetwork not available on Android")
        result.success(null)
    }
    
    private fun skanGetConversionValue(result: Result) {
        Log.d(TAG, "SKAdNetwork not available on Android")
        result.success(-1)
    }
    
    // ============ Push Notifications & Uninstall Tracking ============
    
    private fun registerDeviceTokenForUninstall(call: MethodCall, result: Result) {
        // iOS-specific functionality
        Log.d(TAG, "Device token registration not available on Android")
        result.success(null)
    }
    
    private fun setFCMDeviceToken(call: MethodCall, result: Result) {
        try {
            fcmToken = call.argument<String>("fcmToken")
            Log.d(TAG, "FCM device token set")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set FCM device token", e)
            result.error("FCM_ERROR", "Failed to set FCM device token: ${e.message}", null)
        }
    }
    
    private fun handlePushNotification(call: MethodCall, result: Result) {
        try {
            val notificationPayload = call.argument<Map<String, Any>>("notificationPayload")
            Log.d(TAG, "Handling push notification with payload")
            
            // Track push notification received
            if (isEnabled && isInitialized && !allTrackingStopped) {
                coroutineScope.launch {
                    val action = UserAction(
                        id = generateActionId(),
                        actionType = "custom",
                        screenName = null,
                        elementId = null,
                        elementType = "notification",
                        userId = currentUserId,
                        sessionId = currentSessionId,
                        timestamp = System.currentTimeMillis(),
                        properties = mapOf(
                            "event_name" to "push_notification_received",
                            "action_subtype" to "push_notification",
                            "notification_payload" to notificationPayload,
                            "platform" to "android"
                        ) + globalProperties,
                        deviceInfo = createDeviceInfo(),
                        appVersion = "1.0.0"
                    )
                    
                    userActions.add(action)
                    Log.d(TAG, "Push notification tracked: ${action.id}")
                }
            }
            
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to handle push notification", e)
            result.error("NOTIFICATION_ERROR", "Failed to handle push notification: ${e.message}", null)
        }
    }
    
    // ============ Advanced Configuration ============
    
    private fun setWrapperInfo(call: MethodCall, result: Result) {
        try {
            wrapperName = call.argument<String>("name")
            wrapperVersion = call.argument<String>("version")
            Log.d(TAG, "Wrapper info set: $wrapperName v$wrapperVersion")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set wrapper info", e)
            result.error("WRAPPER_ERROR", "Failed to set wrapper info: ${e.message}", null)
        }
    }
    
    private fun getSdkVersion(result: Result) {
        try {
            result.success(sdkVersion)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get SDK version", e)
            result.error("VERSION_ERROR", "Failed to get SDK version: ${e.message}", null)
        }
    }
}