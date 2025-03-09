require 'spec_helper'

describe JIRA::Resource::Webhook do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '2' }

    let(:expected_attributes) do
      { 'name' => 'from API', 'url' => 'http://localhost:3000/webhooks/1', 'excludeBody' => false,
'filters' => { 'issue-related-events-section' => '' }, 'events' => [], 'enabled' => true, 'self' => 'http://localhost:2990/jira/rest/webhooks/1.0/webhook/2', 'lastUpdatedUser' => 'admin', 'lastUpdatedDisplayName' => 'admin', 'lastUpdated' => 1_453_306_520_188 }
    end

    let(:expected_collection_length) { 1 }

    it_behaves_like 'a resource'
    it_behaves_like 'a resource with a collection GET endpoint'
    it_behaves_like 'a resource with a singular GET endpoint'

    it 'returns a collection of components' do
      stub_request(:get, site_url + described_class.singular_path(client, key))
        .to_return(status: 200, body: get_mock_response('webhook/webhook.json'))
    end
  end
end
