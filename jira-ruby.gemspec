# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'jira/version'

Gem::Specification.new do |s|
  s.name        = 'jira-ruby'
  s.version     = JIRA::VERSION
  s.authors     = ['SUMO Heavy Industries', 'test IO']
  s.homepage    = 'http://www.sumoheavy.com'
  s.summary     = 'Ruby Gem for use with the Atlassian JIRA REST API'
  s.description = 'API for JIRA'
  s.licenses    = ['MIT']
  s.metadata    = {
    'source_code_uri' => 'https://github.com/sumoheavy/jira-ruby',
    'rubygems_mfa_required' => 'true' }

  s.required_ruby_version = '>= 3.1.0'

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  # Runtime Dependencies
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'atlassian-jwt'
  s.add_runtime_dependency 'multipart-post'
  s.add_runtime_dependency 'oauth', '~> 1.0'

  # Development Dependencies
  s.add_development_dependency 'guard', '~> 2.18', '>= 2.18.1'
  s.add_development_dependency 'guard-rspec', '~> 4.7', '>= 4.7.3'
  s.add_development_dependency 'pry', '~> 0.14', '>= 0.14.3'
  s.add_development_dependency 'railties'
  s.add_development_dependency 'rake', '~> 13.2', '>= 13.2.1'
  s.add_development_dependency 'rspec', '~> 3.0', '>= 3.13'
  s.add_development_dependency 'webmock', '~> 3.23', '>= 3.23.0'
end
