require 'rspec/core/rake_task'
require 'rdoc/task'

Dir.glob('lib/tasks/*.rake').each { |r| import r }

task :default => [:test]

task :test => [:prepare, :spec]

desc "Prepare and run rspec tests"
task :prepare do
  rsa_key = File.expand_path('rsakey.pem')
  if !File.exists?(rsa_key)
    raise "rsakey.pem does not exist, tests will fail.  Run `rake jira:generate_public_cert` first"
  end
end

desc "Run RSpec tests"
RSpec::Core::RakeTask.new(:spec)

Rake::RDocTask.new(:doc) do |rd|
  rd.main       = 'README.rdoc'
  rd.rdoc_dir   = 'doc'
  rd.rdoc_files.include('README.rdoc', 'lib/**/*.rb')
end
