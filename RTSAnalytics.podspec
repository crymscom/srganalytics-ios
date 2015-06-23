Pod::Spec.new do |s|
  s.name        = "RTSAnalytics"
  s.version     = "0.4.0"
  s.summary     = "Analytics for SRG mobile applications"
  s.description = "Analytics for SRG mobile applications"
  s.homepage    = "https://bitbucket.org/rtsmb/srganalytics-ios"
  s.license     = { :type => "N/A" }
  s.authors     = { "Cédric Foellmi" => "cedric.foellmi@hortis.ch", "Cédric Luthi" => "cedric.luthi@rts.ch", "Frédéric Humbert-Droz" => "fred.hd@me.com", "Samuel Défago" => "defagos@gmail.com" }
  s.source      = { :git => "git@bitbucket.org:rtsmb/srganalytics-ios.git", :tag => s.version.to_s }

  # Platform setup
  s.requires_arc = true
  s.ios.deployment_target = "7.0"

  # Exclude optional Stream Measurement modules
  s.default_subspec = 'Core'

  ### Subspecs

  s.subspec 'Core' do |co|
    co.source_files         = "RTSAnalytics/RTSAnalytics.h", "RTSAnalytics/Core/*.{h,m}"
    co.private_header_files = "RTSAnalytics/Core/*_private.h"
    co.frameworks           = "AVFoundation", "CoreMedia", "Foundation", "MediaPlayer", "UIKit"
    co.dependency             "comScore-iOS-SDK-RTS", "3.1502.26"

    co.subspec 'Version' do |ve|
      ve.source_files = "RTSAnalytics/Core/RTSAnalyticsVersion.m"
      ve.compiler_flags = '-DRTS_ANALYTICS_VERSION=' + s.version.to_s
    end
  end

  s.subspec 'MediaPlayer' do |sm|
    sm.source_files         = "RTSAnalytics/RTSAnalyticsMediaPlayer.h", "RTSAnalytics/MediaPlayer/*.{h,m}"
    sm.private_header_files = "RTSAnalytics/MediaPlayer/*_private.h"
    sm.dependency             "RTSAnalytics/Core"
    sm.dependency             "RTSMediaPlayer", "~> 0.4.0"
  end

end
