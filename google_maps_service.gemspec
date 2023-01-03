# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'google_maps_service/version'

Gem::Specification.new do |spec|
  spec.name          = 'google_map_services'
  spec.version       = GoogleMapsService::VERSION
  spec.authors       = ['Edward Samuel Pasaribu', 'Ahmed Abdelhamid']
  spec.email         = ['edwardsamuel92@gmail.com', 'eng.a.abdelhamid@outlook.com']

  spec.summary       = %q{Ruby gem for Google Maps Web Service APIs }
  spec.homepage      = %q{https://github.com/go-illa/google-maps-services-ruby/tree/google-map-services-gem}
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = '>= 2.6.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']
  # spec.has_rdoc      = 'yard'

  spec.add_runtime_dependency 'multi_json', '~> 1.12'
  spec.add_runtime_dependency 'faraday', '~> 2.0'
  spec.add_runtime_dependency 'retriable', '~> 3.1'
end
