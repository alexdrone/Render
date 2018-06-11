Pod::Spec.new do |s|
  s.name             = "RenderNeutrino"
  s.version          = "5.5.2"
  s.summary          = "Render is a declarative library for building efficient UIs on iOS inspired by React."
  s.description      = <<-DESC
  s.platform         = :ios
  Render is a declarative library for building efficient UIs on iOS inspired by React.

  * Declarative: Render uses a declarative API to define UI components. You simply describe the layout for your UI based on a set of inputs and the framework takes care of the rest (diff and reconciliation from virtual view hierarchy to the actual one under the hood).
  * Flexbox layout: Render includes the robust and battle-tested Facebook's Yoga as default layout engine.
  * Fine-grained recycling: Any component such as a text or image can be recycled and reused anywhere in the UI.
                       DESC

  s.homepage         = "https://github.com/alexdrone/Render"
  s.screenshots      = "https://raw.githubusercontent.com/alexdrone/Render/master/docs/assets/logo_small.png"
  s.license          = 'MIT'
  s.author           = { "Alex Usbergo" => "alexakadrone@gmail.com" }
  s.source           = { :git => "https://github.com/alexdrone/Render.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/alexdrone'
  s.ios.deployment_target = '10.0'
  s.source_files = 'render/**/*', 'mods/inspector/**/*'
  s.ios.public_header_files = ['render/**/*.{h}']
  s.frameworks = 'UIKit'
  s.module_name = "RenderNeutrino"
  s.compiler_flags = ""
end
