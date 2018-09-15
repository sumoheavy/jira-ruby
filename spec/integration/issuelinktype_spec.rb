require 'spec_helper'

describe JIRA::Resource::Issuelinktype do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '10000' }

    let(:expected_attributes) do
      {
        'id' => key,
        'self' => 'http://localhost:2990/jira/rest/api/2/issueLinkType/10000',
        'name' => 'Blocks',
        'inward' => 'is blocked by',
        'outward' => 'blocks'
      }
    end

    let(:expected_collection_length) { 3 }

    it_should_behave_like 'a resource'
    it_should_behave_like 'a resource with a collection GET endpoint'
    it_should_behave_like 'a resource with a singular GET endpoint'
  end
end
