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
        serverUrl: 'https://sorted-berlin-pf-onto.trycloudflare.com/v1/track',
        apiKey: 'demo-api-key-12345',
        debugMode: true,
      );

      debugPrint('📋 Configuration created with server URL: ${config.serverUrl}');
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
