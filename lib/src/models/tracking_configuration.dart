/// Configuration class for the IA Tracking SDK
class TrackingConfiguration {
  /// Create a tracking configuration
  const TrackingConfiguration({
    this.userId,
    this.appVersion,
    this.maxDatabaseSize = 50 * 1024 * 1024, // 50MB
    this.maxRetentionDays = 30,
    this.sessionTimeoutMinutes = 30,
    this.batchSize = 50,
    this.serverUrl,
    this.apiKey,
    this.debugMode = false,
  });

  /// Create from Map (for method channel communication)
  factory TrackingConfiguration.fromMap(Map<String, dynamic> map) {
    return TrackingConfiguration(
      userId: map['userId'],
      appVersion: map['appVersion'],
      maxDatabaseSize: map['maxDatabaseSize'] ?? 50 * 1024 * 1024,
      maxRetentionDays: map['maxRetentionDays'] ?? 30,
      sessionTimeoutMinutes: map['sessionTimeoutMinutes'] ?? 30,
      batchSize: map['batchSize'] ?? 50,
      serverUrl: map['serverUrl'],
      apiKey: map['apiKey'],
      debugMode: map['debugMode'] ?? false,
    );
  }

  /// User identifier (optional)
  final String? userId;

  /// Application version
  final String? appVersion;

  /// Maximum database size in bytes (default: 50MB)
  final int maxDatabaseSize;

  /// Maximum data retention period in days (default: 30 days)
  final int maxRetentionDays;

  /// Session timeout in minutes (default: 30 minutes)
  final int sessionTimeoutMinutes;

  /// Batch size for data export operations (default: 50)
  final int batchSize;

  /// Server URL for data synchronization (optional)
  final String? serverUrl;

  /// API key for server authentication (optional)
  final String? apiKey;

  /// Enable debug mode for development (default: false)
  final bool debugMode;

  /// Create a copy of this configuration with updated values
  TrackingConfiguration copyWith({
    String? userId,
    String? appVersion,
    int? maxDatabaseSize,
    int? maxRetentionDays,
    int? sessionTimeoutMinutes,
    int? batchSize,
    String? serverUrl,
    String? apiKey,
    bool? debugMode,
  }) {
    return TrackingConfiguration(
      userId: userId ?? this.userId,
      appVersion: appVersion ?? this.appVersion,
      maxDatabaseSize: maxDatabaseSize ?? this.maxDatabaseSize,
      maxRetentionDays: maxRetentionDays ?? this.maxRetentionDays,
      sessionTimeoutMinutes:
          sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      batchSize: batchSize ?? this.batchSize,
      serverUrl: serverUrl ?? this.serverUrl,
      apiKey: apiKey ?? this.apiKey,
      debugMode: debugMode ?? this.debugMode,
    );
  }

  /// Convert to Map for method channel communication
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'appVersion': appVersion,
      'maxDatabaseSize': maxDatabaseSize,
      'maxRetentionDays': maxRetentionDays,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
      'batchSize': batchSize,
      'serverUrl': serverUrl,
      'apiKey': apiKey,
      'debugMode': debugMode,
    };
  }

  @override
  String toString() {
    return 'TrackingConfiguration('
        'userId: $userId, '
        'appVersion: $appVersion, '
        'maxDatabaseSize: $maxDatabaseSize, '
        'maxRetentionDays: $maxRetentionDays, '
        'sessionTimeoutMinutes: $sessionTimeoutMinutes, '
        'batchSize: $batchSize, '
        'serverUrl: $serverUrl, '
        'debugMode: $debugMode)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackingConfiguration &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          appVersion == other.appVersion &&
          maxDatabaseSize == other.maxDatabaseSize &&
          maxRetentionDays == other.maxRetentionDays &&
          sessionTimeoutMinutes == other.sessionTimeoutMinutes &&
          batchSize == other.batchSize &&
          serverUrl == other.serverUrl &&
          apiKey == other.apiKey &&
          debugMode == other.debugMode;

  @override
  int get hashCode =>
      userId.hashCode ^
      appVersion.hashCode ^
      maxDatabaseSize.hashCode ^
      maxRetentionDays.hashCode ^
      sessionTimeoutMinutes.hashCode ^
      batchSize.hashCode ^
      serverUrl.hashCode ^
      apiKey.hashCode ^
      debugMode.hashCode;
}
