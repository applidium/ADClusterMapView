Pod::Spec.new do |spec|
  spec.name         = 'ADClusterMapView'
  spec.version      = '1.2.0'
  spec.authors      = 'Applidium'
  spec.license      = { :type => 'BSD' }
  spec.homepage     = 'http://applidium.github.io/ADClusterMapView/'
  spec.summary      = 'ADClusterMapView is a drop-in subclass of MKMapView that displays and animate clusters of annotations.'
  spec.platform     = 'ios', '5.0'
  spec.authors      = { 'Applidium' => 'https://github.com/applidium/' }
  spec.source       = { :git => 'https://github.com/applidium/ADClusterMapView.git', :tag => "v#{spec.version}" }
  spec.source_files = 'ADClusterMapView/**/*.{h,m}'
  spec.frameworks    = 'MapKit', 'CoreLocation'
  spec.requires_arc = true
end
