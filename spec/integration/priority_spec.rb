require 'spec_helper'

describe JIRA::Resource::Priority do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '1' }

    let(:expected_attributes) do
      {
        'self' => 'http://localhost:2990/jira/rest/api/2/priority/1',
        'id' => key,
        'name' => 'Blocker'
      }
    end

    let(:expected_collection_length) { 5 }

    it_behaves_like 'a resource'
    it_behaves_like 'a resource with a collection GET endpoint'
    it_behaves_like 'a resource with a singular GET endpoint'
  end
end
