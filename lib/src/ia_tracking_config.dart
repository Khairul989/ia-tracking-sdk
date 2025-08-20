import 'dart:io' show Platform;

/// Global property configuration
class IaGlobalProperty {
  final String key;
  final String value;
  final bool overrideExisting;

  IaGlobalProperty(this.key, this.value, {this.overrideExisting = true});

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'overrideExisting': overrideExisting,
    };
  }
}

/// Privacy compliance settings
class IaPrivacySettings {
  bool trackingEnabled;
  bool dataSharingEnabled;
  bool limitDataSharing;
  bool coppaCompliant;
  bool gdprCompliant;

  IaPrivacySettings({
    this.trackingEnabled = true,
    this.dataSharingEnabled = true,
    this.limitDataSharing = false,
    this.coppaCompliant = false,
    this.gdprCompliant = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'trackingEnabled': trackingEnabled,
      'dataSharingEnabled': dataSharingEnabled,
      'limitDataSharing': limitDataSharing,
      'coppaCompliant': coppaCompliant,
      'gdprCompliant': gdprCompliant,
    };
  }
}

/// SKAdNetwork configuration (iOS only)
class IaSkanSettings {
  bool enabled;
  bool manualConversionManagement;
  int waitForTrackingAuthorizationTimeout;

  IaSkanSettings({
    this.enabled = true,
    this.manualConversionManagement = false,
    this.waitForTrackingAuthorizationTimeout = 60,
  });

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'manualConversionManagement': manualConversionManagement,
      'waitForTrackingAuthorizationTimeout': waitForTrackingAuthorizationTimeout,
    };
  }
}

/// Callback function types
typedef ConversionValueCallback = void Function(int conversionValue);
typedef ConversionValuesCallback = void Function(int conversionValue, int coarse, bool lock);
typedef AttributionCallback = void Function(Map<String, dynamic> attribution);

/// Main configuration class for IA Tracking SDK
class IaTrackingConfig {
  // Optional API key for authentication (if your backend requires it)
  final String? apiKey;

  // Optional user identification
  String? userId;
  String? deviceId;

  // Privacy settings
  IaPrivacySettings privacy;

  // SKAdNetwork settings (iOS)
  IaSkanSettings skanSettings;

  // Session configuration
  int sessionTimeoutMinutes;
  bool enableAutoFlush;
  int autoFlushIntervalMs;

  // Global properties
  final List<IaGlobalProperty> _globalProperties = [];

  // Debug and logging
  bool enableLogging;
  bool enableDebugMode;

  // Callbacks
  ConversionValueCallback? conversionValueCallback;
  ConversionValuesCallback? conversionValuesCallback;
  AttributionCallback? attributionCallback;

  // Platform-specific settings
  Map<String, dynamic> platformSettings;

  IaTrackingConfig({
    this.apiKey,
    this.userId,
    this.deviceId,
    IaPrivacySettings? privacy,
    IaSkanSettings? skanSettings,
    this.sessionTimeoutMinutes = 30,
    this.enableAutoFlush = true,
    this.autoFlushIntervalMs = 5000,
    this.enableLogging = false,
    this.enableDebugMode = false,
    this.platformSettings = const {},
  }) : privacy = privacy ?? IaPrivacySettings(),
       skanSettings = skanSettings ?? IaSkanSettings();

  /// Add a global property that will be attached to all events
  void addGlobalProperty(String key, String value, {bool overrideExisting = true}) {
    // Remove existing property with same key if overrideExisting is true
    if (overrideExisting) {
      _globalProperties.removeWhere((prop) => prop.key == key);
    }
    _globalProperties.add(IaGlobalProperty(key, value, overrideExisting: overrideExisting));
  }

  /// Remove a global property
  void removeGlobalProperty(String key) {
    _globalProperties.removeWhere((prop) => prop.key == key);
  }

  /// Clear all global properties
  void clearGlobalProperties() {
    _globalProperties.clear();
  }

  /// Get read-only list of global properties
  List<IaGlobalProperty> get globalProperties => List.unmodifiable(_globalProperties);

  /// Set conversion value callback (iOS SKAdNetwork)
  void setConversionValueCallback(ConversionValueCallback callback) {
    conversionValueCallback = callback;
  }

  /// Set conversion values callback (iOS SKAdNetwork 4.0)
  void setConversionValuesCallback(ConversionValuesCallback callback) {
    conversionValuesCallback = callback;
  }

  /// Set attribution callback
  void setAttributionCallback(AttributionCallback callback) {
    attributionCallback = callback;
  }

  /// Convert configuration to map for method channel
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> config = {
      'apiKey': apiKey,
      'userId': userId,
      'deviceId': deviceId,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
      'enableAutoFlush': enableAutoFlush,
      'autoFlushIntervalMs': autoFlushIntervalMs,
      'enableLogging': enableLogging,
      'enableDebugMode': enableDebugMode,
      'privacy': privacy.toMap(),
      'globalProperties': _globalProperties.map((prop) => prop.toMap()).toList(),
      'platformSettings': platformSettings,
    };

    // Add iOS-specific settings
    if (Platform.isIOS) {
      config['skanSettings'] = skanSettings.toMap();
    }

    // Add callback flags
    config['hasConversionValueCallback'] = conversionValueCallback != null;
    config['hasConversionValuesCallback'] = conversionValuesCallback != null;
    config['hasAttributionCallback'] = attributionCallback != null;

    return config;
  }

  /// Create a copy of this configuration with optional modifications
  IaTrackingConfig copyWith({
    String? apiKey,
    String? userId,
    String? deviceId,
    IaPrivacySettings? privacy,
    IaSkanSettings? skanSettings,
    int? sessionTimeoutMinutes,
    bool? enableAutoFlush,
    int? autoFlushIntervalMs,
    bool? enableLogging,
    bool? enableDebugMode,
    Map<String, dynamic>? platformSettings,
  }) {
    final newConfig = IaTrackingConfig(
      apiKey: apiKey ?? this.apiKey,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      privacy: privacy ?? this.privacy,
      skanSettings: skanSettings ?? this.skanSettings,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      enableAutoFlush: enableAutoFlush ?? this.enableAutoFlush,
      autoFlushIntervalMs: autoFlushIntervalMs ?? this.autoFlushIntervalMs,
      enableLogging: enableLogging ?? this.enableLogging,
      enableDebugMode: enableDebugMode ?? this.enableDebugMode,
      platformSettings: platformSettings ?? this.platformSettings,
    );

    // Copy global properties
    for (final prop in _globalProperties) {
      newConfig._globalProperties.add(prop);
    }

    // Copy callbacks
    newConfig.conversionValueCallback = conversionValueCallback;
    newConfig.conversionValuesCallback = conversionValuesCallback;
    newConfig.attributionCallback = attributionCallback;

    return newConfig;
  }

  /// Validate the configuration
  List<String> validate() {
    final errors = <String>[];

    // Note: Server URL is now hardcoded in the SDK, no validation needed

    // Validate session timeout
    if (sessionTimeoutMinutes <= 0) {
      errors.add('sessionTimeoutMinutes must be greater than 0');
    }

    // Validate auto-flush interval
    if (autoFlushIntervalMs <= 0) {
      errors.add('autoFlushIntervalMs must be greater than 0');
    }

    // Validate SKAdNetwork settings on iOS
    if (Platform.isIOS && skanSettings.enabled) {
      if (skanSettings.waitForTrackingAuthorizationTimeout < 0) {
        errors.add('waitForTrackingAuthorizationTimeout must be >= 0');
      }
    }

    return errors;
  }
}