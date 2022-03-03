source 'https://rubygems.org'

# Specify your gem's dependencies in google_maps_service.gemspec
gemspec

group :development do
  gem 'bundler', '~> 2.1'
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.3'
  gem 'simplecov', '~> 0.12'
  gem 'coveralls', '~> 0.8.2'
  gem 'webmock', '~> 2.3.1'
end

platforms :ruby do
  group :development do
    gem 'yard', '~> 0.9'
    gem 'redcarpet', '~> 3.5'
  end
end

if ENV['RAILS_VERSION']
  gem 'rails', ENV['RAILS_VERSION']
end
