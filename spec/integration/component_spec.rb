require 'spec_helper'

describe JIRA::Resource::Component do


  let(:client) do
    client = JIRA::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:key) { "10000" }

  let(:expected_attributes) do
    {
      'self' => "http://localhost:2990/jira/rest/api/2/component/10000",
      'id'   => key,
      'name' => "Cheesecake"
    }
  end

  let(:attributes_for_post) {
    {"name" => "Test component", "project" => "SAMPLEPROJECT" }
  }
  let(:expected_attributes_from_post) {
    { "id" => "10001", "name" => "Test component" }
  }

  let(:attributes_for_put) {
    {"name" => "Jammy", "project" => "SAMPLEPROJECT" }
  }
  let(:expected_attributes_from_put) {
    { "id" => "10000", "name" => "Jammy" }
  }

  it_should_behave_like "a resource"
  it_should_behave_like "a resource with a singular GET endpoint"
  it_should_behave_like "a resource with a DELETE endpoint"
  it_should_behave_like "a resource with a POST endpoint"
  it_should_behave_like "a resource with a PUT endpoint"

end
