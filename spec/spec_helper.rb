$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'bundler/setup'
require 'webmock/rspec'

require 'jira'

RSpec.configure do |config|

end

def get_mock_response(file)
  File.read(File.join(File.dirname(__FILE__), 'mock_responses/', file))
end
