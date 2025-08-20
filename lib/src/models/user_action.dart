import 'package:ia_tracking/src/models/action_type.dart';

/// Represents a user action that has been tracked
class UserAction {
  /// Create a new user action
  const UserAction({
    required this.id,
    required this.actionType,
    required this.timestamp,
    this.screenName,
    this.elementId,
    this.elementType,
    this.userId,
    this.sessionId,
    this.properties,
    this.deviceInfo,
    this.appVersion,
    this.sdkVersion,
    this.appId,
    this.isSynced = false,
    this.retryCount = 0,
  });

  /// Create from Map (for method channel communication)
  factory UserAction.fromMap(Map<String, dynamic> map) {
    return UserAction(
      id: map['id'] ?? '',
      actionType: ActionTypeExtension.fromString(map['actionType'] ?? 'custom'),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      screenName: map['screenName'],
      elementId: map['elementId'],
      elementType: map['elementType'],
      userId: map['userId'],
      appId: map['appId'],
      sessionId: map['sessionId'],
      properties: map['properties'] != null
          ? Map<String, dynamic>.from(map['properties'])
          : null,
      deviceInfo: map['deviceInfo'] != null
          ? Map<String, dynamic>.from(map['deviceInfo'])
          : null,
      appVersion: map['appVersion'],
      sdkVersion: map['sdkVersion'],
      isSynced: map['isSynced'] ?? false,
      retryCount: map['retryCount'] ?? 0,
    );
  }

  /// Unique identifier for this action
  final String id;

  /// Type of action performed
  final ActionType actionType;

  /// Name of the screen where action occurred
  final String? screenName;

  /// ID of the UI element that was interacted with
  final String? elementId;

  /// Type of UI element (button, input, etc.)
  final String? elementType;

  /// User identifier who performed the action
  final String? userId;

  /// Session ID when action was performed
  final String? sessionId;

  /// Timestamp when action was recorded
  final DateTime timestamp;

  /// Additional properties specific to this action
  final Map<String, dynamic>? properties;

  /// Device information at time of action
  final Map<String, dynamic>? deviceInfo;

  /// Application version when action was recorded
  final String? appVersion;

  /// SDK version that recorded this action
  final String? sdkVersion;

  /// Whether this action has been synchronized to server
  final bool isSynced;

  /// Number of retry attempts for failed sync operations
  final int retryCount;

  /// Application ID when action was recorded
  final String? appId;

  /// Convert to Map for method channel communication
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actionType': actionType.value,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'screenName': screenName,
      'elementId': elementId,
      'elementType': elementType,
      'userId': userId,
      'appId': appId,
      'sessionId': sessionId,
      'properties': properties,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'sdkVersion': sdkVersion,
      'isSynced': isSynced,
      'retryCount': retryCount,
    };
  }

  /// Create a copy with updated fields
  UserAction copyWith({
    String? id,
    ActionType? actionType,
    DateTime? timestamp,
    String? screenName,
    String? elementId,
    String? elementType,
    String? userId,
    String? appId,
    String? sessionId,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? deviceInfo,
    String? appVersion,
    String? sdkVersion,
    bool? isSynced,
    int? retryCount,
  }) {
    return UserAction(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      timestamp: timestamp ?? this.timestamp,
      screenName: screenName ?? this.screenName,
      elementId: elementId ?? this.elementId,
      elementType: elementType ?? this.elementType,
      userId: userId ?? this.userId,
      appId: appId ?? this.appId,
      sessionId: sessionId ?? this.sessionId,
      properties: properties ?? this.properties,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
      sdkVersion: sdkVersion ?? this.sdkVersion,
      isSynced: isSynced ?? this.isSynced,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  String toString() {
    return 'UserAction('
        'id: $id, '
        'actionType: $actionType, '
        'screenName: $screenName, '
        'elementId: $elementId, '
        'timestamp: $timestamp, '
        'isSynced: $isSynced, '
        'appId: $appId)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          actionType == other.actionType &&
          screenName == other.screenName &&
          elementId == other.elementId &&
          elementType == other.elementType &&
          userId == other.userId &&
          sessionId == other.sessionId &&
          timestamp == other.timestamp &&
          properties == other.properties &&
          deviceInfo == other.deviceInfo &&
          appVersion == other.appVersion &&
          sdkVersion == other.sdkVersion &&
          isSynced == other.isSynced &&
          appId == other.appId &&
          retryCount == other.retryCount;

  @override
  int get hashCode =>
      id.hashCode ^
      actionType.hashCode ^
      screenName.hashCode ^
      elementId.hashCode ^
      elementType.hashCode ^
      userId.hashCode ^
      sessionId.hashCode ^
      timestamp.hashCode ^
      properties.hashCode ^
      deviceInfo.hashCode ^
      appVersion.hashCode ^
      sdkVersion.hashCode ^
      isSynced.hashCode ^
      retryCount.hashCode ^
      appId.hashCode;
}
