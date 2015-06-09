source 'ssh://git@bitbucket.org/rtsmb/srgpodspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'
workspace 'RTSAnalytics.xcworkspace'

pod 'comScore-iOS-SDK-RTS', '3.1502.26'
pod 'RTSMediaPlayer', '0.2.5'

pod 'CocoaLumberjack', '2.0.0'

target :'RTSAnalyticsTests', :exclusive => true do
    pod 'OCMock', '~> 3.1.2'
end

### Demo project

target 'RTSAnalytics Demo', :exclusive => true do
	xcodeproj 'RTSAnalytics Demo/RTSAnalytics Demo'

	pod 'RTSAnalytics',               { :path => '.' }
	pod 'RTSAnalytics/MediaPlayer',   { :path => '.' }
	pod 'RTSMediaPlayer',             '0.2.5'
end

target 'RTSAnalytics DemoTests', :exclusive => true do
	xcodeproj 'RTSAnalytics Demo/RTSAnalytics Demo'

	pod 'KIF', '3.2.1'
end
