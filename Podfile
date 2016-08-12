source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/SRGSSR/srgpodspecs-ios.git'

platform :ios, '8.0'
inhibit_all_warnings!

workspace 'SRGAnalytics'

# Will be inherited by all targets below
pod 'SRGAnalytics', :path => '.'

target 'SRGAnalytics' do
  target 'SRGAnalyticsTests' do
    # Test target, inherit search paths only, not linking
    # For more information, see http://blog.cocoapods.org/CocoaPods-1.0-Migration-Guide/
    inherit! :search_paths

    # Repeat SRGAnalytics podspec dependencies
    pod 'ComScore-iOS'

    # Target-specific dependencies
    pod 'OCMock', '~> 3.3.0'
    pod 'SRGAnalytics/MediaPlayer', :path => '.'
  end

  xcodeproj 'SRGAnalytics.xcodeproj', 'Test' => :debug
end

target 'SRGAnalytics Demo' do
  pod 'SRGAnalytics/MediaPlayer', :path => '.'

  target 'SRGAnalytics DemoTests' do
    # See above
    inherit! :search_paths

    # Target-specific dependencies
    pod 'KIF', '~> 3.4.0'
  end

  xcodeproj 'RTSAnalytics Demo/SRGAnalytics Demo', 'Test' => :debug
end
