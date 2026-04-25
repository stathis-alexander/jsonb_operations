# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development do
  gem 'rubocop-angellist',     github: 'angellist/rubocop-angellist', require: false
  gem 'rubocop-graphql',       require: false
  gem 'rubocop-performance',   require: false
  gem 'rubocop-rails',         require: false
  gem 'rubocop-rake',          require: false
  gem 'rubocop-rspec',         require: false
  gem 'rubocop-sorbet',        require: false
  gem 'rubocop-thread_safety', require: false
  gem 'sorbet',                require: false
  gem 'tapioca',               require: false
end

group :test do
  # Allows for overriding Rails in CI. Pins Rails to a specific minor (e.g. `~> 7.2.0`).
  rails_version = ENV.fetch('RAILS_VERSION', nil)
  if rails_version
    gem 'activerecord',  rails_version
    gem 'activesupport', rails_version
  end

  gem 'rspec', require: false
  gem 'pg',    require: false
end

group :development, :test do
  gem 'rake', require: false
end
