source 'https://github.com/CocoaPods/Specs.git'
source 'ssh://git@bitbucket.org/rtsmb/srgpodspecs.git'

inhibit_all_warnings!
platform :ios, '7.0'
workspace 'SRGAnalytics.xcworkspace'

pod 'comScore-iOS-SDK-RTS', '3.1509.15'
pod 'SRGMediaPlayer', '~> 1.6.1'

xcodeproj 'SRGAnalytics', 'Test' => :debug

target :'SRGAnalyticsTests' do
    pod 'SRGAnalytics', :path => '.'
    pod 'SRGAnalytics/MediaPlayer', :path => '.'
    pod 'OCMock', '~> 3.1.2'
end

#### Demo project

target 'SRGAnalytics Demo', :exclusive => true do
	xcodeproj 'RTSAnalytics Demo/SRGAnalytics Demo', 'Test' => :debug
	pod 'SRGAnalytics',               { :path => '.' }
	pod 'SRGAnalytics/MediaPlayer',   { :path => '.' }
	pod 'SRGMediaPlayer',             '~> 1.6.1'
end

target 'SRGAnalytics DemoTests', :exclusive => true do
	xcodeproj 'RTSAnalytics Demo/SRGAnalytics Demo', 'Test' => :debug
	pod 'KIF', '3.4.1'
end

### Workaround to make sure to have iPad xibs compiled as well.

post_install do |installer|
    
    pods_project = installer.respond_to?(:pods_project) ? installer.pods_project : installer.project # Prepare for CocoaPods 0.38.2

    pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2' # iPhone, iPad
        end
    end
    
end
