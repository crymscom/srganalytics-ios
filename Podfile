source 'ssh://git@bitbucket.org/rtsmb/srgpodspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'
workspace 'RTSAnalytics.xcworkspace'

pod 'comScore-iOS-SDK-RTS', '3.1502.26'
pod 'RTSMediaPlayer', '0.3.2'

target :'RTSAnalyticsTests', :exclusive => true do
    pod 'OCMock', '~> 3.1.2'
end

### Demo project

target 'RTSAnalytics Demo', :exclusive => true do
	xcodeproj 'RTSAnalytics Demo/RTSAnalytics Demo'
	pod 'RTSAnalytics',               { :path => '.' }
	pod 'RTSAnalytics/MediaPlayer',   { :path => '.' }
	pod 'RTSMediaPlayer',             '0.3.2'
end

target 'RTSAnalytics DemoTests', :exclusive => true do
	xcodeproj 'RTSAnalytics Demo/RTSAnalytics Demo'
	pod 'KIF', '3.2.1'
end

post_install do |installer|
    
    installer.project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2' # iPhone, iPad
#            config.build_settings['TARGETED_DEVICE_FAMILY'] = '2'
        end
    end
    
end

