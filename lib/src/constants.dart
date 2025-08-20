/// IA Tracking SDK Constants
/// 
/// This file contains all method channel constants and configuration values
/// used for communication between Flutter and native platforms.
class IaTrackingConstants {
  // API Endpoints - Internal SDK Configuration
  static const String apiBaseUrl = 'https://api.iatracking.com'; // Replace with your actual endpoint
  static const String trackingEndpoint = '$apiBaseUrl/v1/track';
  static const String revenueEndpoint = '$apiBaseUrl/v1/revenue';
  
  // Development/Testing endpoints (you can switch based on build config)
  static const String devApiBaseUrl = 'https://dev-api.iatracking.com';
  static const String stagingApiBaseUrl = 'https://staging-api.iatracking.com';
  // Core tracking methods
  static const String initialize = 'initialize';
  static const String trackScreenView = 'trackScreenView';
  static const String trackButtonTap = 'trackButtonTap';
  static const String trackTextInput = 'trackTextInput';
  static const String trackCustomEvent = 'trackCustomEvent';

  // Revenue tracking methods
  static const String trackRevenue = 'trackRevenue';
  static const String trackRevenueWithAttributes = 'trackRevenueWithAttributes';
  static const String trackInAppPurchase = 'trackInAppPurchase';

  // User identity methods
  static const String setUserId = 'setUserId';
  static const String unsetUserId = 'unsetUserId';
  static const String setDeviceId = 'setDeviceId';

  // Global properties methods
  static const String setGlobalProperty = 'setGlobalProperty';
  static const String unsetGlobalProperty = 'unsetGlobalProperty';
  static const String getGlobalProperties = 'getGlobalProperties';
  static const String clearGlobalProperties = 'clearGlobalProperties';

  // Privacy and compliance methods
  static const String setTrackingEnabled = 'setTrackingEnabled';
  static const String isTrackingEnabled = 'isTrackingEnabled';
  static const String setDataSharingEnabled = 'setDataSharingEnabled';
  static const String isDataSharingEnabled = 'isDataSharingEnabled';
  static const String trackingOptIn = 'trackingOptIn';
  static const String trackingOptOut = 'trackingOptOut';
  static const String stopAllTracking = 'stopAllTracking';
  static const String resumeAllTracking = 'resumeAllTracking';

  // Session and lifecycle methods
  static const String startSession = 'startSession';
  static const String endSession = 'endSession';
  static const String flush = 'flush';
  static const String setSessionTimeout = 'setSessionTimeout';

  // SKAdNetwork (iOS) methods
  static const String skanRegisterAppForAttribution = 'skanRegisterAppForAttribution';
  static const String skanUpdateConversionValue = 'skanUpdateConversionValue';
  static const String skanUpdateConversionValues = 'skanUpdateConversionValues';
  static const String skanGetConversionValue = 'skanGetConversionValue';

  // Push notifications and uninstall tracking
  static const String registerDeviceToken = 'registerDeviceToken';
  static const String setFCMToken = 'setFCMToken';
  static const String handlePushNotification = 'handlePushNotification';

  // Data management methods
  static const String getActionStatistics = 'getActionStatistics';
  static const String getUnsyncedActions = 'getUnsyncedActions';
  static const String markActionsAsSynced = 'markActionsAsSynced';
  static const String deleteAllUserData = 'deleteAllUserData';
  static const String getCleanupStats = 'getCleanupStats';
  static const String performCleanup = 'performCleanup';

  // SDK configuration and metadata
  static const String setSdkVersion = 'setSdkVersion';
  static const String getSdkVersion = 'getSdkVersion';
  static const String setWrapperInfo = 'setWrapperInfo';

  // Method channel name
  static const String channelName = 'ia_tracking';

  // Event property keys
  static const String isRevenueEvent = 'is_revenue_event';
  static const String revenueAmount = 'r';
  static const String revenueCurrency = 'pcc';
  static const String productSku = 'product_sku';
  static const String productName = 'product_name';
  static const String productCategory = 'product_category';
  static const String productQuantity = 'product_quantity';
  static const String productPrice = 'product_price';

  // Default values
  static const String defaultCurrency = 'USD';
  static const String sdkVersion = '1.0.0';
  static const String sdkName = 'Flutter';
}

/// Platform-specific constants
class IaTrackingPlatformConstants {
  // Android specific
  static const String androidMinSdk = '21';
  static const String androidTargetSdk = '34';
  
  // iOS specific
  static const String iosMinVersion = '12.0';
  
  // Common
  static const int defaultSessionTimeout = 30; // minutes
  static const int maxRetryAttempts = 3;
  static const int autoFlushInterval = 5000; // milliseconds
}