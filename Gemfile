# frozen_string_literal: true

source 'https://rubygems.org'

group :development do
  gem 'guard', '~> 2.18', '>= 2.18.1'
  gem 'guard-rspec', '~> 4.7', '>= 4.7.3'
  gem 'railties'
  gem 'rake', '~> 13.2', '>= 13.2.1'
  gem 'rspec', '~> 3.0', '>= 3.13'
  gem 'wdm', '>= 0.1.0' if Gem.win_platform?
  gem 'webmock', '~> 3.23', '>= 3.23.0'
end

group :development, :test do
  gem 'pry' # this was in the original Gemfile - but only needed in development & test
  gem 'rubocop'
  gem 'rubocop-rspec', require: false
  gem 'byebug'
end

# Specify your gem's dependencies in jira_api.gemspec
gemspec
