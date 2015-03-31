Pod::Spec.new do |s|
  s.name = "RTSAnalytics"
  
  s.version = "0.0.1"
  
  s.summary = "RTS Analytics for the RTS Media Player"
  
  s.description = "RTS Analytics for the RTS Media Player"
  
  s.homepage = "http://rts.ch"
  
  s.license = { :type => "N/A" }
  
  s.authors = { "Cédric Foellmi" => "cedric.foellmi@hortis.ch", "Cédric Luthi" => "cedric.luthi@rts.ch" }
  
  s.source = { :git => "git@bitbucket.org:rtsmb/rtsanalytics-ios.git", :tag => s.version.to_s }
  
  s.ios.deployment_target = "7.0"
  
  s.requires_arc = true
    
  s.source_files = "RTSAnalytics/*.{m,h}"
  
  s.frameworks = [ "Foundation", "UIKit" ]
end