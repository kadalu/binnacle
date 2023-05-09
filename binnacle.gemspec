require_relative "lib/binnacle/version"

Gem::Specification.new do |spec|
  spec.name        = "binnacle"
  spec.version     = Binnacle::VERSION
  spec.summary     = "Automate tests & infra with the simple imperative code"
  spec.description = "Automate tests & infra with the simple imperative code"
  spec.authors     = ["Aravinda Vishwanathapura"]
  spec.email       = "aravinda@kadalu.tech"
  spec.files       = Dir["lib/**/*", "LICENSE", "README.adoc"]
  spec.homepage    = "https://github.com/kadalu/binnacle"
  spec.license     = "Apache-2.0"

  spec.executables = %w[ binnacle ]
end
