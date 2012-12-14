Pod::Spec.new do |s|
  s.name         = "ADClusterMapView"
  s.version      = "0.0.1"
  s.summary      = "ADClusterMapView is a drop-in subclass of MKMapView that displays and animate clusters of annotations."
  s.homepage     = "https://github.com/applidium/ADClusterMapView"
  s.license      = { :type => 'NetBSD', :file => 'LICENSE' }
  s.author       = { "Applidium" => "https://github.com/applidium/" }
  s.source       = { :git => "https://github.com/danpizz/ADClusterMapView.git", :tag => '0.0.1' }
  s.platform     = :ios
  s.source_files = 'ADClusterMapView/**/*.{h,m}'
  s.frameworks = 'MapKit', 'CoreLocation'
end
