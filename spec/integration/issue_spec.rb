require 'spec_helper'

describe JIRA::Resource::Issue do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '10002' }

    let(:expected_attributes) do
      {
        'self' => 'http://localhost:2990/jira/rest/api/2/issue/10002',
        'key' => 'SAMPLEPROJECT-1',
        'expand' => 'renderedFields,names,schema,transitions,editmeta,changelog'
      }
    end

    let(:attributes_for_post) do
      { 'foo' => 'bar' }
    end
    let(:expected_attributes_from_post) do
      { 'id' => '10005', 'key' => 'SAMPLEPROJECT-4' }
    end

    let(:attributes_for_put) do
      { 'foo' => 'bar' }
    end
    let(:expected_attributes_from_put) do
      { 'foo' => 'bar' }
    end
    let(:expected_collection_length) { 11 }

    it_behaves_like 'a resource'
    it_behaves_like 'a resource with a singular GET endpoint'
    describe 'GET all issues' do # JIRA::Resource::Issue.all uses the search endpoint
      let(:client) { client }
      let(:site_url) { site_url }

      let(:expected_attributes) do
        {
          'id' => '10014',
          'self' => 'http://localhost:2990/jira/rest/api/2/issue/10014',
          'key' => 'SAMPLEPROJECT-13'
        }
      end

      before do
        stub_request(:get, "#{site_url}/jira/rest/api/2/search?expand=transitions.fields&maxResults=1000&startAt=0")
          .to_return(status: 200, body: get_mock_response('issue.json'))

        stub_request(:get, "#{site_url}/jira/rest/api/2/search?expand=transitions.fields&maxResults=1000&startAt=11")
          .to_return(status: 200, body: get_mock_response('empty_issues.json'))
      end

      it_behaves_like 'a resource with a collection GET endpoint'
    end

    it_behaves_like 'a resource with a DELETE endpoint'
    it_behaves_like 'a resource with a POST endpoint'
    it_behaves_like 'a resource with a PUT endpoint'
    it_behaves_like 'a resource with a PUT endpoint that rejects invalid fields'

    describe 'errors' do
      before do
        stub_request(:get,
                     "#{site_url}/jira/rest/api/2/issue/10002")
          .to_return(status: 200, body: get_mock_response('issue/10002.json'))
        stub_request(:put, "#{site_url}/jira/rest/api/2/issue/10002")
          .with(body: '{"missing":"fields and update"}')
          .to_return(status: 400, body: get_mock_response('issue/10002.put.missing_field_update.json'))
      end

      it 'fails to save when fields and update are missing' do
        subject = client.Issue.build('id' => '10002')
        subject.fetch
        expect(subject.save('missing' => 'fields and update')).to be_falsey
      end
    end

    describe 'GET jql issues' do # JIRA::Resource::Issue.jql uses the search endpoint
      jql_query_string = "PROJECT = 'SAMPLEPROJECT'"
      let(:client) { client }
      let(:site_url) { site_url }
      let(:jql_query_string) { jql_query_string }

      let(:expected_attributes) do
        {
          'id' => '10014',
          'self' => 'http://localhost:2990/jira/rest/api/2/issue/10014',
          'key' => 'SAMPLEPROJECT-13'
        }
      end

      it_behaves_like 'a resource with JQL inputs and a collection GET endpoint'
    end
  end
end
