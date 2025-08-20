/// Enumeration of different types of user actions that can be tracked
enum ActionType {
  /// User viewed a screen or page
  screenView,

  /// User tapped a button or interactive element
  buttonTap,

  /// User entered text into an input field
  textInput,

  /// User navigated between screens
  navigation,

  /// User performed a search query
  search,

  /// Custom event defined by the application
  custom,
}

/// Extension to provide string representations and parsing for ActionType
extension ActionTypeExtension on ActionType {
  /// Convert ActionType to string representation
  String get value {
    switch (this) {
      case ActionType.screenView:
        return 'screen_view';
      case ActionType.buttonTap:
        return 'button_tap';
      case ActionType.textInput:
        return 'text_input';
      case ActionType.navigation:
        return 'navigation';
      case ActionType.search:
        return 'search';
      case ActionType.custom:
        return 'custom';
    }
  }

  /// Create ActionType from string value
  static ActionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'screen_view':
        return ActionType.screenView;
      case 'button_tap':
        return ActionType.buttonTap;
      case 'text_input':
        return ActionType.textInput;
      case 'navigation':
        return ActionType.navigation;
      case 'search':
        return ActionType.search;
      case 'custom':
        return ActionType.custom;
      default:
        throw ArgumentError('Unknown ActionType: $value');
    }
  }
}
