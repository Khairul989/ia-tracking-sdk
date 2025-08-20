import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart' as flutter_services;
import 'package:ia_tracking/src/exceptions/ia_tracking_exception.dart';
import 'package:ia_tracking/src/ia_tracking_config.dart';
import 'package:ia_tracking/src/models/action_statistics.dart';
import 'package:ia_tracking/src/models/action_type.dart';
import 'package:ia_tracking/src/models/cleanup_stats.dart';
import 'package:ia_tracking/src/models/revenue_models.dart';
import 'package:ia_tracking/src/models/tracking_configuration.dart';
import 'package:ia_tracking/src/models/user_action.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Main interface for the IA Tracking Flutter SDK
///
/// This class provides a Flutter wrapper around the native Android and iOS
/// IA Tracking SDKs, enabling cross-platform user action tracking.
abstract class IaTracker extends PlatformInterface {
  /// Constructs an IaTracker
  IaTracker() : super(token: _token);

  static final Object _token = Object();

  static IaTracker _instance = _IaTrackerImpl();

  /// The default instance of [IaTracker] to use
  static IaTracker get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IaTracker] when
  /// they register themselves.
  static set instance(IaTracker instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize the IA Tracking SDK
  ///
  /// This must be called before any tracking operations.
  /// The [config] parameter contains all configuration options.
  ///
  /// Throws [InitializationException] if initialization fails.
  Future<void> initialize(TrackingConfiguration config);

  /// Track a screen view event
  ///
  /// [screenName] - Name of the screen being viewed
  ///
  /// This automatically captures:
  /// - Current timestamp
  /// - Session information
  /// - Device information
  Future<void> trackScreenView(String screenName);

  /// Track a button tap event
  ///
  /// [elementId] - Identifier of the button/element tapped
  /// [screenName] - Name of the screen where tap occurred
  /// [coordinates] - Optional tap coordinates relative to screen
  Future<void> trackButtonTap(
    String elementId,
    String screenName, {
    Offset? coordinates,
  });

  /// Track text input event
  ///
  /// [elementId] - Identifier of the input field
  /// [screenName] - Name of the screen where input occurred
  /// [inputLength] - Length of the input text (for privacy, not the actual text)
  Future<void> trackTextInput(
    String elementId,
    String screenName, {
    int? inputLength,
  });

  /// Track navigation between screens
  ///
  /// [fromScreen] - Screen user navigated from
  /// [toScreen] - Screen user navigated to
  /// [method] - Method of navigation (e.g., 'push', 'pop', 'replace')
  Future<void> trackNavigation(
    String fromScreen,
    String toScreen, {
    String? method,
  });

  /// Track search query
  ///
  /// [query] - Search query text
  /// [screenName] - Screen where search occurred
  /// [resultsCount] - Number of results returned (optional)
  Future<void> trackSearch(
    String query,
    String screenName, {
    int? resultsCount,
  });

  /// Track custom event with properties
  ///
  /// [eventName] - Name of the custom event
  /// [screenName] - Screen where event occurred
  /// [elementId] - Optional element that triggered the event
  /// [properties] - Optional additional properties
  Future<void> trackCustomEvent(
    String eventName,
    String screenName, {
    String? elementId,
    Map<String, dynamic>? properties,
  });

  /// Start a new user session
  ///
  /// This is typically called automatically, but can be called manually
  /// to force a new session (e.g., after user login).
  Future<void> startNewSession();

  /// Update the current user ID
  ///
  /// This will start a new session with the new user ID.
  /// Pass null to clear the user ID (anonymous tracking).
  Future<void> setUserId(String? userId);

  /// Enable or disable tracking
  ///
  /// When disabled, all tracking calls will be ignored.
  /// This is useful for privacy compliance (e.g., user opt-out).
  Future<void> setEnabled(bool enabled);

  /// Check if tracking is currently enabled
  Future<bool> isEnabled();

  /// Get statistics about tracked actions
  ///
  /// Returns counts of total, synced, and unsynced actions.
  Future<ActionStatistics> getActionStatistics();

  /// Get unsynced actions for data export
  ///
  /// [limit] - Maximum number of actions to retrieve (default: 50)
  ///
  /// Returns a list of actions that haven't been synchronized to your server.
  /// Use this for implementing your own data synchronization.
  Future<List<UserAction>> getUnsyncedActions({int limit = 50});

  /// Mark actions as successfully synchronized
  ///
  /// [actionIds] - List of action IDs that were successfully synced
  ///
  /// Call this after successfully uploading actions to your server.
  /// This prevents the same actions from being returned in future
  /// getUnsyncedActions calls.
  Future<void> markActionsAsSynced(List<String> actionIds);

  /// Get cleanup and retention statistics
  ///
  /// Returns information about database size, retention policies,
  /// and cleanup status.
  Future<CleanupStats> getCleanupStats();

  /// Perform immediate data cleanup
  ///
  /// Manually trigger cleanup of old data based on retention policies.
  /// This is normally done automatically but can be triggered manually
  /// if needed.
  Future<void> performCleanup();

  /// Delete all user data
  ///
  /// This removes all tracked data for privacy compliance (e.g., GDPR).
  /// This operation cannot be undone.
  Future<void> deleteAllUserData();

  /// Flush all pending operations
  ///
  /// Ensures all pending tracking operations are completed.
  /// Useful before app termination or when you need to ensure
  /// data persistence.
  Future<void> flush();

  // ============ ENHANCED FEATURES (Inspired by Singular) ============

  /// Initialize SDK with enhanced configuration
  ///
  /// This enhanced initialization method supports additional features like
  /// SKAdNetwork, privacy controls, and global properties.
  Future<void> initializeEnhanced(IaTrackingConfig config);

  /// Track revenue event
  ///
  /// Track revenue-generating events with automatic revenue metadata.
  Future<void> trackRevenue(IaRevenueEvent revenue);

  /// Track in-app purchase (iOS)
  ///
  /// Tracks iOS in-app purchases with receipt validation data.
  Future<void> trackIOSInAppPurchase(IaIOSInAppPurchase purchase);

  /// Track in-app purchase (Android)
  ///
  /// Tracks Android in-app purchases with signature validation data.
  Future<void> trackAndroidInAppPurchase(IaAndroidInAppPurchase purchase);

  /// Set global property
  ///
  /// Sets a property that will be automatically attached to all future events.
  /// [key] - Property key
  /// [value] - Property value
  /// [overrideExisting] - Whether to override if key already exists
  ///
  /// Returns true if property was set successfully.
  Future<bool> setGlobalProperty(String key, String value,
      {bool overrideExisting = true});

  /// Remove global property
  ///
  /// Removes a global property by key.
  Future<void> unsetGlobalProperty(String key);

  /// Get all global properties
  ///
  /// Returns a map of all currently set global properties.
  Future<Map<String, String>> getGlobalProperties();

  /// Clear all global properties
  ///
  /// Removes all global properties.
  Future<void> clearGlobalProperties();

  /// Set tracking enabled state
  ///
  /// When disabled, all tracking calls will be ignored.
  /// This is different from setEnabled() as it provides more granular control.
  Future<void> setTrackingEnabled(bool enabled);

  /// Check if tracking is enabled
  Future<bool> isTrackingEnabled();

  /// Enable data sharing limitation
  ///
  /// Limits what data is shared with third parties for privacy compliance.
  Future<void> setDataSharingEnabled(bool enabled);

  /// Check if data sharing is enabled
  Future<bool> isDataSharingEnabled();

  /// Tracking opt-in (GDPR compliance)
  ///
  /// Explicitly opt user into tracking for GDPR compliance.
  Future<void> trackingOptIn();

  /// Tracking opt-out (GDPR compliance)
  ///
  /// Explicitly opt user out of tracking for GDPR compliance.
  Future<void> trackingOptOut();

  /// Stop all tracking (stronger than setEnabled)
  ///
  /// Completely stops all tracking operations. Use for GDPR compliance.
  Future<void> stopAllTracking();

  /// Resume all tracking
  ///
  /// Resumes tracking after stopAllTracking() was called.
  Future<void> resumeAllTracking();

  /// Check if all tracking is stopped
  Future<bool> isAllTrackingStopped();

  /// Set device ID for tracking
  ///
  /// Allows manual setting of device identifier.
  Future<void> setDeviceId(String deviceId);

  /// Unset device ID
  ///
  /// Clears manually set device ID, falling back to automatic generation.
  Future<void> unsetDeviceId();

  /// Set session timeout
  ///
  /// [timeoutMinutes] - Session timeout in minutes
  Future<void> setSessionTimeout(int timeoutMinutes);

  // ============ iOS SKAdNetwork Support ============

  /// Register app for SKAdNetwork attribution (iOS only)
  ///
  /// This should be called as early as possible in the app lifecycle.
  Future<void> skanRegisterAppForAttribution();

  /// Update SKAdNetwork conversion value (iOS only)
  ///
  /// [conversionValue] - Value between 0-63
  /// Returns true if update was successful
  Future<bool> skanUpdateConversionValue(int conversionValue);

  /// Update SKAdNetwork conversion values with coarse value (iOS only, SKAdNetwork 4.0)
  ///
  /// [conversionValue] - Fine-grained value
  /// [coarseValue] - Coarse-grained value (0, 1, or 2)
  /// [lockWindow] - Whether to lock the conversion window
  Future<void> skanUpdateConversionValues(
      int conversionValue, int coarseValue, bool lockWindow);

  /// Get current SKAdNetwork conversion value (iOS only)
  ///
  /// Returns current conversion value or -1 if not available
  Future<int> skanGetConversionValue();

  // ============ Push Notifications & Uninstall Tracking ============

  /// Register device token for uninstall tracking (iOS)
  ///
  /// [deviceToken] - APNS device token in hex string format
  Future<void> registerDeviceTokenForUninstall(String deviceToken);

  /// Set FCM token for push notifications (Android)
  ///
  /// [fcmToken] - Firebase Cloud Messaging token
  Future<void> setFCMDeviceToken(String fcmToken);

  /// Handle push notification data (iOS only)
  ///
  /// [notificationPayload] - Push notification payload
  Future<void> handlePushNotification(Map<String, dynamic> notificationPayload);

  // ============ Advanced Configuration ============

  /// Set SDK wrapper information
  ///
  /// Used to identify the wrapper SDK (e.g., Flutter, React Native)
  Future<void> setWrapperInfo(String name, String version);

  /// Get SDK version
  Future<String> getSdkVersion();
}

