require 'spec_helper'

describe JIRA::Resource::Project do

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }


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
        stub_request(:get, site_url + "/jira/rest/api/2/search?jql=project='SAMPLEPROJECT'").
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

    it "returns a collection of components" do

      stub_request(:get, site_url + described_class.singular_path(client, key)).
        to_return(:status => 200, :body => get_mock_response('project/SAMPLEPROJECT.json'))

      subject = client.Project.find(key)
      subject.components.length.should == 2
      subject.components.each do |component|
        component.class.should == JIRA::Resource::Component
      end

    end
  end
end
