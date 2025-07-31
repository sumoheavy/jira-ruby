require 'spec_helper'

describe JIRA::Resource::Status do

  before(:each) do
    stub_request(:get, "http://foo:bar@localhost:2990/jira/rest/api/2/status")
      .with(headers: {
        'Accept'=>'application/json',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'User-Agent'=>'Ruby'
      })
      .to_return(:status => 200, :body => '[{"self":"http://localhost:2990/jira/rest/api/2/status/1","id":"1","name":"Open"},{"self":"http://localhost:2990/jira/rest/api/2/status/2","id":"2","name":"In Progress"},{"self":"http://localhost:2990/jira/rest/api/2/status/3","id":"3","name":"Resolved"},{"self":"http://localhost:2990/jira/rest/api/2/status/4","id":"4","name":"Closed"},{"self":"http://localhost:2990/jira/rest/api/2/status/5","id":"5","name":"Reopened"}]', :headers => {})
  end

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }


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
end
