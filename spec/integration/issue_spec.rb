require 'spec_helper'

describe Jira::Resource::Issue do

  let(:client) do
    client = Jira::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  before(:each) do
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2.0.alpha1/issue/SAMPLE-1").
                 to_return(:body => get_mock_response('issue/SAMPLE-1.json'))
  end

  it "should get a single issue by key" do
    issue = client.Issue.find('SAMPLE-1')

    issue.self.should   == "http://localhost:2990/jira/rest/api/2.0.alpha1/issue/SAMPLE-1"
    issue.key.should    == "SAMPLE-1"
    issue.expand.should == "html"
  end

  it "builds and fetches single issue" do
    issue = client.Issue.build('key' => 'SAMPLE-1')
    issue.fetch

    issue.self.should   == "http://localhost:2990/jira/rest/api/2.0.alpha1/issue/SAMPLE-1"
    issue.key.should    == "SAMPLE-1"
    issue.expand.should == "html"
  end
end
