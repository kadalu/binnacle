# rubocop:disable Gemspec/RequiredRubyVersion
# frozen_string_literal: true

require_relative 'lib/kadalu/binnacle/version'

Gem::Specification.new do |spec|
  spec.name        = 'kadalu-binnacle'
  spec.version     = Kadalu::Binnacle::VERSION
  spec.summary     = 'Automate tests & infra with the simple imperative code'
  spec.description = 'Easy to use syntax allows you to get started in minutes'
  spec.authors     = ['Aravinda VK']
  spec.email       = 'aravinda@kadalu.tech'
  spec.files       = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.homepage    = 'https://github.com/kadalu/binnacle'
  spec.license     = 'Apache-2.0'

  spec.executables = %w[binnacle]

  spec.add_development_dependency 'rubocop', '~> 0.60'
end
# rubocop:enable Gemspec/RequiredRubyVersion
