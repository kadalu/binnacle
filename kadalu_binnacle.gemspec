# rubocop:disable Gemspec/RequiredRubyVersion
# frozen_string_literal: true

require_relative 'lib/binnacle/version'

Gem::Specification.new do |spec|
  spec.name        = 'kadalu_binnacle'
  spec.version     = Binnacle::VERSION
  spec.summary     = 'Automate tests & infra with the simple imperative code'
  spec.description = 'Automate tests & infra with the simple imperative code'
  spec.authors     = ['Aravinda Vishwanathapura']
  spec.email       = 'aravinda@kadalu.tech'
  spec.files       = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.homepage    = 'https://github.com/kadalu/binnacle'
  spec.license     = 'Apache-2.0'

  spec.executables = %w[binnacle]

  spec.add_development_dependency 'rubocop', '~> 0.60'
end
# rubocop:enable Gemspec/RequiredRubyVersion
