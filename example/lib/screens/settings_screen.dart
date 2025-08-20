import 'package:flutter/material.dart';
import 'package:ia_tracking/ia_tracking.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isTrackingEnabled = true;
  String _currentUserId = '';
  String _statusMessage = 'Loading settings...';

  final _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
    _trackScreenView();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _trackScreenView() async {
    try {
      await IaTracker.instance.trackScreenView('SettingsScreen');
    } catch (e) {
      _updateStatus('Failed to track screen view: $e');
    }
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final isEnabled = await IaTracker.instance.isEnabled();
      setState(() {
        _isTrackingEnabled = isEnabled;
        _statusMessage = 'Settings loaded';
      });
    } catch (e) {
      _updateStatus('Failed to load settings: $e');
    }
  }

  Future<void> _toggleTracking() async {
    try {
      await IaTracker.instance.trackButtonTap(
        'toggle_tracking_button',
        'SettingsScreen',
      );

      final newState = !_isTrackingEnabled;
      await IaTracker.instance.setEnabled(newState);

      setState(() {
        _isTrackingEnabled = newState;
      });
      _updateStatus('Tracking ${newState ? 'enabled' : 'disabled'}');
    } catch (e) {
      _updateStatus('Failed to toggle tracking: $e');
    }
  }

  Future<void> _updateUserId() async {
    try {
      await IaTracker.instance.trackButtonTap(
        'update_user_id_button',
        'SettingsScreen',
      );

      final newUserId = _userIdController.text.trim();

      if (newUserId.isEmpty) {
        _updateStatus('User ID cannot be empty');
        return;
      }

      await IaTracker.instance.setUserId(newUserId);

      setState(() {
        _currentUserId = newUserId;
      });
      _updateStatus('User ID updated to: $newUserId');

      // Clear the text field
      _userIdController.clear();

      // Start a new session with the new user ID
      await IaTracker.instance.startNewSession();
      _updateStatus('New session started with updated user ID');
    } catch (e) {
      _updateStatus('Failed to update user ID: $e');
    }
  }

  Future<void> _clearUserId() async {
    try {
      await IaTracker.instance.trackButtonTap(
        'clear_user_id_button',
        'SettingsScreen',
      );

      await IaTracker.instance.setUserId(null);

      setState(() {
        _currentUserId = '';
      });
      _updateStatus('User ID cleared (anonymous tracking)');

      // Start a new session
      await IaTracker.instance.startNewSession();
    } catch (e) {
      _updateStatus('Failed to clear user ID: $e');
    }
  }

  Future<void> _showCleanupStats() async {
    try {
      await IaTracker.instance.trackButtonTap(
        'show_cleanup_stats_button',
        'SettingsScreen',
      );

      final stats = await IaTracker.instance.getCleanupStats();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Data & Cleanup Statistics'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow('Total Actions:', '${stats.totalActions}'),
                  _buildStatRow(
                      'Unsynced Actions:', '${stats.unsyncedActions}'),
                  _buildStatRow('Synced Actions:', '${stats.syncedActions}'),
                  _buildStatRow(
                      'Database Size:', _formatBytes(stats.estimatedSizeBytes)),
                  _buildStatRow('Max Size:', _formatBytes(stats.maxSizeBytes)),
                  _buildStatRow('Retention Days:', '${stats.retentionDays}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performCleanup();
                },
                child: const Text('Run Cleanup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _updateStatus('Failed to get cleanup stats: $e');
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<void> _performCleanup() async {
    try {
      await IaTracker.instance.performCleanup();
      _updateStatus('Data cleanup completed');
    } catch (e) {
      _updateStatus('Failed to perform cleanup: $e');
    }
  }

  Future<void> _deleteAllUserData() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete All User Data'),
          content: const Text(
            'This will permanently delete all tracked user data. '
            'This action cannot be undone. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete All Data'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await IaTracker.instance.trackButtonTap(
          'delete_all_data_button',
          'SettingsScreen',
        );

        await IaTracker.instance.deleteAllUserData();
        _updateStatus('All user data deleted');
      }
    } catch (e) {
      _updateStatus('Failed to delete user data: $e');
    }
  }

  Future<void> _exportUnsyncedData() async {
    try {
      await IaTracker.instance.trackButtonTap(
        'export_unsynced_button',
        'SettingsScreen',
      );

      final actions = await IaTracker.instance.getUnsyncedActions(limit: 100);

      if (actions.isEmpty) {
        _updateStatus('No unsynced data to export');
        return;
      }

      // For demo purposes, just show the count
      // In a real app, you would export this data to a file or send to server
      _updateStatus('Found ${actions.length} unsynced actions');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsynced Data Export'),
            content: Text(
              'Found ${actions.length} unsynced actions ready for export.\n\n'
              'In a production app, this data would be exported to a file '
              'or synchronized with your server.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _markDataAsSynced(actions.map((a) => a.id).toList());
                },
                child: const Text('Mark as Synced'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _updateStatus('Failed to export data: $e');
    }
  }

  Future<void> _markDataAsSynced(List<String> actionIds) async {
    try {
      await IaTracker.instance.markActionsAsSynced(actionIds);
      _updateStatus('${actionIds.length} actions marked as synced');
    } catch (e) {
      _updateStatus('Failed to mark actions as synced: $e');
    }
  }

  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });

    // Clear status after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Ready';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Tracking Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tracking Control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tracking Control',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Tracking'),
                      subtitle: Text(
                        _isTrackingEnabled
                            ? 'User actions are being tracked'
                            : 'Tracking is disabled',
                      ),
                      value: _isTrackingEnabled,
                      onChanged: (value) => _toggleTracking(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // User Management
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (_currentUserId.isNotEmpty) ...[
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Current User ID'),
                        subtitle: Text(_currentUserId),
                        trailing: IconButton(
                          onPressed: _clearUserId,
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear User ID',
                        ),
                      ),
                      const Divider(),
                    ],
                    TextField(
                      controller: _userIdController,
                      decoration: const InputDecoration(
                        labelText: 'New User ID',
                        hintText: 'Enter user identifier',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _updateUserId(),
                      onChanged: (value) {
                        // Track text input
                        if (value.isNotEmpty) {
                          IaTracker.instance
                              .trackTextInput(
                            'user_id_field',
                            'SettingsScreen',
                            inputLength: value.length,
                          )
                              .catchError((e) {
                            print('Failed to track text input: $e');
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _updateUserId,
                      icon: const Icon(Icons.update),
                      label: const Text('Update User ID'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Data Management
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Management',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showCleanupStats,
                          icon: const Icon(Icons.info_outline),
                          label: const Text('View Stats'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _exportUnsyncedData,
                          icon: const Icon(Icons.download),
                          label: const Text('Export Data'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _deleteAllUserData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
