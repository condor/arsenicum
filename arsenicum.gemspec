# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'arsenicum/version'

Gem::Specification.new do |spec|
  spec.name          = "arsenicum"
  spec.version       = Arsenicum::VERSION
  spec.authors       = ["condor"]
  spec.email         = ["condor1226@gmail.com"]
  spec.description   = %q{Arsenicum: multi-backend asyncronous processor.}
  spec.summary       = %q{Arsenicum: multi-backend asyncronous processor.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/).reject{|s|s == 'build.rake'}
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'aws-sdk'
  spec.add_dependency 'multi_json'
  spec.add_dependency 'celluloid'
  spec.add_dependency 'msgpack'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rails', '~> 4.0'
  spec.add_development_dependency 'sqlite3'
end
