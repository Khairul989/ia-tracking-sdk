# IA Tracking Flutter SDK Example

This example app demonstrates how to use the IA Tracking Flutter SDK to track user actions across your Flutter application.

## Features Demonstrated

### 1. Basic Setup & Initialization
- SDK initialization with configuration
- Status monitoring and error handling
- Enable/disable tracking functionality

### 2. Button Interaction Tracking
- Different button types (Elevated, Outlined, Text, Icon, FAB)
- Coordinate tracking for touch positions
- Custom properties attached to button events

### 3. Form Input Tracking
- Text field input length tracking (privacy-safe)
- Dropdown selection tracking
- Form validation and submission events
- Real-time input monitoring

### 4. Search Functionality
- Search query tracking with results count
- Debounced search input
- Search result selection tracking
- Query performance metrics

### 5. Navigation Tracking
- Automatic screen view tracking
- Manual navigation event tracking
- Tab change monitoring
- Route transition tracking

### 6. Data Management
- Action statistics and metrics
- Unsynced data export capabilities
- Data cleanup and retention management
- User data deletion for privacy compliance

## Getting Started

1. **Install Dependencies**
   ```bash
   cd example
   flutter pub get
   ```

2. **Run the Example**
   ```bash
   flutter run
   ```

3. **Explore Features**
   - Use the main screen to test basic tracking
   - Navigate to Settings for advanced configuration
   - Try the Demo screens for comprehensive examples

## Code Structure

```
lib/
├── main.dart                 # App initialization and main screen
├── screens/
│   ├── settings_screen.dart  # Configuration and data management
│   └── demo_screen.dart      # Comprehensive tracking examples
```

## Key Implementation Details

### SDK Initialization

```dart
final config = TrackingConfiguration(
  userId: 'demo_user_001',
  appVersion: '1.0.0',
  maxDatabaseSize: 50 * 1024 * 1024, // 50MB
  maxRetentionDays: 30,
  sessionTimeoutMinutes: 30,
  batchSize: 50,
  serverUrl: 'https://api.example.com/tracking',
  apiKey: 'demo_api_key_12345',
  debugMode: true,
);

await IaTracker.instance.initialize(config);
```

### Automatic Screen Tracking

```dart
class _TrackingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = route.settings.name ?? route.runtimeType.toString();
    IaTracker.instance.trackScreenView(routeName);
  }
}
```

### Button Interaction Tracking

```dart
ElevatedButton(
  onPressed: () async {
    await IaTracker.instance.trackButtonTap(
      'submit_button',
      'FormScreen',
      coordinates: Offset(200, 400), // Optional
    );
    
    // Additional custom event
    await IaTracker.instance.trackCustomEvent(
      'form_submitted',
      'FormScreen',
      elementId: 'contact_form',
      properties: {
        'form_valid': true,
        'completion_time': 45.2,
      },
    );
  },
  child: Text('Submit'),
)
```

### Text Input Tracking

```dart
TextField(
  onChanged: (value) {
    IaTracker.instance.trackTextInput(
      'email_field',
      'SignupScreen',
      inputLength: value.length, // Privacy-safe length only
    );
  },
)
```

### Search Tracking

```dart
Future<void> _performSearch(String query) async {
  // Perform search logic
  final results = await searchService.search(query);
  
  // Track search with results
  await IaTracker.instance.trackSearch(
    query,
    'SearchScreen',
    resultsCount: results.length,
  );
}
```

## Privacy & Compliance

The SDK is designed with privacy in mind:

- **Text Input**: Only tracks input length, never actual content
- **User Data**: Provides complete data deletion capabilities
- **Opt-out**: Users can disable tracking entirely
- **GDPR Compliant**: Includes data export and deletion functions

## Customization

### Custom Events

```dart
await IaTracker.instance.trackCustomEvent(
  'product_viewed',
  'ProductScreen',
  elementId: 'product_123',
  properties: {
    'product_id': '123',
    'category': 'electronics',
    'price': 99.99,
    'view_duration': 23.5,
  },
);
```

### Error Handling

```dart
try {
  await IaTracker.instance.trackButtonTap('button_id', 'ScreenName');
} catch (e) {
  // Handle tracking errors gracefully
  print('Tracking failed: $e');
  // App continues to function normally
}
```

## Production Considerations

1. **API Configuration**: Update `serverUrl` and `apiKey` for your production environment
2. **Debug Mode**: Disable `debugMode` in production builds
3. **Data Retention**: Configure appropriate `maxRetentionDays` for your use case
4. **Database Size**: Set `maxDatabaseSize` based on device storage constraints
5. **User Consent**: Implement proper consent mechanisms before enabling tracking

## Need Help?

- Check the [Flutter SDK Documentation](../README.md)
- Review the [Native Android SDK](../../android-sdk/)
- Review the [Native iOS SDK](../../ios-sdk/)
- Contact support for additional assistance