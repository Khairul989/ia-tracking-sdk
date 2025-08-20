/// Statistics about tracked actions
class ActionStatistics {
  /// Create action statistics
  const ActionStatistics({
    required this.totalActions,
    required this.unsyncedActions,
    required this.syncedActions,
    required this.failedActions,
  });

  /// Create from Map (for method channel communication)
  factory ActionStatistics.fromMap(Map<String, dynamic> map) {
    return ActionStatistics(
      totalActions: map['totalActions'] ?? 0,
      unsyncedActions: map['unsyncedActions'] ?? 0,
      syncedActions: map['syncedActions'] ?? 0,
      failedActions: map['failedActions'] ?? 0,
    );
  }

  /// Total number of actions tracked
  final int totalActions;

  /// Number of actions not yet synced to server
  final int unsyncedActions;

  /// Number of actions successfully synced to server
  final int syncedActions;

  /// Number of actions that failed to sync
  final int failedActions;

  /// Convert to Map for method channel communication
  Map<String, dynamic> toMap() {
    return {
      'totalActions': totalActions,
      'unsyncedActions': unsyncedActions,
      'syncedActions': syncedActions,
      'failedActions': failedActions,
    };
  }

  /// Sync success rate as a percentage (0.0 to 1.0)
  double get syncSuccessRate {
    if (totalActions == 0) return 1.0;
    return syncedActions / totalActions;
  }

  /// Whether there are pending actions to sync
  bool get hasPendingActions => unsyncedActions > 0;

  @override
  String toString() {
    return 'ActionStatistics('
        'total: $totalActions, '
        'unsynced: $unsyncedActions, '
        'synced: $syncedActions, '
        'failed: $failedActions)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionStatistics &&
          runtimeType == other.runtimeType &&
          totalActions == other.totalActions &&
          unsyncedActions == other.unsyncedActions &&
          syncedActions == other.syncedActions &&
          failedActions == other.failedActions;

  @override
  int get hashCode =>
      totalActions.hashCode ^
      unsyncedActions.hashCode ^
      syncedActions.hashCode ^
      failedActions.hashCode;
}
