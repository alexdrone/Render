#
# Be sure to run `pod lib lint Render.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Render"
  s.version          = "2.1.1"
  s.summary          = "Swift and UIKit a la React."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  React-inspired swift library for writing UIKit UIs.
                       DESC

  s.homepage         = "https://github.com/alexdrone/Render"
  s.screenshots      = "https://github.com/alexdrone/Render/raw/master/Doc/logo.png"
  s.license          = 'MIT'
  s.author           = { "Alex Usbergo" => "alexakadrone@gmail.com" }
  s.source           = { :git => "https://github.com/alexdrone/Render.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/alexdrone'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Render/**/*'

  # s.resource_bundles = {
  #   'Render' => ['Render/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
