require 'spec_helper'

describe JIRA::Resource::Project do

  let(:client) do
    client = JIRA::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:key) { "SAMPLEPROJECT" }

  let(:expected_attributes) do
    {
      'self'   => "http://localhost:2990/jira/rest/api/2/project/SAMPLEPROJECT",
      'key'    => key,
      'name'   => "Sample Project for Developing RoR RESTful API"
    }
  end

  it_should_behave_like "a resource"
  it_should_behave_like "a resource with a collection GET endpoint"
  it_should_behave_like "a resource with a singular GET endpoint"
end
