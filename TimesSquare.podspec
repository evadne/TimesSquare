Pod::Spec.new do |s|
  s.name         = "TimesSquare"
  s.version      = "1.0.1"
  s.summary      = "TimesSquare is an Objective-C calendar view for your apps."
  s.homepage     = "https://github.com/evadne/TimesSquare"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { "Square" => "http://squareup.com" }
  s.source       = { :git => "https://github.com/evadne/TimesSquare.git", :branch => "develop", :tag => "head" }
  s.platform     = :ios, '6.0'
  s.source_files = 'TimesSquare/*.{h,m}'
  s.requires_arc = true
end