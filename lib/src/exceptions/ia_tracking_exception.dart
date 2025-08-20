/// Base exception for IA Tracking SDK errors
class IaTrackingException implements Exception {
  /// Create an IA Tracking exception
  const IaTrackingException(
    this.message, {
    this.code,
    this.details,
  });

  /// Error message
  final String message;

  /// Error code for programmatic handling
  final String? code;

  /// Additional error details
  final Map<String, dynamic>? details;

  @override
  String toString() {
    if (code != null) {
      return 'IaTrackingException [$code]: $message';
    }
    return 'IaTrackingException: $message';
  }
}

/// Exception thrown when SDK is not properly initialized
class InitializationException extends IaTrackingException {
  const InitializationException(super.message)
      : super(code: 'INITIALIZATION_ERROR');
}

/// Exception thrown when invalid parameters are provided
class InvalidParameterException extends IaTrackingException {
  const InvalidParameterException(super.message)
      : super(code: 'INVALID_PARAMETER');
}

/// Exception thrown when platform communication fails
class PlatformException extends IaTrackingException {
  const PlatformException(super.message, {super.details})
      : super(code: 'PLATFORM_ERROR');
}

/// Exception thrown when database operations fail
class DatabaseException extends IaTrackingException {
  const DatabaseException(super.message, {super.details})
      : super(code: 'DATABASE_ERROR');
}

/// Exception thrown when network operations fail
class NetworkException extends IaTrackingException {
  const NetworkException(super.message, {super.details})
      : super(code: 'NETWORK_ERROR');
}

/// Exception thrown when sync operations fail
class SyncException extends IaTrackingException {
  const SyncException(super.message, {super.details})
      : super(code: 'SYNC_ERROR');
}
