import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart' as flutter_services;
import 'package:ia_tracking/src/exceptions/ia_tracking_exception.dart';
import 'package:ia_tracking/src/models/action_statistics.dart';
import 'package:ia_tracking/src/models/action_type.dart';
import 'package:ia_tracking/src/models/cleanup_stats.dart';
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
}