/// Default implementation of [IaTracker] using method channels
class _IaTrackerImpl extends IaTracker {
  static const flutter_services.MethodChannel _channel =
      flutter_services.MethodChannel('ia_tracking');

  @override
  Future<void> initialize(TrackingConfiguration config) async {
    try {
      await _channel.invokeMethod('initialize', config.toMap());
    } on flutter_services.PlatformException catch (e) {
      throw InitializationException('Failed to initialize: ${e.message}');
    }
  }

  @override
  Future<void> trackScreenView(String screenName) async {
    if (screenName.isEmpty) {
      throw const InvalidParameterException('Screen name cannot be empty');
    }

    try {
      await _channel.invokeMethod('trackScreenView', {
        'screenName': screenName,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to track screen view: ${e.message}');
    }
  }

  @override
  Future<void> trackButtonTap(
    String elementId,
    String screenName, {
    Offset? coordinates,
  }) async {
    if (elementId.isEmpty) {
      throw const InvalidParameterException('Element ID cannot be empty');
    }
    if (screenName.isEmpty) {
      throw const InvalidParameterException('Screen name cannot be empty');
    }

    try {
      final args = <String, dynamic>{
        'elementId': elementId,
        'screenName': screenName,
      };

      if (coordinates != null) {
        args['coordinatesX'] = coordinates.dx;
        args['coordinatesY'] = coordinates.dy;
      }

      await _channel.invokeMethod('trackButtonTap', args);
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to track button tap: ${e.message}');
    }
  }

  @override
  Future<void> trackTextInput(
    String elementId,
    String screenName, {
    int? inputLength,
  }) async {
    if (elementId.isEmpty) {
      throw const InvalidParameterException('Element ID cannot be empty');
    }
    if (screenName.isEmpty) {
      throw const InvalidParameterException('Screen name cannot be empty');
    }

    try {
      await _channel.invokeMethod('trackTextInput', {
        'elementId': elementId,
        'screenName': screenName,
        'inputLength': inputLength,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to track text input: ${e.message}');
    }
  }

  @override
  Future<void> trackNavigation(
    String fromScreen,
    String toScreen, {
    String? method,
  }) async {
    if (fromScreen.isEmpty) {
      throw const InvalidParameterException('From screen cannot be empty');
    }
    if (toScreen.isEmpty) {
      throw const InvalidParameterException('To screen cannot be empty');
    }

    try {
      await _channel.invokeMethod('trackNavigation', {
        'fromScreen': fromScreen,
        'toScreen': toScreen,
        'method': method,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to track navigation: ${e.message}');
    }
  }

  @override
  Future<void> trackSearch(
    String query,
    String screenName, {
    int? resultsCount,
  }) async {
    if (query.isEmpty) {
      throw const InvalidParameterException('Query cannot be empty');
    }
    if (screenName.isEmpty) {
      throw const InvalidParameterException('Screen name cannot be empty');
    }

    try {
      await _channel.invokeMethod('trackSearch', {
        'query': query,
        'screenName': screenName,
        'resultsCount': resultsCount,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to track search: ${e.message}');
    }
  }

  @override
  Future<void> trackCustomEvent(
    String eventName,
    String screenName, {
    String? elementId,
    Map<String, dynamic>? properties,
  }) async {
    if (eventName.isEmpty) {
      throw const InvalidParameterException('Event name cannot be empty');
    }
    if (screenName.isEmpty) {
      throw const InvalidParameterException('Screen name cannot be empty');
    }

    try {
      await _channel.invokeMethod('trackCustomEvent', {
        'eventName': eventName,
        'screenName': screenName,
        'elementId': elementId,
        'properties': properties,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to track custom event: ${e.message}');
    }
  }

  @override
  Future<void> startNewSession() async {
    try {
      await _channel.invokeMethod('startNewSession');
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to start new session: ${e.message}');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await _channel.invokeMethod('setUserId', {
        'userId': userId,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to set user ID: ${e.message}');
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setEnabled', {
        'enabled': enabled,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to set enabled state: ${e.message}');
    }
  }

  @override
  Future<bool> isEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isEnabled');
      return result ?? false;
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to check enabled state: ${e.message}');
    }
  }

  @override
  Future<ActionStatistics> getActionStatistics() async {
    try {
      final result = await _channel.invokeMethod('getActionStatistics');
      if (result == null) {
        throw const DatabaseException('Failed to retrieve action statistics');
      }

      // Cast the result to Map<String, dynamic> safely
      final Map<String, dynamic> statsMap;
      if (result is Map<Object?, Object?>) {
        statsMap = Map<String, dynamic>.from(result);
      } else if (result is Map<String, dynamic>) {
        statsMap = result;
      } else {
        throw const DatabaseException('Invalid statistics data format');
      }

      return ActionStatistics.fromMap(statsMap);
    } on flutter_services.PlatformException catch (e) {
      throw DatabaseException('Failed to get action statistics: ${e.message}');
    }
  }

  @override
  Future<List<UserAction>> getUnsyncedActions({int limit = 50}) async {
    try {
      final result = await _channel.invokeMethod('getUnsyncedActions', {
        'limit': limit,
      });

      if (result == null) {
        return [];
      }

      // Handle type conversion safely
      final List<dynamic> resultList;
      if (result is List<dynamic>) {
        resultList = result;
      } else {
        return [];
      }

      return resultList.map((item) {
        // Convert each action map safely
        final Map<String, dynamic> actionMap;
        if (item is Map<Object?, Object?>) {
          actionMap = Map<String, dynamic>.from(item);
        } else if (item is Map<String, dynamic>) {
          actionMap = item;
        } else {
          return UserAction(
            id: 'unknown',
            actionType: ActionType.custom,
            timestamp: DateTime.now(),
          );
        }

        return UserAction.fromMap(actionMap);
      }).toList();
    } on flutter_services.PlatformException catch (e) {
      throw DatabaseException('Failed to get unsynced actions: ${e.message}');
    }
  }

  @override
  Future<void> markActionsAsSynced(List<String> actionIds) async {
    if (actionIds.isEmpty) {
      return; // Nothing to sync
    }

    try {
      await _channel.invokeMethod('markActionsAsSynced', {
        'actionIds': actionIds,
      });
    } on flutter_services.PlatformException catch (e) {
      throw SyncException('Failed to mark actions as synced: ${e.message}');
    }
  }

  @override
  Future<CleanupStats> getCleanupStats() async {
    try {
      final result = await _channel.invokeMethod('getCleanupStats');
      if (result == null) {
        throw const DatabaseException('Failed to retrieve cleanup stats');
      }

      // Cast the result to Map<String, dynamic> safely
      final Map<String, dynamic> statsMap;
      if (result is Map<Object?, Object?>) {
        statsMap = Map<String, dynamic>.from(result);
      } else if (result is Map<String, dynamic>) {
        statsMap = result;
      } else {
        throw const DatabaseException('Invalid cleanup stats data format');
      }

      return CleanupStats.fromMap(statsMap);
    } on flutter_services.PlatformException catch (e) {
      throw DatabaseException('Failed to get cleanup stats: ${e.message}');
    }
  }

  @override
  Future<void> performCleanup() async {
    try {
      await _channel.invokeMethod('performCleanup');
    } on flutter_services.PlatformException catch (e) {
      throw DatabaseException('Failed to perform cleanup: ${e.message}');
    }
  }

  @override
  Future<void> deleteAllUserData() async {
    try {
      await _channel.invokeMethod('deleteAllUserData');
    } on flutter_services.PlatformException catch (e) {
      throw DatabaseException('Failed to delete user data: ${e.message}');
    }
  }

  @override
  Future<void> flush() async {
    try {
      await _channel.invokeMethod('flush');
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to flush operations: ${e.message}');
    }
  }

  // ============ ENHANCED FEATURES IMPLEMENTATIONS ============

  @override
  Future<void> initializeEnhanced(IaTrackingConfig config) async {
    // Validate configuration before sending to native
    final errors = config.validate();
    if (errors.isNotEmpty) {
      throw InitializationException('Configuration validation failed: ${errors.join(', ')}');
    }

    try {
      await _channel.invokeMethod('initializeEnhanced', config.toMap());
    } on flutter_services.PlatformException catch (e) {
      throw InitializationException('Failed to initialize enhanced: ${e.message}');
    }
  }

  @override
  Future<void> trackRevenue(IaRevenueEvent revenue) async {
    // Validate revenue data
    final errors = revenue.validate();
    if (errors.isNotEmpty) {
      throw InvalidParameterException('Revenue validation failed: ${errors.join(', ')}');
    }

    try {
      await _channel.invokeMethod('trackRevenue', revenue.toMap());
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to track revenue: ${e.message}');
    }
  }

  @override
  Future<void> trackIOSInAppPurchase(IaIOSInAppPurchase purchase) async {
    // Validate purchase data
    final errors = purchase.validate();
    if (errors.isNotEmpty) {
      throw InvalidParameterException('iOS IAP validation failed: ${errors.join(', ')}');
    }

    try {
      await _channel.invokeMethod('trackIOSInAppPurchase', purchase.toMap());
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to track iOS in-app purchase: ${e.message}');
    }
  }

  @override
  Future<void> trackAndroidInAppPurchase(IaAndroidInAppPurchase purchase) async {
    // Validate purchase data
    final errors = purchase.validate();
    if (errors.isNotEmpty) {
      throw InvalidParameterException('Android IAP validation failed: ${errors.join(', ')}');
    }

    try {
      await _channel.invokeMethod('trackAndroidInAppPurchase', purchase.toMap());
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to track Android in-app purchase: ${e.message}');
    }
  }

  @override
  Future<bool> setGlobalProperty(String key, String value, {bool overrideExisting = true}) async {
    if (key.isEmpty) {
      throw const InvalidParameterException('Global property key cannot be empty');
    }

    try {
      final result = await _channel.invokeMethod<bool>('setGlobalProperty', {
        'key': key,
        'value': value,
        'overrideExisting': overrideExisting,
      });
      return result ?? false;
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to set global property: ${e.message}');
    }
  }

  @override
  Future<void> unsetGlobalProperty(String key) async {
    if (key.isEmpty) {
      throw const InvalidParameterException('Global property key cannot be empty');
    }

    try {
      await _channel.invokeMethod('unsetGlobalProperty', {
        'key': key,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to unset global property: ${e.message}');
    }
  }

  @override
  Future<Map<String, String>> getGlobalProperties() async {
    try {
      final result = await _channel.invokeMethod('getGlobalProperties');
      if (result == null) {
        return {};
      }

      // Convert result to Map<String, String>
      if (result is Map<Object?, Object?>) {
        return Map<String, String>.from(result);
      } else if (result is Map<String, String>) {
        return result;
      } else {
        return {};
      }
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to get global properties: ${e.message}');
    }
  }

  @override
  Future<void> clearGlobalProperties() async {
    try {
      await _channel.invokeMethod('clearGlobalProperties');
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to clear global properties: ${e.message}');
    }
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setTrackingEnabled', {
        'enabled': enabled,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to set tracking enabled: ${e.message}');
    }
  }

  @override
  Future<bool> isTrackingEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isTrackingEnabled');
      return result ?? false;
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to check tracking enabled: ${e.message}');
    }
  }

  @override
  Future<void> setDataSharingEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setDataSharingEnabled', {
        'enabled': enabled,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to set data sharing enabled: ${e.message}');
    }
  }

  @override
  Future<bool> isDataSharingEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDataSharingEnabled');
      return result ?? false;
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to check data sharing enabled: ${e.message}');
    }
  }

  @override
  Future<void> trackingOptIn() async {
    try {
      await _channel.invokeMethod('trackingOptIn');
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to opt-in to tracking: ${e.message}');
    }
  }

  @override
  Future<void> trackingOptOut() async {
    try {
      await _channel.invokeMethod('trackingOptOut');
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to opt-out of tracking: ${e.message}');
    }
  }

  @override
  Future<void> stopAllTracking() async {
    try {
      await _channel.invokeMethod('stopAllTracking');
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to stop all tracking: ${e.message}');
    }
  }

  @override
  Future<void> resumeAllTracking() async {
    try {
      await _channel.invokeMethod('resumeAllTracking');
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to resume all tracking: ${e.message}');
    }
  }

  @override
  Future<bool> isAllTrackingStopped() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAllTrackingStopped');
      return result ?? false;
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to check if all tracking stopped: ${e.message}');
    }
  }

  @override
  Future<void> setDeviceId(String deviceId) async {
    if (deviceId.isEmpty) {
      throw const InvalidParameterException('Device ID cannot be empty');
    }

    try {
      await _channel.invokeMethod('setDeviceId', {
        'deviceId': deviceId,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to set device ID: ${e.message}');
    }
  }

  @override
  Future<void> unsetDeviceId() async {
    try {
      await _channel.invokeMethod('unsetDeviceId');
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to unset device ID: ${e.message}');
    }
  }

  @override
  Future<void> setSessionTimeout(int timeoutMinutes) async {
    if (timeoutMinutes <= 0) {
      throw const InvalidParameterException('Session timeout must be greater than 0');
    }

    try {
      await _channel.invokeMethod('setSessionTimeout', {
        'timeoutMinutes': timeoutMinutes,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to set session timeout: ${e.message}');
    }
  }

  // ============ iOS SKAdNetwork Support ============

  @override
  Future<void> skanRegisterAppForAttribution() async {
    try {
      await _channel.invokeMethod('skanRegisterAppForAttribution');
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to register for SKAdNetwork: ${e.message}');
    }
  }

  @override
  Future<bool> skanUpdateConversionValue(int conversionValue) async {
    if (conversionValue < 0 || conversionValue > 63) {
      throw const InvalidParameterException('SKAdNetwork conversion value must be between 0-63');
    }

    try {
      final result = await _channel.invokeMethod<bool>('skanUpdateConversionValue', {
        'conversionValue': conversionValue,
      });
      return result ?? false;
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to update SKAdNetwork conversion value: ${e.message}');
    }
  }

  @override
  Future<void> skanUpdateConversionValues(int conversionValue, int coarseValue, bool lockWindow) async {
    if (conversionValue < 0 || conversionValue > 63) {
      throw const InvalidParameterException('SKAdNetwork conversion value must be between 0-63');
    }
    if (coarseValue < 0 || coarseValue > 2) {
      throw const InvalidParameterException('SKAdNetwork coarse value must be between 0-2');
    }

    try {
      await _channel.invokeMethod('skanUpdateConversionValues', {
        'conversionValue': conversionValue,
        'coarseValue': coarseValue,
        'lockWindow': lockWindow,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to update SKAdNetwork conversion values: ${e.message}');
    }
  }

  @override
  Future<int> skanGetConversionValue() async {
    try {
      final result = await _channel.invokeMethod<int>('skanGetConversionValue');
      return result ?? -1;
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to get SKAdNetwork conversion value: ${e.message}');
    }
  }

  // ============ Push Notifications & Uninstall Tracking ============

  @override
  Future<void> registerDeviceTokenForUninstall(String deviceToken) async {
    if (deviceToken.isEmpty) {
      throw const InvalidParameterException('Device token cannot be empty');
    }

    try {
      await _channel.invokeMethod('registerDeviceTokenForUninstall', {
        'deviceToken': deviceToken,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to register device token: ${e.message}');
    }
  }

  @override
  Future<void> setFCMDeviceToken(String fcmToken) async {
    if (fcmToken.isEmpty) {
      throw const InvalidParameterException('FCM token cannot be empty');
    }

    try {
      await _channel.invokeMethod('setFCMDeviceToken', {
        'fcmToken': fcmToken,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to set FCM device token: ${e.message}');
    }
  }

  @override
  Future<void> handlePushNotification(Map<String, dynamic> notificationPayload) async {
    if (notificationPayload.isEmpty) {
      throw const InvalidParameterException('Notification payload cannot be empty');
    }

    try {
      await _channel.invokeMethod('handlePushNotification', {
        'notificationPayload': notificationPayload,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to handle push notification: ${e.message}');
    }
  }

  // ============ Advanced Configuration ============

  @override
  Future<void> setWrapperInfo(String name, String version) async {
    if (name.isEmpty) {
      throw const InvalidParameterException('Wrapper name cannot be empty');
    }
    if (version.isEmpty) {
      throw const InvalidParameterException('Wrapper version cannot be empty');
    }

    try {
      await _channel.invokeMethod('setWrapperInfo', {
        'name': name,
        'version': version,
      });
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to set wrapper info: ${e.message}');
    }
  }

  @override
  Future<String> getSdkVersion() async {
    try {
      final result = await _channel.invokeMethod<String>('getSdkVersion');
      return result ?? 'unknown';
    } on flutter_services.PlatformException catch (e) {
      throw PlatformException('Failed to get SDK version: ${e.message}');
    }
  }
}
