# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "config_mapper/version"

Gem::Specification.new do |spec|

  spec.name          = "config_mapper"
  spec.version       = ConfigMapper::VERSION

  spec.summary       = "Maps config data onto plain old objects"
  spec.license       = "MIT"

  spec.authors       = ["Mike Williams"]
  spec.email         = ["mdub@dogbiscuit.org"]
  spec.homepage      = "https://github.com/mdub/config_mapper"

  spec.files         = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.9.0"
  spec.add_development_dependency "rubocop", "~> 0.79.0"

end
