require 'spec_helper'

describe JIRA::Resource::Component do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '10000' }

    let(:expected_attributes) do
      {
        'self' => 'http://localhost:2990/jira/rest/api/2/component/10000',
        'id' => key,
        'name' => 'Cheesecake'
      }
    end

    let(:attributes_for_post) do
      { 'name' => 'Test component', 'project' => 'SAMPLEPROJECT' }
    end
    let(:expected_attributes_from_post) do
      { 'id' => '10001', 'name' => 'Test component' }
    end

    let(:attributes_for_put) do
      { 'name' => 'Jammy', 'project' => 'SAMPLEPROJECT' }
    end
    let(:expected_attributes_from_put) do
      { 'id' => '10000', 'name' => 'Jammy' }
    end

    it_should_behave_like 'a resource'
    it_should_behave_like 'a resource with a singular GET endpoint'
    it_should_behave_like 'a resource with a DELETE endpoint'
    it_should_behave_like 'a resource with a POST endpoint'
    it_should_behave_like 'a resource with a PUT endpoint'
    it_should_behave_like 'a resource with a PUT endpoint that rejects invalid fields'
  end
end
