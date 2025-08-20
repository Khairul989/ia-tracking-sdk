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
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  
  # Reference to our native iOS SDK
  # TODO: Uncomment when native iOS SDK is properly integrated
  # s.dependency 'IATracking', '~> 1.0.0'
  
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end