source 'https://github.com/CocoaPods/Specs.git'
source 'ssh://git@bitbucket.org/rtsmb/srgpodspecs.git'

platform :ios, '7.0'
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
    pod 'OCMock', '~> 3.1.2'
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
    pod 'KIF', '3.4.1'
  end

  xcodeproj 'RTSAnalytics Demo/SRGAnalytics Demo', 'Test' => :debug
end
