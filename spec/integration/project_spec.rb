require 'spec_helper'

describe Jira::Resource::Project do

  let(:client) do
    client = Jira::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:expected_attributes) do
    {
      'self'   => "http://localhost:2990/jira/rest/api/2/project/SAMPLEPROJECT",
      'key'    => "SAMPLEPROJECT",
      'name'   => "Sample Project for Developing RoR RESTful API"
    }
  end

  before(:each) do
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2/project").
                 to_return(:body => get_mock_response('project.json'))
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2/project/SAMPLEPROJECT").
                 to_return(:body => get_mock_response('project/SAMPLEPROJECT.json'))
  end

  it "should get all the projects" do
    projects = client.Project.all
    projects.length.should == 1

    first = projects.first
    first.should have_attributes(expected_attributes)
  end

  it "should get a single project by key" do
    project = client.Project.find('SAMPLEPROJECT')

    project.should have_attributes(expected_attributes)
  end

  it "builds and fetches single project" do
    project = client.Project.build('key' => 'SAMPLEPROJECT')
    project.fetch

    project.should have_attributes(expected_attributes)
  end
end
