# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "jira/version"

Gem::Specification.new do |s|
  s.name        = "jira-ruby"
  s.version     = JIRA::VERSION
  s.authors     = ["SUMO Heavy Industries"]
  s.homepage    = "http://www.sumoheavy.com"
  s.summary     = %q{Ruby Gem for use with the Atlassian JIRA REST API}
  s.description = %q{API for JIRA}
  s.licenses    = ["OSL-3.0"]

  s.rubyforge_project = "jira-ruby"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "oauth", '~> 0.4.7'
  s.add_runtime_dependency "activesupport"

  s.add_development_dependency "railties", '~> 4.1.4'
  s.add_development_dependency "webmock", '~> 1.18.0'
  s.add_development_dependency "rspec", '~> 3.0.0'
  s.add_development_dependency "rake", '~> 10.3.2'
end
