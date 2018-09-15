require 'spec_helper'

describe JIRA::Resource::Version do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '10000' }

    let(:expected_attributes) do
      {
        'self' => 'http://localhost:2990/jira/rest/api/2/version/10000',
        'id'   => key,
        'description' => 'Initial version'
      }
    end

    let(:attributes_for_post) do
      { 'name' => '2.0', 'project' => 'SAMPLEPROJECT' }
    end
    let(:expected_attributes_from_post) do
      { 'id' => '10001', 'name' => '2.0' }
    end

    let(:attributes_for_put) do
      { 'name' => '2.0.0' }
    end
    let(:expected_attributes_from_put) do
      { 'id' => '10000', 'name' => '2.0.0' }
    end

    it_should_behave_like 'a resource'
    it_should_behave_like 'a resource with a singular GET endpoint'
    it_should_behave_like 'a resource with a DELETE endpoint'
    it_should_behave_like 'a resource with a POST endpoint'
    it_should_behave_like 'a resource with a PUT endpoint'
    it_should_behave_like 'a resource with a PUT endpoint that rejects invalid fields'
  end
end
