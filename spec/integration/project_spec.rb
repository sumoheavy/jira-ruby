require 'spec_helper'

describe JIRA::Resource::Project do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { 'SAMPLEPROJECT' }

    let(:expected_attributes) do
      {
        'self'   => 'http://localhost:2990/jira/rest/api/2/project/SAMPLEPROJECT',
        'key'    => key,
        'name'   => 'Sample Project for Developing RoR RESTful API'
      }
    end

    let(:expected_collection_length) { 1 }

    it_should_behave_like 'a resource'
    it_should_behave_like 'a resource with a collection GET endpoint'
    it_should_behave_like 'a resource with a singular GET endpoint'

    describe 'issues' do
      it 'returns all the issues' do
        stub_request(:get, site_url + '/jira/rest/api/2/search?jql=project="SAMPLEPROJECT"')
          .to_return(status: 200, body: get_mock_response('project/SAMPLEPROJECT.issues.json'))
        subject = client.Project.build('key' => key)
        issues = subject.issues
        expect(issues.length).to eq(11)
        issues.each do |issue|
          expect(issue.class).to eq(JIRA::Resource::Issue)
          expect(issue.expanded?).to be_falsey
        end
      end
    end

    it 'returns a collection of components' do
      stub_request(:get, site_url + described_class.singular_path(client, key))
        .to_return(status: 200, body: get_mock_response('project/SAMPLEPROJECT.json'))

      subject = client.Project.find(key)
      expect(subject.components.length).to eq(2)
      subject.components.each do |component|
        expect(component.class).to eq(JIRA::Resource::Component)
      end
    end
  end
end
