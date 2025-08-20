# IA Tracking Flutter SDK

A comprehensive Flutter plugin for user action tracking that provides seamless integration with native Android and iOS IA Tracking SDKs. Track user interactions, screen views, navigation, and custom events with high performance and privacy-focused design.

[![pub.dev](https://img.shields.io/pub/v/ia_tracking.svg)](https://pub.dev/packages/ia_tracking)
[![Platform Support](https://img.shields.io/badge/platform-android%20%7C%20ios-blue.svg)](https://pub.dev/packages/ia_tracking)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## Features

### 🎯 Comprehensive Tracking
- **Screen Views**: Automatic and manual screen view tracking
- **User Interactions**: Button taps, text input, dropdown selections
- **Navigation**: Route changes, tab switching, deep link navigation  
- **Search**: Query tracking with results count and performance metrics
- **Custom Events**: Flexible event tracking with properties and metadata

### 🛡️ Privacy-Focused
- **Safe Text Input**: Tracks input length only, never actual content
- **User Consent**: Easy enable/disable functionality for compliance
- **Data Control**: Complete user data deletion capabilities
- **GDPR Ready**: Export and deletion APIs for regulatory compliance

### ⚡ High Performance
- **Native Integration**: Leverages high-performance native SDKs
- **Efficient Storage**: SQLite-based local storage with compression
- **Smart Batching**: Configurable batch sizes for optimal network usage
- **Background Processing**: Non-blocking async operations

### 📊 Advanced Analytics
- **Session Management**: Automatic session handling with configurable timeouts
- **Data Retention**: Configurable retention policies and automatic cleanup
- **Sync Management**: Track synced vs unsynced data states
- **Statistics**: Comprehensive metrics and performance insights

## Getting Started

### Installation

Add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  ia_tracking: ^1.0.0
```

Run the installation command:

```bash
flutter pub get
```

### Android Setup

Add the native Android SDK dependency to your `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.iav3:ia-tracking-android:1.0.0'
}
```

### iOS Setup

Add the native iOS SDK to your `ios/Podfile`:

```ruby
pod 'IATracking', '~> 1.0.0'
```

## Basic Usage

### 1. Initialize the SDK

```dart
import 'package:ia_tracking/ia_tracking.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure the SDK
  const config = TrackingConfiguration(
    userId: 'user_12345',
    appVersion: '1.0.0',
    maxDatabaseSize: 50 * 1024 * 1024, // 50MB
    maxRetentionDays: 30,
    sessionTimeoutMinutes: 30,
    batchSize: 50,
    serverUrl: 'https://your-api.example.com/tracking',
    apiKey: 'your_api_key_here',
    debugMode: false, // Set to true for development
  );
  
  try {
    await IaTracker.instance.initialize(config);
    print('IA Tracking initialized successfully');
  } catch (e) {
    print('Failed to initialize IA Tracking: $e');
  }
  
  runApp(MyApp());
}
```

### 2. Track Screen Views

```dart
class MyScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    // Track screen view
    IaTracker.instance.trackScreenView('HomeScreen');
  }
}
```

### 3. Track Button Interactions

```dart
ElevatedButton(
  onPressed: () async {
    // Track button tap with optional coordinates
    await IaTracker.instance.trackButtonTap(
      'submit_button',
      'FormScreen',
      coordinates: Offset(100, 200), // Optional
    );
    
    // Your button action here
    handleSubmit();
  },
  child: Text('Submit'),
)
```

### 4. Track Text Input

```dart
TextField(
  onChanged: (value) {
    // Track input length (privacy-safe, no actual content)
    IaTracker.instance.trackTextInput(
      'email_field',
      'SignupScreen',
      inputLength: value.length,
    );
  },
  decoration: InputDecoration(labelText: 'Email'),
)
```

### 5. Track Custom Events

```dart
await IaTracker.instance.trackCustomEvent(
  'product_purchased',
  'CheckoutScreen',
  elementId: 'buy_now_button',
  properties: {
    'product_id': '12345',
    'product_name': 'Wireless Headphones',
    'price': 99.99,
    'category': 'electronics',
    'payment_method': 'credit_card',
  },
);
```

## Advanced Features

### Navigation Tracking

```dart
// Automatic navigation tracking with Navigator observer
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [
        TrackingNavigatorObserver(), // Automatic screen tracking
      ],
      // ... rest of your app
    );
  }
}

