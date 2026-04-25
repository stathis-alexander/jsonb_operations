# frozen_string_literal: true

require_relative 'lib/jsonb_operations/version'

Gem::Specification.new do |spec|
  spec.name    = 'jsonb_operations'
  spec.version = JsonbOperations::VERSION
  spec.authors = ['Alexander Stathis']
  spec.email   = ['stathis.alexanderj@gmail.com']

  spec.summary     = 'Arel nodes for all PostgreSQL JSONB operators'
  spec.description = 'Provides Arel and ActiveRecord extensions for PostgreSQL JSONB operators.'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.0'

  spec.files         = Dir['lib/**/*.rb', 'LICENSE']
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord',   '>= 5.0'
  spec.add_dependency 'activesupport',  '>= 5.0'
end
