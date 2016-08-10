Pod::Spec.new do |s|

  s.name         = "LFHeatMap"
  s.version      = "1.0.2"
  s.summary      = "Extremely fast heat maps for iOS"
  s.homepage     = "https://github.com/gpolak/LFHeatMap"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  
  s.author       = { "George Polak" => "george.polak@gmail.com" }

  s.platform     = :ios, "5.0"

  s.source       = { :git => "https://github.com/gpolak/LFHeatMap.git", :tag => "1.0.2" }

  s.source_files = 'LFHeatMap'
  s.requires_arc = true

end
