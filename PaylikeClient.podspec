Pod::Spec.new do |s|
  s.name             = 'PaylikeClient'
  s.swift_version    = '5.0'
  s.ios.deployment_target = '13.0'
  s.version          = '0.2.0'
  s.summary          = 'High level API package to construct specific requests towards the Paylike ecosystem'
  s.description      = <<-DESC
This packages is a clone of the JS version and responsible for providing a handy high level
interface to create payments in the Paylike ecosystem
                       DESC

  s.homepage         = 'https://github.com/paylike/swift-client'
  s.license          = { :type => 'BSD-3', :file => 'LICENSE' }
  s.author           = { 'Paylike.io' => 'info@paylike.io' }
  s.source           = {
  :git => 'https://github.com/paylike/swift-client.git',
  :tag => s.version.to_s
}
  s.source_files = 'Sources/PaylikeClient/**/*'
  s.dependency 'PaylikeRequest'
  s.dependency 'AnyCodable-FlightSchool'
end
