require 'spec_helper'

describe JIRA::Resource::Resolution do

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }


    let(:key) { "1" }

    let(:expected_attributes) do
      {
        'self' => "http://www.example.com/jira/rest/api/2/resolution/1",
        'id' => key,
        'name' => 'Fixed',
        'description' => 'A fix for this issue is checked into the tree and tested.', 
        'iconUrl' => 'http://www.example.com/jira/images/icons/status_resolved.gif'
      }
    end

    let(:expected_collection_length) { 2 }

    it_should_behave_like "a resource"
    it_should_behave_like "a resource with a collection GET endpoint"
    it_should_behave_like "a resource with a singular GET endpoint"

  end
end