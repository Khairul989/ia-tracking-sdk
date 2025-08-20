# Changelog

All notable changes to the IA Tracking Flutter SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-08-20

### Added
- **API Integration Update**: Complete integration with backend API documentation
- **CloudFlare Tunnel Support**: Native support for CloudFlare tunnel URLs
- **Enhanced UUID Generation**: Proper v4 UUID format for all event and batch IDs
- **Structured API Payload**: New payload format with `events`, `batchInfo`, `deviceInfo`, and `sessionInfo`
- **Environment Variable Support**: API URL configuration via `IA_TRACKING_API_URL` environment variable
- **Base64 URL Encoding**: Support for base64-encoded API URLs for additional security

### Changed
- **API Endpoint Structure**: Updated to use `/v1/track` endpoint format
- **HTTP Headers**: Updated to match API documentation (`Content-Type`, `User-Agent`, `X-API-Key`)
- **Event Type Mapping**: Improved event type categorization with `action_subtype` properties
- **Device Information**: Enhanced device info collection including timezone, carrier, and connection type
- **Error Handling**: Improved error responses and debugging information
- **UUID Format**: Fixed UUID generation to use proper v4 format instead of custom format

### Fixed
- **API Validation**: Events now pass server-side UUID validation
- **Batch Processing**: Proper batch ID generation and tracking
- **URL Validation**: Enhanced URL validation to support development and production environments
- **Session Management**: Improved session ID generation and tracking

### Technical Improvements
- **Android Implementation**: Updated native Android plugin to match API specifications
- **iOS Implementation**: Updated native iOS plugin with new payload structure
- **Response Handling**: Enhanced API response parsing and error logging
- **Security**: Improved URL handling and validation for production use

### Breaking Changes
- **API Payload Format**: The internal API payload format has changed to match backend specifications
- **UUID Format**: Event IDs now use standard v4 UUID format (affects internal storage only)

**Note**: These changes are primarily internal and maintain backward compatibility for the public Flutter API.

## [1.0.0] - 2024-12-20

### Added
- Initial release of IA Tracking Flutter SDK
- Comprehensive cross-platform user action tracking
- Integration with native Android and iOS SDKs
- Complete Flutter plugin architecture with method channels

#### Core Features
- **Screen View Tracking**: Automatic and manual screen view tracking
- **User Interaction Tracking**: Button taps, text input, form interactions
- **Navigation Tracking**: Route changes, tab switching, deep links
- **Search Tracking**: Query tracking with results count and performance metrics
- **Custom Event Tracking**: Flexible event system with properties and metadata

#### Data Models
- `UserAction`: Comprehensive action data model with serialization
- `ActionType`: Enumerated action types for type safety
- `TrackingConfiguration`: Builder-pattern configuration with validation
- `ActionStatistics`: Statistics and metrics data model
- `CleanupStats`: Data retention and cleanup statistics

#### Platform Integration
- **Android Plugin**: Kotlin implementation with coroutines for async operations
- **iOS Plugin**: Swift implementation with Grand Central Dispatch
- **Method Channel Communication**: Reliable Flutter-native communication
- **Error Handling**: Comprehensive exception handling and error propagation

#### Privacy & Compliance
- **Privacy-Safe Text Tracking**: Input length only, never actual content
- **User Consent Management**: Easy enable/disable functionality
- **Data Export**: GDPR-compliant data export capabilities
- **Data Deletion**: Complete user data deletion for privacy compliance
- **Session Management**: Configurable session handling and user ID management

#### Performance Features
- **Background Processing**: Non-blocking async operations
- **Smart Batching**: Configurable batch sizes for optimal performance
- **Local Storage**: Efficient SQLite-based storage with retention policies
- **Memory Optimization**: Minimal memory footprint with efficient data structures

#### Developer Experience
- **Comprehensive Documentation**: Full API documentation with examples
- **Example App**: Complete demonstration app with all features
- **Type Safety**: Full TypeScript-style type safety with Dart
- **Error Handling**: Graceful failure handling that never breaks app functionality

#### Configuration Options
- Database size limits and retention policies
- Session timeout configuration
- Batch size optimization
- Debug mode for development
- Server URL and API key configuration
- User identification and app version tracking

#### API Highlights
- `IaTracker.instance.initialize()`: SDK initialization with configuration
- `trackScreenView()`: Screen view tracking
- `trackButtonTap()`: Button and element interaction tracking
- `trackTextInput()`: Privacy-safe text input tracking
- `trackNavigation()`: Navigation event tracking
- `trackSearch()`: Search query and results tracking
- `trackCustomEvent()`: Flexible custom event tracking
- `getActionStatistics()`: Comprehensive statistics
- `getUnsyncedActions()`: Data export functionality
- `deleteAllUserData()`: Privacy compliance data deletion

### Dependencies
- Flutter SDK 3.0.0 or higher
- Android: compileSdkVersion 34, minSdkVersion 21
- iOS: iOS 12.0 or higher
- Native Android SDK: ia-tracking-android 1.0.0
- Native iOS SDK: IATracking 1.0.0

### Known Issues
- None at this time

### Breaking Changes
- None (initial release)

---

## Development Roadmap

### Planned Features

#### Version 1.1.0
- [ ] Real-time analytics dashboard integration
- [ ] Enhanced offline mode with intelligent sync
- [ ] Advanced funnel and conversion tracking
- [ ] A/B testing integration capabilities
- [ ] Performance monitoring and crash tracking

#### Version 1.2.0
- [ ] Machine learning insights integration
- [ ] Advanced user behavior analytics
- [ ] Predictive analytics capabilities
- [ ] Enhanced privacy controls and consent management
- [ ] Multi-tenant and enterprise features

#### Version 2.0.0
- [ ] Flutter 4.0 compatibility
- [ ] Enhanced cross-platform performance
- [ ] Advanced data visualization tools
- [ ] Real-time collaborative analytics
- [ ] Expanded platform support (Web, Desktop)

---

**For the latest updates and detailed release information, visit our [GitHub Releases](https://github.com/your-repo/ia-tracking-flutter-sdk/releases) page.**