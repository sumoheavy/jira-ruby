require 'spec_helper'

describe JIRA::Resource::User do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { 'admin' }

    let(:expected_attributes) do
      {
        'self' => 'http://localhost:2990/jira/rest/api/2/user?username=admin',
        'name' => key,
        'emailAddress' => 'admin@example.com'
      }
    end

    it_should_behave_like 'a resource'
    it_should_behave_like 'a resource with a singular GET endpoint'
  end
end
