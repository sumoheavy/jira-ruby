$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'bundler/setup'
require 'webmock/rspec'
Dir['./spec/support/**/*.rb'].each { |f| require f }

require 'jira-ruby'

RSpec.configure do |config|
  config.extend ClientsHelper
end

def get_mock_response(file, value_if_file_not_found = false)
  file.sub!('?', '_') # we have to replace this character on Windows machine
  File.read(File.join(File.dirname(__FILE__), 'mock_responses/', file))
rescue Errno::ENOENT => e
  raise e if value_if_file_not_found == false
  value_if_file_not_found
end
