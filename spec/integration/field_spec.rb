require 'spec_helper'

describe JIRA::Resource::Field do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '1' }

    let(:expected_attributes) do
      {
        'id' => key,
        'name' => 'Description',
        'custom' => false,
        'orderable' => true,
        'navigable' => true,
        'searchable' => true,
        'clauseNames' => ['description'],
        'schema' => {
          'type' => 'string',
          'system' => 'description'
        }
      }
    end

    let(:expected_collection_length) { 2 }

    it_behaves_like 'a resource'
    it_behaves_like 'a resource with a collection GET endpoint'
    it_behaves_like 'a resource with a singular GET endpoint'
  end
end
