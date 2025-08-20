package com.iav3.iatracking

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Flutter plugin for IA Tracking Android SDK
 * 
 * This plugin provides Flutter bindings for the native Android IA Tracking SDK,
 * allowing Flutter apps to track user actions using the high-performance native implementation.
 * 
 * NOTE: This is currently a mock implementation for demonstration purposes.
 * In production, this would integrate with the actual native Android SDK.
 */
class IaTrackingPlugin : FlutterPlugin, MethodCallHandler {

    companion object {
        private const val TAG = "IaTrackingPlugin"
        private const val CHANNEL_NAME = "ia_tracking"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val coroutineScope = CoroutineScope(Dispatchers.Main)
    
    // Mock tracking state
    private var isInitialized = false
    private var isEnabled = true
    private var currentUserId: String? = null
    private var actionCount = 0
    
    // Real action storage for tracking user interactions
    private val userActions = mutableListOf<Map<String, Any?>>()
    private fun generateActionId(): String = "action_${System.currentTimeMillis()}_${(1000..9999).random()}"
    private fun getCurrentSession(): String = "session_demo_${System.currentTimeMillis() / 1000}"

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        Log.d(TAG, "Plugin attached to engine")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d(TAG, "Method called: ${call.method}")
        
        when (call.method) {
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
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        Log.d(TAG, "Plugin detached from engine")
    }

    // Mock implementation methods
    private fun initialize(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as? Map<String, Any>
            Log.d(TAG, "Initializing with arguments: $arguments")
            
            // Mock initialization
            isInitialized = true
            currentUserId = arguments?.get("userId") as? String
            
            result.success(null)
            Log.d(TAG, "Initialization successful")
        } catch (e: Exception) {
            Log.e(TAG, "Initialization failed", e)
            result.error("INITIALIZATION_ERROR", "Failed to initialize: ${e.message}", null)
        }
    }

    private fun trackScreenView(call: MethodCall, result: Result) {
        coroutineScope.launch {
            try {
                val screenName = call.argument<String>("screenName")
                Log.d(TAG, "Tracking screen view: $screenName")
                
                // Store real user action
                val action = mapOf(
                    "id" to generateActionId(),
                    "actionType" to "screen_view",
                    "screenName" to (screenName ?: "unknown"),
                    "timestamp" to System.currentTimeMillis(),
                    "userId" to (currentUserId ?: "anonymous"),
                    "sessionId" to getCurrentSession(),
                    "properties" to mapOf(
                        "device_type" to "android",
                        "app_version" to "1.0.0"
                    )
                )
                userActions.add(action)
                
                actionCount++
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to track screen view", e)
                result.error("TRACKING_ERROR", "Failed to track screen view: ${e.message}", null)
            }
        }
    }

    private fun trackButtonTap(call: MethodCall, result: Result) {
        coroutineScope.launch {
            try {
                val elementId = call.argument<String>("elementId")
                val screenName = call.argument<String>("screenName")
                val coordinatesX = call.argument<Double>("coordinatesX")
                val coordinatesY = call.argument<Double>("coordinatesY")
                Log.d(TAG, "Tracking button tap: $elementId on $screenName")
                
                // Store real user action
                val properties = mutableMapOf<String, Any>(
                    "device_type" to "android",
                    "element_type" to "button"
                )
                if (coordinatesX != null && coordinatesY != null) {
                    properties["tap_x"] = coordinatesX
                    properties["tap_y"] = coordinatesY
                }
                
                val action = mapOf(
                    "id" to generateActionId(),
                    "actionType" to "button_tap",
                    "screenName" to (screenName ?: "unknown"),
                    "elementId" to (elementId ?: "unknown"),
                    "timestamp" to System.currentTimeMillis(),
                    "userId" to (currentUserId ?: "anonymous"),
                    "sessionId" to getCurrentSession(),
                    "properties" to properties
                )
                userActions.add(action)
                
                actionCount++
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
                Log.d(TAG, "Tracking text input: $elementId on $screenName")
                
                actionCount++
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
                Log.d(TAG, "Tracking navigation: $fromScreen -> $toScreen")
                
                actionCount++
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
                Log.d(TAG, "Tracking search: '$query' on $screenName")
                
                actionCount++
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
                Log.d(TAG, "Tracking custom event: '$eventName' on $screenName")
                
                actionCount++
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
            val stats = mapOf(
                "totalActions" to actionCount,
                "unsyncedActions" to (actionCount / 2),
                "syncedActions" to (actionCount / 2),
                "failedActions" to 0
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
            
            // Return recent user actions (all actions are unsynced in this demo)
            val unsyncedActions = userActions.takeLast(minOf(limit, userActions.size))
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
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to mark actions as synced", e)
            result.error("SYNC_ERROR", "Failed to mark actions as synced: ${e.message}", null)
        }
    }

    private fun getCleanupStats(result: Result) {
        try {
            val stats = mapOf(
                "totalActions" to actionCount,
                "unsyncedActions" to (actionCount / 2),
                "syncedActions" to (actionCount / 2),
                "estimatedSizeBytes" to (actionCount * 1024),
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
            actionCount = 0
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
}