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
  s.metadata    = { 'source_code_uri' => 'https://github.com/sumoheavy/jira-ruby' }

  s.required_ruby_version = '>= 1.9.3'

  s.rubyforge_project = 'jira-ruby'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  # Runtime Dependencies
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'atlassian-jwt'
  s.add_runtime_dependency 'multipart-post'

  # Development Dependencies
  s.add_development_dependency 'guard', '~> 2.13', '>= 2.13.0'
  s.add_development_dependency 'guard-rspec', '~> 4.6', '>= 4.6.5'
  s.add_development_dependency 'pry', '~> 0.10', '>= 0.10.3'
  s.add_development_dependency 'railties'
  s.add_development_dependency 'rake', '~> 10.3', '>= 10.3.2'
  s.add_development_dependency 'rspec', '~> 3.0', '>= 3.0.0'
  s.add_development_dependency 'webmock', '~> 1.18', '>= 1.18.0'
end
