# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "jira_api/version"

Gem::Specification.new do |s|
  s.name        = "jira_api"
  s.version     = JiraApi::VERSION
  s.authors     = ["Greg Signal"]
  s.email       = ["greg.signal@trineo.co.nz"]
  s.homepage    = ""
  s.summary     = %q{API for Jira 5}
  s.description = %q{API for Jira 5}

  s.rubyforge_project = "jira_api"

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
end
