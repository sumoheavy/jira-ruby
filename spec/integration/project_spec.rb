require 'spec_helper'

describe Jira::Resource::Project do

  let(:client) do
    client = Jira::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  before(:each) do
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2.0.alpha1/project").
                 to_return(:body => get_mock_response('project.json'))
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2.0.alpha1/project/SAMPLEPROJECT").
                 to_return(:body => get_mock_response('project/SAMPLEPROJECT.json'))
  end

  it "should get all the projects" do
    projects = client.Project.all
    projects.length.should == 1

    first = projects.first
    first.self.should   == "http://localhost:2990/jira/rest/api/2.0.alpha1/project/SAMPLEPROJECT"
    first.key.should    == "SAMPLEPROJECT"
    first.name.should   == "Sample Project"
    first.roles.should  == {}
  end

  it "should get a single project by key" do
    project = client.Project.find('SAMPLEPROJECT')

    project.self.should   == "http://localhost:2990/jira/rest/api/2.0.alpha1/project/SAMPLEPROJECT"
    project.key.should    == "SAMPLEPROJECT"
    project.name.should   == "Sample Project"
  end

  it "builds and fetches single project" do
    project = client.Project.build('key' => 'SAMPLEPROJECT')
    project.fetch

    project.self.should   == "http://localhost:2990/jira/rest/api/2.0.alpha1/project/SAMPLEPROJECT"
    project.key.should    == "SAMPLEPROJECT"
    project.name.should   == "Sample Project"
  end
end
