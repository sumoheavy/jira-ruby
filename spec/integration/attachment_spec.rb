require 'spec_helper'

describe JIRA::Resource::Attachment do


  let(:client) do
    client = JIRA::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:key) { "10000" }

  let(:expected_attributes) do
    {
      'self' => "http://localhost:2990/jira/rest/api/2/attachment/10000",
      'size' => 15360,
      'filename' => "ballmer.png"
    }
  end

  it_should_behave_like "a resource"
  it_should_behave_like "a resource with a singular GET endpoint"
  it_should_behave_like "a resource with a DELETE endpoint"

end
