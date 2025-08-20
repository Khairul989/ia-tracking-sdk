import 'package:ia_tracking/ia_tracking.dart';

/// Simple usage example showing how to use IA Tracking SDK
/// after server URL is hardcoded internally
class SimpleUsageExample {
  
  /// Initialize the SDK - No server URL needed!
  /// Just like Singular SDK - clean and simple
  static Future<void> initializeSDK() async {
    try {
      // Basic initialization - only user ID needed
      await IaTracker.instance.initialize(TrackingConfiguration(
        userId: 'user123', // Optional
      ));
      
      print('✅ IA Tracking SDK initialized successfully!');
    } catch (e) {
      print('❌ Failed to initialize SDK: $e');
    }
  }
  
  /// Enhanced initialization with all features
  static Future<void> initializeEnhancedSDK() async {
    try {
      // Enhanced initialization - still no server URL!
      final config = IaTrackingConfig(
        userId: 'user123',
        apiKey: 'your-api-key', // Optional - only if your backend requires it
        privacy: IaPrivacySettings(
          trackingEnabled: true,
          gdprCompliant: true,
        ),
        enableLogging: true,
      );
      
      // Add global properties that will be attached to all events
      config.addGlobalProperty('app_version', '1.0.0');
      config.addGlobalProperty('user_tier', 'premium');
      
      await IaTracker.instance.initializeEnhanced(config);
      
      print('✅ Enhanced IA Tracking SDK initialized!');
    } catch (e) {
      print('❌ Failed to initialize enhanced SDK: $e');
    }
  }
  
  /// Track various events
  static Future<void> trackEvents() async {
    // Track screen views
    await IaTracker.instance.trackScreenView('home_screen');
    
    // Track user actions
    await IaTracker.instance.trackButtonTap('login_button', 'login_screen');
    
    // Track revenue (new feature!)
    await IaTracker.instance.trackRevenue(IaRevenue(
      eventName: 'purchase',
      amount: 9.99,
      currency: 'USD',
      properties: {
        'product_id': 'premium_subscription',
        'payment_method': 'credit_card',
      },
    ));
    
    // Track iOS In-App Purchase (automatically validates receipts)
    await IaTracker.instance.trackIOSInAppPurchase(IaIOSInAppPurchase(
      eventName: 'ios_iap',
      amount: 4.99,
      currency: 'USD',
      productId: 'com.yourapp.premium',
      transactionId: 'trans_123',
      receiptData: 'base64_receipt_data',
    ));
    
    print('✅ Events tracked successfully!');
  }
  
  /// Configure global properties (attached to all events automatically)
  static Future<void> setupGlobalProperties() async {
    // Set properties that will be added to every event
    await IaTracker.instance.setGlobalProperty('user_segment', 'power_user');
    await IaTracker.instance.setGlobalProperty('ab_test_variant', 'variant_a');
    
    // Get all global properties
    final properties = await IaTracker.instance.getGlobalProperties();
    print('Global properties: $properties');
  }
  
  /// Privacy controls for GDPR compliance
  static Future<void> handlePrivacy() async {
    // User opts out of tracking
    await IaTracker.instance.trackingOptOut();
    
    // Later, user opts back in
    await IaTracker.instance.trackingOptIn();
    
    // Check privacy status
    final isEnabled = await IaTracker.instance.isTrackingEnabled();
    print('Tracking enabled: $isEnabled');
  }
  
  /// iOS SKAdNetwork support (attribution tracking)
  static Future<void> setupAttribution() async {
    // Register for SKAdNetwork attribution (iOS only)
    await IaTracker.instance.skanRegisterAppForAttribution();
    
    // Update conversion value based on user actions
    await IaTracker.instance.skanUpdateConversionValue(10); // 0-63
    
    print('✅ Attribution tracking configured!');
  }
}

/// Usage in your app
void main() async {
  // Initialize the SDK first
  await SimpleUsageExample.initializeEnhancedSDK();
  
  // Setup global properties
  await SimpleUsageExample.setupGlobalProperties();
  
  // Configure attribution (iOS)
  await SimpleUsageExample.setupAttribution();
  
  // Start tracking events
  await SimpleUsageExample.trackEvents();
  
  // Handle privacy compliance
  await SimpleUsageExample.handlePrivacy();
}