// Manual navigation tracking
await IaTracker.instance.trackNavigation(
  'HomeScreen',
  'ProductDetailsScreen',
  method: 'push',
);
```

### Search Tracking

```dart
Future<void> performSearch(String query) async {
  final results = await searchService.search(query);
  
  // Track search with results count
  await IaTracker.instance.trackSearch(
    query,
    'SearchScreen',
    resultsCount: results.length,
  );
}
```

### Session Management

```dart
// Start new session (useful after user login)
await IaTracker.instance.startNewSession();

// Update user ID
await IaTracker.instance.setUserId('new_user_id');

// Clear user ID (anonymous tracking)
await IaTracker.instance.setUserId(null);
```

### Enable/Disable Tracking

```dart
// Check if tracking is enabled
bool isEnabled = await IaTracker.instance.isEnabled();

// Enable/disable tracking (useful for user privacy settings)
await IaTracker.instance.setEnabled(false); // Disable
await IaTracker.instance.setEnabled(true);  // Enable
```

### Data Management

```dart
// Get tracking statistics
ActionStatistics stats = await IaTracker.instance.getActionStatistics();
print('Total actions: ${stats.totalActions}');
print('Unsynced actions: ${stats.unsyncedActions}');

// Export unsynced data for server synchronization
List<UserAction> unsyncedActions = await IaTracker.instance.getUnsyncedActions(
  limit: 100,
);

// Mark actions as synced after successful upload
List<String> actionIds = unsyncedActions.map((action) => action.id).toList();
await IaTracker.instance.markActionsAsSynced(actionIds);

// Get cleanup statistics
CleanupStats cleanupStats = await IaTracker.instance.getCleanupStats();
print('Database size: ${cleanupStats.estimatedSizeBytes} bytes');

// Perform manual cleanup
await IaTracker.instance.performCleanup();

// Delete all user data (GDPR compliance)
await IaTracker.instance.deleteAllUserData();

// Flush pending operations
await IaTracker.instance.flush();
```

## Configuration Options

### TrackingConfiguration

```dart
const config = TrackingConfiguration(
  // User identification
  userId: 'user_12345',                    // Optional: User identifier
  
  // App information  
  appVersion: '1.0.0',                     // Optional: App version
  
  // Storage settings
  maxDatabaseSize: 50 * 1024 * 1024,       // Default: 50MB
  maxRetentionDays: 30,                     // Default: 30 days
  
  // Session settings
  sessionTimeoutMinutes: 30,                // Default: 30 minutes
  
  // Network settings
  batchSize: 50,                           // Default: 50 actions per batch
  serverUrl: 'https://api.example.com',     // Optional: Your server URL
  apiKey: 'your_api_key',                  // Optional: API authentication
  
  // Development settings
  debugMode: false,                        // Default: false
);
```

## Data Models

### UserAction

All tracked actions are stored as `UserAction` objects with the following properties:

```dart
class UserAction {
  final String id;                    // Unique action identifier
  final ActionType actionType;        // Type of action (screen_view, button_tap, etc.)
  final String? screenName;           // Screen where action occurred
  final String? elementId;            // Element that triggered action
  final String? elementType;          // Type of element (button, text_field, etc.)
  final String? userId;               // User who performed action
  final String? sessionId;            // Session identifier
  final DateTime timestamp;           // When action occurred
  final Map<String, dynamic> properties;  // Custom properties
  final Map<String, dynamic> deviceInfo;  // Device information
  final String? appVersion;           // App version when action occurred
  final String? sdkVersion;           // SDK version
  final bool isSynced;               // Whether action has been synced
  final int retryCount;              // Number of sync retry attempts
}
```

### ActionType

Supported action types:

```dart
enum ActionType {
  screenView,      // Screen/page views
  buttonTap,       // Button and clickable element interactions
  textInput,       // Text field input (length only, privacy-safe)
  navigation,      // Navigation between screens
  search,          // Search queries
  customEvent,     // Custom application events
}
```

## Privacy & Compliance

### Data Collection Principles

1. **Minimal Data**: Only collect essential interaction data
2. **No Sensitive Content**: Text input tracking captures length only
3. **User Control**: Easy opt-out mechanisms
4. **Transparent**: Clear documentation of what data is collected
5. **Secure Storage**: Local SQLite database with appropriate permissions

### GDPR Compliance

```dart
// Data export for user requests
List<UserAction> allUserData = await IaTracker.instance.getUnsyncedActions(
  limit: -1, // Get all data
);

