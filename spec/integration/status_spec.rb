require 'spec_helper'

describe JIRA::Resource::Status do

  let(:client) do
    client = JIRA::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:key) { "1" }

  let(:expected_attributes) do
    {
      'self' => "http://localhost:2990/jira/rest/api/2/status/1",
      'id' => key,
      'name' => 'Open'
    }
  end

  let(:expected_collection_length) { 5 }

  it_should_behave_like "a resource"
  it_should_behave_like "a resource with a collection GET endpoint"
  it_should_behave_like "a resource with a singular GET endpoint"

end
