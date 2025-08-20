import 'package:flutter/material.dart';
import 'package:ia_tracking/ia_tracking.dart';

class DetailedStatisticsScreen extends StatefulWidget {
  const DetailedStatisticsScreen({super.key});

  @override
  State<DetailedStatisticsScreen> createState() =>
      _DetailedStatisticsScreenState();
}

class _DetailedStatisticsScreenState extends State<DetailedStatisticsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';

  // Statistics data
  ActionStatistics? _statistics;
  List<UserAction> _unsyncedActions = [];
  List<UserAction> _allActions = [];
  CleanupStats? _cleanupStats;

  // UI state - updated
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadAllStatistics();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAllStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load statistics sequentially with proper error handling
      final statistics = await IaTracker.instance.getActionStatistics();
      final unsyncedActions =
          await IaTracker.instance.getUnsyncedActions(limit: 100);
      final cleanupStats = await IaTracker.instance.getCleanupStats();

      // Defensive normalization: ensure properties maps are String->dynamic
      final normalizedUnsynced = unsyncedActions
          .map((a) => _normalizeUserAction(a))
          .toList(growable: false);

      setState(() {
        _statistics = statistics;
        _unsyncedActions = normalizedUnsynced;
        _cleanupStats = cleanupStats;

        // Show real user actions
        _allActions = List.from(normalizedUnsynced);

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load statistics: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Statistics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadAllStatistics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading statistics...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAllStatistics,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      children: [
        _buildOverviewTab(),
        _buildActionsTab(_allActions, 'All Actions'),
        _buildActionsTab(_unsyncedActions, 'Unsynced Actions'),
        _buildCleanupTab(),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedTabIndex,
      onTap: (index) {
        setState(() {
          _selectedTabIndex = index;
        });
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Overview',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'All Actions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sync_problem),
          label: 'Unsynced',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cleaning_services),
          label: 'Cleanup',
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsCard(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
          const SizedBox(height: 16),
          _buildRecentActionsCard(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final stats = _statistics!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Actions',
                    stats.totalActions.toString(),
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Synced',
                    stats.syncedActions.toString(),
                    Icons.cloud_done,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Unsynced',
                    stats.unsyncedActions.toString(),
                    Icons.cloud_upload,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Failed',
                    stats.failedActions.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _syncAllActions,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync All'),
                ),
                ElevatedButton.icon(
                  onPressed: _performCleanup,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Cleanup'),
                ),
                ElevatedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAllData,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActionsCard() {
    final recentActions = _allActions.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTabIndex = 1;
                    });
                    _pageController.animateToPage(1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recentActions.map((action) => _buildActionListTile(action)),
            if (recentActions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text('No actions recorded yet'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsTab(List<UserAction> actions, String title) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title (${actions.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: _loadAllStatistics,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(
          child: actions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No actions found'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: actions.length,
                  itemBuilder: (context, index) {
                    final action = actions[index];
                    return _buildActionListTile(action, showDivider: true);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActionListTile(UserAction action, {bool showDivider = false}) {
    final isRecent = DateTime.now().difference(action.timestamp).inMinutes < 5;
    final isSynced = action.properties?['synced'] == true;

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: _getActionColor(action.actionType),
            child: Icon(
              _getActionIcon(action.actionType),
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            '${action.actionType.value} - ${action.screenName ?? 'Unknown'}',
            style: TextStyle(
              fontWeight: isRecent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // element id if present
              if (action.elementId?.isNotEmpty == true)
                Text('Element: ${action.elementId!}'),

              // user / session summary (if available)
              if ((action.userId?.isNotEmpty ?? false) ||
                  (action.sessionId?.isNotEmpty ?? false))
                Text(
                  'User: ${action.userId ?? 'Anonymous'}  •  Session: ${action.sessionId ?? '—'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

              // timestamp
              Text(
                _formatTimestamp(action.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),

              // small preview of properties as chips
              if (action.properties?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: _buildPropertiesPreview(action),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRecent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                isSynced ? Icons.cloud_done : Icons.cloud_upload,
                color: isSynced ? Colors.green : Colors.orange,
                size: 16,
              ),
            ],
          ),
          onTap: () => _showActionDetails(action),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  Widget _buildPropertiesPreview(UserAction action) {
    final entries = action.properties!.entries.toList();
    final preview = entries.take(3).map((e) {
      final key = e.key;
      final val = e.value?.toString() ?? '';
      final display = val.length > 18 ? '${val.substring(0, 18)}…' : val;
      return Chip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        label: Text('$key: $display', style: const TextStyle(fontSize: 12)),
      );
    }).toList();

    // if there are more properties than previewed, add a small indicator
    if (entries.length > 3) {
      preview.add(const Chip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        label: Text('…', style: TextStyle(fontSize: 12)),
      ));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: preview,
    );
  }

  Widget _buildCleanupTab() {
    final cleanup = _cleanupStats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: cleanup.estimatedSizeBytes / cleanup.maxSizeBytes,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatBytes(cleanup.estimatedSizeBytes)} / ${_formatBytes(cleanup.maxSizeBytes)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  _buildCleanupInfo(
                      'Total Actions', cleanup.totalActions.toString()),
                  _buildCleanupInfo(
                      'Unsynced Actions', cleanup.unsyncedActions.toString()),
                  _buildCleanupInfo(
                      'Synced Actions', cleanup.syncedActions.toString()),
                  _buildCleanupInfo(
                      'Retention Period', '${cleanup.retentionDays} days'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maintenance Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _performCleanup,
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('Perform Cleanup'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _clearAllData,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete All Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanupInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(ActionType actionType) {
    switch (actionType) {
      case ActionType.screenView:
        return Colors.blue;
      case ActionType.buttonTap:
        return Colors.green;
      case ActionType.textInput:
        return Colors.orange;
      case ActionType.navigation:
        return Colors.purple;
      case ActionType.search:
        return Colors.teal;
      case ActionType.custom:
        return Colors.indigo;
    }
  }

  IconData _getActionIcon(ActionType actionType) {
    switch (actionType) {
      case ActionType.screenView:
        return Icons.visibility;
      case ActionType.buttonTap:
        return Icons.touch_app;
      case ActionType.textInput:
        return Icons.keyboard;
      case ActionType.navigation:
        return Icons.navigation;
      case ActionType.search:
        return Icons.search;
      case ActionType.custom:
        return Icons.star;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  // Normalize a Map<Object?,Object?> or Map<String,dynamic> into Map<String,dynamic>
  Map<String, dynamic>? _normalizeProps(Map? props) {
    if (props == null) return null;
    final out = <String, dynamic>{};
    try {
      // Try generic iteration
      props.forEach((k, v) {
        out[k?.toString() ?? ''] = v;
      });
    } catch (_) {
      // Fallback to cast
      try {
        final casted = (props).cast<String, dynamic>();
        out.addAll(casted);
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return out;
  }

  // Create a UserAction from a possibly-untyped UserAction instance returned
  // by the platform implementation. If the object is already a UserAction,
  // return it directly. If it's a Map, convert safely.
  UserAction _normalizeUserAction(dynamic raw) {
    if (raw is UserAction) return raw;
    if (raw is Map) {
      final map = <String, dynamic>{};
      raw.forEach((k, v) => map[k?.toString() ?? ''] = v);
      // ensure properties is normalized
      if (map['properties'] is Map) {
        map['properties'] = _normalizeProps(map['properties']);
      }
      try {
        return UserAction.fromMap(map);
      } catch (e) {
        // Fallback: construct minimal UserAction
        return UserAction(
          id: map['id']?.toString() ?? 'unknown',
          userId: map['userId']?.toString(),
          sessionId: map['sessionId']?.toString(),
          actionType: ActionType.values.firstWhere(
              (t) => t.value == map['actionType'],
              orElse: () => ActionType.custom),
          screenName: map['screenName']?.toString(),
          elementId: map['elementId']?.toString(),
          timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
              DateTime.now(),
          properties: (map['properties'] as Map?)?.cast<String, dynamic>(),
        );
      }
    }

    // Last resort: empty minimal action
    return UserAction(
      id: 'unknown',
      userId: null,
      sessionId: null,
      actionType: ActionType.custom,
      screenName: 'Unknown',
      elementId: null,
      timestamp: DateTime.now(),
      properties: {},
    );
  }

  void _showActionDetails(UserAction action) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Action Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailRow('ID', action.id),
                    _buildDetailRow('Type', action.actionType.value),
                    _buildDetailRow('Screen', action.screenName ?? 'Unknown'),
                    if (action.elementId?.isNotEmpty == true)
                      _buildDetailRow('Element', action.elementId!),
                    _buildDetailRow('User ID', action.userId ?? 'Anonymous'),
                    _buildDetailRow('Session ID', action.sessionId ?? 'None'),
                    _buildDetailRow('Timestamp', action.timestamp.toString()),
                    _buildDetailRow(
                        'Formatted Time', _formatTimestamp(action.timestamp)),
                    if (action.properties?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Properties',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...action.properties!.entries.map(
                        (entry) =>
                            _buildDetailRow(entry.key, entry.value.toString()),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _syncAllActions() async {
    if (_unsyncedActions.isEmpty) return;

    try {
      final actionIds = _unsyncedActions.map((action) => action.id).toList();
      await IaTracker.instance.markActionsAsSynced(actionIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synced ${actionIds.length} actions'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAllStatistics();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync actions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performCleanup() async {
    try {
      await IaTracker.instance.performCleanup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cleanup completed'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAllStatistics();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to perform cleanup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    // In a real implementation, you would export to file or share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality would be implemented here'),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all tracking data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await IaTracker.instance.deleteAllUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data cleared'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAllStatistics();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
