# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "jira/version"

Gem::Specification.new do |s|
  s.name        = "jira-ruby"
  s.version     = JIRA::VERSION
  s.authors     = ["Trineo Ltd"]
  s.homepage    = "http://trineo.co.nz"
  s.summary     = %q{Ruby Gem for use with the Atlassian JIRA 5 REST API}
  s.description = %q{API for JIRA 5}

  s.rubyforge_project = "jira-ruby"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  s.add_runtime_dependency "oauth"
  s.add_development_dependency "oauth"
  s.add_runtime_dependency "railties"
  s.add_development_dependency "railties"
  s.add_runtime_dependency "activesupport"
  s.add_development_dependency "activesupport"
  s.add_development_dependency "webmock"
  s.add_development_dependency "rspec"
  s.add_runtime_dependency "mixlib-log"
end
