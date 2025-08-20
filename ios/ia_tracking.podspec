Pod::Spec.new do |s|
  s.name             = 'ia_tracking'
  s.version          = '1.0.0'
  s.summary          = 'IA Tracking Flutter SDK - Cross-platform user action tracking'
  s.description      = <<-DESC
IA Tracking Flutter SDK provides seamless integration with native Android and iOS
IA Tracking SDKs for comprehensive user action tracking in Flutter applications.
                       DESC
  s.homepage         = 'https://github.com/iav3/ia-tracking-flutter-sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'IAv3 Team' => 'flutter-support@iav3.com' }
  
  s.source           = { :path => '.' }
  
  # DEVELOPMENT MODE: Source code visible (current)
  s.source_files     = 'Classes/**/*'
  
  # PRODUCTION MODE: Use compiled framework (uncomment for production)
  # s.vendored_frameworks = 'Frameworks/IaTracking.framework'
  # s.source_files = 'Classes/IaTrackingPlugin.h' # Only header for Flutter bridge
  
  s.dependency 'Flutter'
  
  # Optional: If you have a separate native iOS SDK
  # s.dependency 'IATrackingCore', '~> 1.0.0'
  
  # Required iOS frameworks for IDFA and App Tracking Transparency
  s.frameworks = 'AdSupport', 'AppTrackingTransparency', 'StoreKit'
  
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end