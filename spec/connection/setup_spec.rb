require 'spec_helper'

describe JiraApi::Connection do
  before(:each) do
    @args = {
      :base_url => "http://localhost:2990/jira",
      :consumer_key => "0cc0d90a5479700cea6232565d29447d"
    }
  end
  it 'should initialise correctly' do
    u = JiraApi::Connection.new(@args)
    u.should respond_to :base_url
    u.should respond_to :consumer_key
    u.should respond_to :consumer_secret
    u.should respond_to :oauth_token
    u.should respond_to :oauth_token_secret
    u.base_url.should == @args[:base_url]
  end
end
