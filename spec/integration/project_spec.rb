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

  let(:expected_collection_length) { 1 }

  it_should_behave_like "a resource"
  it_should_behave_like "a resource with a collection GET endpoint"
  it_should_behave_like "a resource with a singular GET endpoint"

  describe "issues" do

    it "returns all the issues" do
      stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?jql=project='SAMPLEPROJECT'&startAt=0").
        to_return(:status => 200, :body => get_mock_response('project/SAMPLEPROJECT.issues.json'))
      subject = client.Project.build('key' => key)
      issues = subject.issues
      issues.length.should == 11
      issues.each do |issue|
        issue.class.should == JIRA::Resource::Issue
        issue.expanded?.should be_false
      end

    end

    it "enumrate all projects using a block" do
      stub_request(:get, "http://localhost:2990/jira/rest/api/2/project").
        to_return(:status => 200, :body => get_mock_response('project.json'))
      count = 0
      client.Project.all do |project|
        count += 1
        project.class.should == JIRA::Resource::Project
      end
      count.should == 1

    end

    it "search returns the issues" do
      
      query = "assignee = 'admin'"

      stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?jql=" + URI.escape(query+ " project='SAMPLEPROJECT'") + "&startAt=0").
                   to_return(:status => 200, :body => get_mock_response('project/SAMPLEPROJECT.issues.json'))
      subject = client.Project.build('key' => key)

      JIRA::Resource::Project.get_scoped_jql(subject).should == "project='SAMPLEPROJECT'"
      
      issues = subject.issues(query)
      issues.length.should == 11
      issues.each do |issue|
        issue.class.should == JIRA::Resource::Issue
        issue.expanded?.should be_false
      end

    end

    it "search returns the issues using an enumerator" do
      
      query = "assignee = 'admin'"

      stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?jql=" + URI.escape("project='SAMPLEPROJECT'") + "&startAt=0").
                   to_return(:status => 200, :body => get_mock_response('project/SAMPLEPROJECT.issues.json'))
      subject = client.Project.build('key' => key)

      JIRA::Resource::Project.get_scoped_jql(subject).should == "project='SAMPLEPROJECT'"

      count = 0
      subject.issues do |issue|
        issue.class.should == JIRA::Resource::Issue
        issue.expanded?.should be_false
        count += 1
      end
      count.should == 11
    end

  end



  it "returns a collection of components" do

    stub_request(:get, 'http://localhost:2990' + described_class.singular_path(client, key)).
      to_return(:status => 200, :body => get_mock_response('project/SAMPLEPROJECT.json'))

    subject = client.Project.find(key)
    subject.components.length.should == 2
    subject.components.each do |component|
      component.class.should == JIRA::Resource::Component
    end

  end
end
