require "bundler/gem_tasks"

require 'rubygems'
require 'rspec/core/rake_task'
require 'rake/rdoctask'

Dir.glob('lib/tasks/*.rake').each { |r| import r }

task :default => [:spec]

desc "Run RSpec tests"
RSpec::Core::RakeTask.new(:spec)

Rake::RDocTask.new(:doc) do |rd|
  rd.main     = 'README.rdoc'
  rd.rdoc_dir = 'doc'
end
