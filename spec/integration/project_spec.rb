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

  before(:each) do
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2/project").
                 to_return(:status => 200, :body => get_mock_response('project.json'))
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2/project/SAMPLEPROJECT").
                 to_return(:status => 200,:body => get_mock_response('project/SAMPLEPROJECT.json'))
  end

  it "should get all the projects" do
    projects = client.Project.all
    projects.length.should == 1

    first = projects.first
    first.should have_attributes(expected_attributes)
  end

  it_should_behave_like "a resource with a singular GET endpoint"
end
