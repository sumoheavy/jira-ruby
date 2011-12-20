require "bundler/gem_tasks"

require 'rubygems'
require 'rspec/core/rake_task'
Dir.glob('lib/tasks/*.rake').each { |r| import r }

task :default => [:spec]

desc "Run RSpec tests"
RSpec::Core::RakeTask.new(:spec)
