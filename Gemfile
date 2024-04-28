# frozen_string_literal: true

source 'https://rubygems.org'

group :development do
  gem 'guard'
  gem 'guard-rspec'
  gem 'wdm', '>= 0.1.0' if Gem.win_platform?
end

group :development, :test do
  gem 'pry' # this was in the original Gemfile - but only needed in development & test
  gem 'rubocop'
  gem 'rubocop-rspec', require: false
end

# Specify your gem's dependencies in jira_api.gemspec
gemspec
