source 'https://rubygems.org'

ruby '3.0.6'

# Specify your gem's dependencies in google_maps_apis.gemspec
gemspec

group :development do
  gem 'bundler', '~> 2.3'
  gem 'rake', '~> 12.0'
  gem 'rspec', '~> 3.3'
  gem 'simplecov', '~> 0.12'
  gem 'coveralls', '~> 0.8.2'
  gem 'webmock', '~> 2.3'
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
