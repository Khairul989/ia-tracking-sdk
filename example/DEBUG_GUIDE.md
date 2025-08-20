# Debug Guide: IDE vs Terminal Differences

## Issue Description
The app works fine when run via terminal (`flutter run`) but gets stuck at splash screen when run via IDE debugger (Fn+F5).

## Root Cause
The debugger can interfere with async operations, especially:
1. **Slower execution** - Debug mode has additional overhead
2. **Breakpoint interference** - Even implicit breakpoints can affect timing
3. **Different environment variables** - IDE vs terminal environments differ
4. **Timeout sensitivity** - SDK initialization may take longer under debugger

## Solutions Implemented

### 1. Adaptive Timeouts
```dart
// Use longer timeout for debug mode (IDE)
const timeout = bool.fromEnvironment('dart.vm.product')
    ? Duration(seconds: 10)  // Release mode
    : Duration(seconds: 30); // Debug mode (IDE)
```

### 2. Non-blocking Initialization
```dart
// Initialize SDK after UI is ready
WidgetsBinding.instance.addPostFrameCallback((_) {
  _initializeSDK();
});
```

### 3. Fallback Mechanism
```dart
// Show app even if SDK initialization is slow
Timer(const Duration(seconds: 5), () {
  if (mounted && !_isInitialized) {
    setState(() {
      _statusMessage = 'SDK initialization delayed - app ready';
    });
  }
});
```

### 4. Enhanced Logging
Added debug prints to track initialization progress:
- 🚀 Starting SDK initialization
- 📋 Configuration created  
- ✅ SDK initialization completed
- ❌ SDK initialization failed
- ⏰ Fallback timer activated

## Usage Recommendations

### For Development (IDE)
- Use the provided VS Code launch configurations
- Check Debug Console for initialization logs
- If still stuck, use "Flutter (Profile)" mode instead of debug

### For Testing (Terminal)
- Use `flutter run` for fastest startup
- Use `flutter run --release` for production testing
- Use `flutter run --profile` for performance testing

### Debugging Steps
1. **Check Debug Console** - Look for the emoji debug messages
2. **Try Profile Mode** - Less debugging overhead than debug mode  
3. **Use Terminal** - Fastest way to test functionality
4. **Check Timeout** - Increase timeout if needed for slower devices

## Configuration Files
- `.vscode/launch.json` - VS Code debug configurations
- `lib/main.dart` - Contains adaptive initialization logic

## Environment Detection
The app automatically detects the environment:
- `dart.vm.product = true` → Release mode (10s timeout)
- `dart.vm.product = false` → Debug mode (30s timeout)