// Complete data deletion
await IaTracker.instance.deleteAllUserData();

// Check tracking status
bool isTracking = await IaTracker.instance.isEnabled();
```

### Privacy Settings UI

```dart
class PrivacySettingsScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SwitchListTile(
            title: Text('Analytics Tracking'),
            subtitle: Text('Help improve our app by sharing usage analytics'),
            value: _trackingEnabled,
            onChanged: (bool value) async {
              await IaTracker.instance.setEnabled(value);
              setState(() {
                _trackingEnabled = value;
              });
            },
          ),
          ElevatedButton(
            onPressed: () async {
              // Show confirmation dialog first
              await IaTracker.instance.deleteAllUserData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('All data deleted successfully')),
              );
            },
            child: Text('Delete My Data'),
          ),
        ],
      ),
    );
  }
}
```

## Error Handling

The SDK is designed to fail gracefully and never interfere with your app's functionality:

```dart
try {
  await IaTracker.instance.trackButtonTap('button_id', 'ScreenName');
} on InitializationException catch (e) {
  print('SDK not initialized: $e');
} on PlatformException catch (e) {
  print('Platform error: $e');
} on DatabaseException catch (e) {
  print('Database error: $e');
} catch (e) {
  print('Unexpected error: $e');
}
```

### Exception Types

- `InitializationException`: SDK not properly initialized
- `InvalidParameterException`: Invalid method parameters
- `PlatformException`: Platform-specific errors
- `DatabaseException`: Database operation errors  
- `SyncException`: Data synchronization errors

## Performance Considerations

### Best Practices

1. **Initialize Early**: Initialize the SDK in your `main()` function
2. **Batch Operations**: The SDK automatically batches operations for efficiency
3. **Background Processing**: All operations are performed on background threads
4. **Memory Efficient**: Minimal memory footprint with efficient data structures
5. **Network Aware**: Configurable batch sizes and retry logic

### Performance Tips

```dart
// Don't track every keystroke - use debouncing
Timer? _debounceTimer;

void onSearchChanged(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 500), () {
    IaTracker.instance.trackSearch(query, 'SearchScreen');
  });
}

// Use appropriate batch sizes for your app
const config = TrackingConfiguration(
  batchSize: 25, // Smaller batches for frequent syncing
  // OR
  batchSize: 100, // Larger batches for less frequent syncing
);

// Flush before app shutdown
@override
void dispose() {
  IaTracker.instance.flush();
  super.dispose();
}
```

## Testing

### Unit Testing

```dart
// Mock the tracker for unit tests
class MockIaTracker extends Mock implements IaTracker {}

