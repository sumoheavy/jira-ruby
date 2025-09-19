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
    'rubygems_mfa_required' => 'true'
  }

  s.required_ruby_version = '>= 3.1.0'

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  # Runtime Dependencies
  s.add_dependency 'activesupport'
  s.add_dependency 'atlassian-jwt'
  s.add_dependency 'multipart-post'
  s.add_dependency 'oauth', '~> 0.5', '>= 0.5.0'
  s.add_dependency 'oauth2', '~> 2.0', '>= 2.0.9'
end
