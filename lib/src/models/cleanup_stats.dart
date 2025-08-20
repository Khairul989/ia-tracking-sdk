/// Statistics about data cleanup and retention
class CleanupStats {
  /// Create cleanup statistics
  const CleanupStats({
    required this.totalActions,
    required this.unsyncedActions,
    required this.syncedActions,
    required this.estimatedSizeBytes,
    required this.maxSizeBytes,
    required this.retentionDays,
  });

  /// Create from Map (for method channel communication)
  factory CleanupStats.fromMap(Map<String, dynamic> map) {
    return CleanupStats(
      totalActions: map['totalActions'] ?? 0,
      unsyncedActions: map['unsyncedActions'] ?? 0,
      syncedActions: map['syncedActions'] ?? 0,
      estimatedSizeBytes: map['estimatedSizeBytes'] ?? 0,
      maxSizeBytes: map['maxSizeBytes'] ?? 0,
      retentionDays: map['retentionDays'] ?? 0,
    );
  }

  /// Total number of actions in database
  final int totalActions;

  /// Number of unsynced actions
  final int unsyncedActions;

  /// Number of synced actions
  final int syncedActions;

  /// Estimated database size in bytes
  final int estimatedSizeBytes;

  /// Maximum allowed database size in bytes
  final int maxSizeBytes;

  /// Data retention period in days
  final int retentionDays;

  /// Convert to Map for method channel communication
  Map<String, dynamic> toMap() {
    return {
      'totalActions': totalActions,
      'unsyncedActions': unsyncedActions,
      'syncedActions': syncedActions,
      'estimatedSizeBytes': estimatedSizeBytes,
      'maxSizeBytes': maxSizeBytes,
      'retentionDays': retentionDays,
    };
  }

  /// Database usage as a percentage (0.0 to 1.0)
  double get usagePercentage {
    if (maxSizeBytes <= 0) return 0.0;
    return (estimatedSizeBytes / maxSizeBytes).clamp(0.0, 1.0);
  }

  /// Whether database is near capacity (>80% usage)
  bool get isNearCapacity => usagePercentage > 0.8;

  /// Whether emergency cleanup is needed (>90% usage)
  bool get needsEmergencyCleanup => usagePercentage > 0.9;

  /// Estimated size in human-readable format
  String get estimatedSizeFormatted => _formatBytes(estimatedSizeBytes);

  /// Max size in human-readable format
  String get maxSizeFormatted => _formatBytes(maxSizeBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  String toString() {
    return 'CleanupStats('
        'totalActions: $totalActions, '
        'size: $estimatedSizeFormatted/$maxSizeFormatted, '
        'usage: ${(usagePercentage * 100).toStringAsFixed(1)}%, '
        'retention: ${retentionDays}d)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CleanupStats &&
          runtimeType == other.runtimeType &&
          totalActions == other.totalActions &&
          unsyncedActions == other.unsyncedActions &&
          syncedActions == other.syncedActions &&
          estimatedSizeBytes == other.estimatedSizeBytes &&
          maxSizeBytes == other.maxSizeBytes &&
          retentionDays == other.retentionDays;

  @override
  int get hashCode =>
      totalActions.hashCode ^
      unsyncedActions.hashCode ^
      syncedActions.hashCode ^
      estimatedSizeBytes.hashCode ^
      maxSizeBytes.hashCode ^
      retentionDays.hashCode;
}
