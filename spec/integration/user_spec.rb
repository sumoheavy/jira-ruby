require 'spec_helper'

describe JIRA::Resource::User do


  let(:client) do
    client = JIRA::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:key) { "admin" }

  let(:expected_attributes) do
    {
      'self' => "http://localhost:2990/jira/rest/api/2/user?username=admin",
      'name' => key,
      'emailAddress' => 'admin@example.com'
    }
  end

  it_should_behave_like "a resource"
  it_should_behave_like "a resource with a singular GET endpoint"

end
