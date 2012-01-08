$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'bundler/setup'
require 'webmock/rspec'
Dir["./spec/support/**/*.rb"].each {|f| require f}

require 'jira'

RSpec.configure do |config|

end

RSpec::Matchers.define :have_attributes do |expected|
  match do |actual|
    expected.each do |key, value|
      actual.attrs[key].should == value
    end
  end

  failure_message_for_should do |actual|
    "expected #{actual.attrs} to match #{expected}"
  end
end

def get_mock_response(file)
  File.read(File.join(File.dirname(__FILE__), 'mock_responses/', file))
end