void main() {
  group('Tracking Tests', () {
    late MockIaTracker mockTracker;
    
    setUp(() {
      mockTracker = MockIaTracker();
      IaTracker.instance = mockTracker;
    });
    
    testWidgets('should track button tap', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.tap(find.text('Submit'));
      
      verify(mockTracker.trackButtonTap('submit_button', 'TestScreen'))
          .called(1);
    });
  });
}
```

### Integration Testing

```dart
void main() {
  group('Integration Tests', () {
    testWidgets('should initialize and track actions', (tester) async {
      const config = TrackingConfiguration(
        userId: 'test_user',
        debugMode: true,
      );
      
      await IaTracker.instance.initialize(config);
      await IaTracker.instance.trackScreenView('TestScreen');
      
      final stats = await IaTracker.instance.getActionStatistics();
      expect(stats.totalActions, greaterThan(0));
    });
  });
}
```

## Migration Guide

### From Version 0.x to 1.x

The 1.0 release includes breaking changes for improved performance and API consistency:

```dart
// Old API (0.x)
IATracker.trackButtonClick('button', 'screen');

// New API (1.x) 
IaTracker.instance.trackButtonTap('button', 'screen');

// Old configuration
IATracker.init(userId: 'user123');

// New configuration
const config = TrackingConfiguration(userId: 'user123');
await IaTracker.instance.initialize(config);
```

## Troubleshooting

### Common Issues

#### SDK Not Initialized
```dart
// Error: InitializationException
// Solution: Ensure initialize() is called before any tracking operations
await IaTracker.instance.initialize(config);
```

#### Android Build Issues
```gradle
// Add to android/app/build.gradle
android {
    compileSdkVersion 34
    minSdkVersion 21  // Minimum required
}
```

#### iOS Build Issues
```ruby
# Add to ios/Podfile
platform :ios, '12.0'  # Minimum required

# Run after adding
cd ios && pod install
```

### Debug Mode

Enable debug mode for detailed logging:

```dart
const config = TrackingConfiguration(
  debugMode: true, // Enable detailed logging
);
```

### Logging

The SDK uses different log levels:

- **Error**: Critical errors that prevent functionality
- **Warning**: Potential issues that don't break functionality  
- **Info**: General operational information
- **Debug**: Detailed information for debugging (debug mode only)

## Example App

A complete example app is included in the `example/` directory demonstrating:

- SDK initialization and configuration
- All tracking methods with real-world usage
- Privacy settings and data management
- Error handling and edge cases
- Performance best practices

Run the example:

```bash
cd example
flutter pub get
flutter run
```

## API Reference

### IaTracker

The main class for all tracking operations.

#### Initialization

```dart
static IaTracker get instance // Singleton instance
Future<void> initialize(TrackingConfiguration config) // Initialize SDK
```

#### Tracking Methods

```dart
Future<void> trackScreenView(String screenName)
Future<void> trackButtonTap(String elementId, String screenName, {Offset? coordinates})
Future<void> trackTextInput(String elementId, String screenName, {int? inputLength})
Future<void> trackNavigation(String fromScreen, String toScreen, {String? method})
Future<void> trackSearch(String query, String screenName, {int? resultsCount})
Future<void> trackCustomEvent(String eventName, String screenName, {String? elementId, Map<String, dynamic>? properties})
```

#### Session Management

```dart
Future<void> startNewSession()
Future<void> setUserId(String? userId)
```

#### Control Methods

```dart
Future<void> setEnabled(bool enabled)
Future<bool> isEnabled()
```

#### Data Methods

```dart
Future<ActionStatistics> getActionStatistics()
Future<List<UserAction>> getUnsyncedActions({int limit = 50})
Future<void> markActionsAsSynced(List<String> actionIds)
Future<CleanupStats> getCleanupStats()
Future<void> performCleanup()
Future<void> deleteAllUserData()
Future<void> flush()
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
git clone https://github.com/your-repo/ia-tracking-flutter-sdk.git
cd ia-tracking-flutter-sdk
flutter pub get
cd example && flutter pub get
```

### Running Tests

```bash
flutter test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [Full API Documentation](https://docs.iav3.com/flutter-sdk)
- **Issues**: [GitHub Issues](https://github.com/your-repo/ia-tracking-flutter-sdk/issues)
- **Email**: flutter-support@iav3.com

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

---

**Made with ❤️ by the IAv3 Team**