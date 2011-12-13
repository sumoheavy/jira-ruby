require 'spec_helper'

describe Jira::Resource::Issue do

  let(:client) do
    client = Jira::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:expected_attributes) do
    {
      'self'   => "http://localhost:2990/jira/rest/api/2/issue/10002",
      'key'    => "SAMPLEPROJECT-1",
      'expand' => "renderedFields,names,schema,transitions,editmeta,changelog"
    }
  end

  before(:each) do
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2/issue/SAMPLEPROJECT-1").
                 to_return(:body => get_mock_response('issue/SAMPLEPROJECT-1.json'))
  end

  it "should get a single issue by key" do
    issue = client.Issue.find('SAMPLEPROJECT-1')

    issue.should have_attributes(expected_attributes)
  end

  it "builds and fetches single issue" do
    issue = client.Issue.build('key' => 'SAMPLEPROJECT-1')
    issue.fetch

    issue.should have_attributes(expected_attributes)
  end
end
