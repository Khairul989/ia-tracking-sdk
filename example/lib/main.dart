import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ia_tracking/ia_tracking.dart';
import 'package:ia_tracking_example/screens/demo_screen.dart';
import 'package:ia_tracking_example/screens/detailed_statistics_screen.dart';
import 'package:ia_tracking_example/screens/device_info_screen.dart';
import 'package:ia_tracking_example/screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IA Tracking Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'IA Tracking Demo'),
      navigatorObservers: [
        // Custom navigator observer for automatic screen tracking
        _TrackingNavigatorObserver(),
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _isTrackingEnabled = true;
  String _statusMessage = 'Initializing...';
  bool _isInitialized = false;

  // ATT (App Tracking Transparency) state
  String _attStatus = 'unknown';
  String? _idfa;

  @override
  void initState() {
    super.initState();

    // Initialize SDK asynchronously but don't block UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSDK();
    });

    // Fallback: If initialization takes too long, show app anyway
    Timer(const Duration(seconds: 5), () {
      if (mounted && !_isInitialized) {
        debugPrint('⏰ Fallback: Showing app without SDK initialization');
        setState(() {
          _statusMessage = 'SDK initialization delayed - app ready';
        });
      }
    });
  }

  Future<void> _initializeSDK() async {
    debugPrint('🚀 Starting SDK initialization...');

    try {
      _updateStatus('Initializing IA Tracking SDK...');

      const config = TrackingConfiguration(
        userId: 'demo_user_001',
        appVersion: '1.0.0',
        maxDatabaseSize: 50 * 1024 * 1024, // 50MB
        maxRetentionDays: 30,
        sessionTimeoutMinutes: 30,
        batchSize: 50,
        appId: 'com.ia.app',
        serverUrl: 'https://enormous-right-mule.ngrok-free.app/v1/track',
        apiKey: 'demo-api-key-12345',
        debugMode: true,
      );

      debugPrint(
          '📋 Configuration created with server URL: ${config.serverUrl}');
      debugPrint('📋 API Key: ${config.apiKey}');
      debugPrint('📋 Calling initialize...');

      // Add timeout to prevent hanging on splash screen
      // Use a longer timeout for IDE debugging scenarios
      const timeout = bool.fromEnvironment('dart.vm.product')
          ? Duration(seconds: 10) // Release mode
          : Duration(seconds: 30); // Debug mode (IDE)

      await IaTracker.instance.initialize(config).timeout(timeout);

      debugPrint('✅ SDK initialization completed successfully');
      debugPrint('✅ Server URL configured: ${config.serverUrl}');

      setState(() {
        _isInitialized = true;
      });

      _updateStatus('SDK initialized successfully');

      // Now do the initial tracking calls with error handling
      try {
        await _trackScreenView();
        await _checkTrackingStatus();
        await _checkATTStatus(); // Check ATT status after initialization
        debugPrint('📱 Initial tracking calls completed');
      } catch (trackingError) {
        debugPrint('⚠️ Initial tracking calls failed: $trackingError');
        // Don't fail the entire initialization for tracking errors
      }
    } catch (e) {
      debugPrint('❌ SDK initialization failed: $e');

      setState(() {
        _isInitialized = false;
      });
      _updateStatus('Failed to initialize SDK: $e');
      // Continue with app even if SDK initialization fails
    }
  }

  Future<void> _trackScreenView() async {
    if (!_isInitialized) return;

    try {
      await IaTracker.instance.trackScreenView('HomeScreen');
    } catch (e) {
      _updateStatus('Failed to track screen view: $e');
    }
  }

  Future<void> _checkTrackingStatus() async {
    if (!_isInitialized) return;

    try {
      final isEnabled = await IaTracker.instance.isEnabled();
      setState(() {
        _isTrackingEnabled = isEnabled;
      });
    } catch (e) {
      _updateStatus('Failed to check tracking status: $e');
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    _trackButtonTap();
  }

  Future<void> _trackButtonTap() async {
    if (!_isInitialized) {
      debugPrint('⚠️ SDK not initialized, skipping button tap tracking');
      return;
    }

    try {
      debugPrint('🔄 Tracking button tap...');
      await IaTracker.instance.trackButtonTap(
        'increment_button',
        'HomeScreen',
        coordinates: const Offset(200, 400), // Example coordinates
      );
      debugPrint('✅ Button tap tracked successfully');
      _updateStatus('Button tap tracked successfully');
    } catch (e) {
      debugPrint('❌ Failed to track button tap: $e');
      _updateStatus('Failed to track button tap: $e');
    }
  }

  Future<void> _toggleTracking() async {
    try {
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

  Future<void> _trackCustomEvent() async {
    try {
      await IaTracker.instance.trackCustomEvent(
        'counter_milestone',
        'HomeScreen',
        elementId: 'counter_display',
        properties: {
          'counter_value': _counter,
          'milestone': _counter % 5 == 0 ? 'multiple_of_5' : 'regular',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      _updateStatus('Custom event tracked');
    } catch (e) {
      _updateStatus('Failed to track custom event: $e');
    }
  }

  Future<void> _showStatistics() async {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DetailedStatisticsScreen(),
        ),
      );
      _updateStatus('Statistics screen opened');
    } catch (e) {
      _updateStatus('Failed to open statistics: $e');
    }
  }

  Future<void> _flushData() async {
    try {
      debugPrint('🔄 Manually flushing data...');
      await IaTracker.instance.flush();
      debugPrint('✅ Data flushed successfully');
      _updateStatus('Data flushed successfully');

      // Also get statistics to see what was flushed
      try {
        final stats = await IaTracker.instance.getActionStatistics();
        debugPrint('📊 Statistics after flush: $stats');
      } catch (statsError) {
        debugPrint('⚠️ Could not get stats after flush: $statsError');
      }
    } catch (e) {
      debugPrint('❌ Failed to flush data: $e');
      _updateStatus('Failed to flush data: $e');
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
          _statusMessage = 'Ready to track';
        });
      }
    });
  }

  // ATT (App Tracking Transparency) methods
  Future<void> _checkATTStatus() async {
    if (!_isInitialized) return;

    try {
      final status = await IaTracker.instance.getTrackingAuthorizationStatus();
      final idfa = await IaTracker.instance.getIDFA();

      setState(() {
        _attStatus = status;
        _idfa = idfa;
      });

      debugPrint('📱 ATT Status: $status, IDFA: ${idfa ?? 'null'}');
    } catch (e) {
      debugPrint('❌ Failed to check ATT status: $e');
      _updateStatus('Failed to check ATT status: $e');
    }
  }

  Future<void> _requestATTPermission() async {
    if (!_isInitialized) {
      _updateStatus('SDK not initialized');
      return;
    }

    try {
      debugPrint('🔐 Requesting ATT permission...');
      _updateStatus('Requesting tracking permission...');

      await IaTracker.instance.requestTrackingPermission();

      // Check status after permission request
      await _checkATTStatus();

      final authorized = await IaTracker.instance.isTrackingAuthorized();
      if (authorized) {
        _updateStatus('Tracking permission granted');
        debugPrint('✅ Tracking permission granted');
      } else {
        _updateStatus('Tracking permission denied');
        debugPrint('❌ Tracking permission denied');
      }
    } catch (e) {
      debugPrint('❌ Failed to request ATT permission: $e');
      _updateStatus('Failed to request tracking permission: $e');
    }
  }

  Future<void> _showATTInfo() async {
    await _checkATTStatus();

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('App Tracking Transparency'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $_attStatus'),
                const SizedBox(height: 8),
                Text('IDFA: ${_idfa ?? 'Not available'}'),
                const SizedBox(height: 16),
                const Text(
                  'This information is automatically included in tracking events when available.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // Helper methods for ATT status display
  IconData _getATTStatusIcon() {
    switch (_attStatus) {
      case 'authorized':
        return Icons.verified_user;
      case 'denied':
        return Icons.block;
      case 'restricted':
        return Icons.warning;
      case 'notDetermined':
        return Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getATTStatusColor() {
    switch (_attStatus) {
      case 'authorized':
        return Colors.green;
      case 'denied':
        return Colors.red;
      case 'restricted':
        return Colors.orange;
      case 'notDetermined':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getATTDisplayStatus() {
    switch (_attStatus) {
      case 'authorized':
        return 'Authorized';
      case 'denied':
        return 'Denied';
      case 'restricted':
        return 'Restricted';
      case 'notDetermined':
        return 'Not Asked';
      default:
        return 'Unknown';
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _navigateToDemo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DemoScreen(),
      ),
    );
  }

  void _showDeviceInfo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'DeviceInfoScreen'),
        builder: (context) => const DeviceInfoScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _navigateToSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Tracking Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isTrackingEnabled
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color:
                                _isTrackingEnabled ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(_isTrackingEnabled ? 'Enabled' : 'Disabled'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // ATT Status Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getATTStatusIcon(),
                            color: _getATTStatusColor(),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ATT: ${_getATTDisplayStatus()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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
              const SizedBox(height: 32),
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _toggleTracking,
                    icon: Icon(
                        _isTrackingEnabled ? Icons.pause : Icons.play_arrow),
                    label: Text(_isTrackingEnabled ? 'Disable' : 'Enable'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showStatistics,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Statistics'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _trackCustomEvent,
                    icon: const Icon(Icons.event),
                    label: const Text('Custom Event'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _flushData,
                    icon: const Icon(Icons.save),
                    label: const Text('Flush Data'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showDeviceInfo,
                    icon: const Icon(Icons.phone_android),
                    label: const Text('Device Info'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _requestATTPermission,
                    icon: const Icon(Icons.security),
                    label: const Text('Request ATT'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showATTInfo,
                    icon: const Icon(Icons.info),
                    label: const Text('ATT Status'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _navigateToDemo,
                child: const Text('View More Examples'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Custom navigator observer for automatic screen tracking
class _TrackingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackRouteChange(route, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _trackRouteChange(previousRoute, 'pop');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackRouteChange(newRoute, 'replace');
    }
  }

  void _trackRouteChange(Route<dynamic> route, String method) {
    final routeName = route.settings.name ?? route.runtimeType.toString();

    // Track screen view
    IaTracker.instance.trackScreenView(routeName).catchError((e) {
      debugPrint('Failed to track screen view for $routeName: $e');
    });

    // Track navigation if we have previous route info
    if (method == 'push' && route.settings.arguments != null) {
      final args = route.settings.arguments as Map<String, dynamic>?;
      final fromScreen = args?['fromScreen'] as String?;

      if (fromScreen != null) {
        IaTracker.instance
            .trackNavigation(
          fromScreen,
          routeName,
          method: method,
        )
            .catchError((e) {
          debugPrint('Failed to track navigation: $e');
        });
      }
    }
  }
}
