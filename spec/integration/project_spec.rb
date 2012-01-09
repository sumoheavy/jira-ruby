require 'spec_helper'

describe JIRA::Resource::Project do

  let(:client) do
    client = JIRA::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:key) { "SAMPLEPROJECT" }

  let(:expected_attributes) do
    {
      'self'   => "http://localhost:2990/jira/rest/api/2/project/SAMPLEPROJECT",
      'key'    => key,
      'name'   => "Sample Project for Developing RoR RESTful API"
    }
  end

  it_should_behave_like "a resource"
  it_should_behave_like "a resource with a collection GET endpoint"
  it_should_behave_like "a resource with a singular GET endpoint"

  describe "issues" do

    it "returns all the issues" do
      stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?jql=project='SAMPLEPROJECT'").
        to_return(:status => 200, :body => get_mock_response('project/SAMPLEPROJECT.issues.json'))
      subject = client.Project.build('key' => key)
      issues = subject.issues
      issues.length.should == 11
      issues.each do |issue|
        issue.class.should == JIRA::Resource::Issue
        issue.expanded?.should be_false
      end

    end

  end
end
