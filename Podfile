source 'ssh://git@bitbucket.org/rtsmb/srgpodspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
platform :ios, '7.0'
workspace 'SRGAnalytics.xcworkspace'

pod 'comScore-iOS-SDK-RTS', '3.1504.30'
pod 'SRGMediaPlayer', '~> 0.8.7'

xcodeproj 'SRGAnalytics', 'Test' => :debug

target :'SRGAnalyticsTests', :exclusive => true do
    pod 'OCMock', '~> 3.1.2'
end

### Demo project

target 'SRGAnalytics Demo', :exclusive => true do
	xcodeproj 'RTSAnalytics Demo/SRGAnalytics Demo', 'Test' => :debug
	pod 'SRGAnalytics',               { :path => '.' }
	pod 'SRGAnalytics/MediaPlayer',   { :path => '.' }
	pod 'SRGMediaPlayer',             '~> 0.8.7'
end

target 'SRGAnalytics DemoTests', :exclusive => true do
	xcodeproj 'RTSAnalytics Demo/SRGAnalytics Demo', 'Test' => :debug
	pod 'KIF', '3.2.1'
end

### Workaround to make sure to have iPad xibs compiled as well.

post_install do |installer|
    
    installer.project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2' # iPhone, iPad
#            config.build_settings['TARGETED_DEVICE_FAMILY'] = '2'
        end
    end
    
end

