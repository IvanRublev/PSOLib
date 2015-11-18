#
# Be sure to run `pod lib lint PSOLib.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "PSOLib"
  s.version          = "1.0.0"
  s.summary          = "Particle Swarm Optimization library for iOS and OSX."

  s.description      = <<-DESC
The standard realization of Particle Swarm Optimization algorithm that is intended to optimize non-linear problems where the solution could be represented as a point in multidimensional space. The algorithm is stochastic and robust. Belongs to Artificial Life field of study and Swarm Intelligence set of algorithms. 
                       DESC

  s.homepage         = "https://github.com/IvanRublev/PSOLib"
  s.license          = 'MIT'
  s.author           = { "Ivan Rublev" => "ivan@ivanrublev.me" }
  s.source           = { :git => "https://github.com/IvanRublev/PSOLib.git", :tag => s.version.to_s }

  s.requires_arc = true
  s.ios.deployment_target = '7.1'
  s.osx.deployment_target = '10.9'
  s.source_files = 'Pod/**/*'
  s.frameworks = 'Foundation', 'Accelerate', 'Security'
end
