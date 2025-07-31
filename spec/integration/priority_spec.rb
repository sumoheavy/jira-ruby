require 'spec_helper'

describe JIRA::Resource::Priority do

  before(:each) do
    stub_request(:get, "http://foo:bar@localhost:2990/jira/rest/api/2/priority")
      .with(headers: {
        'Accept'=>'application/json',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'User-Agent'=>'Ruby'
      })
      .to_return(:status => 200, :body => '[{"self":"http://localhost:2990/jira/rest/api/2/priority/1","id":"1","name":"Blocker"},{"self":"http://localhost:2990/jira/rest/api/2/priority/2","id":"2","name":"Critical"},{"self":"http://localhost:2990/jira/rest/api/2/priority/3","id":"3","name":"Major"},{"self":"http://localhost:2990/jira/rest/api/2/priority/4","id":"4","name":"Minor"},{"self":"http://localhost:2990/jira/rest/api/2/priority/5","id":"5","name":"Trivial"}]', :headers => {})
  end

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }


    let(:key) { "1" }

    let(:expected_attributes) do
      {
        'self' => "http://localhost:2990/jira/rest/api/2/priority/1",
        'id' => key,
        'name' => 'Blocker'
      }
    end

    let(:expected_collection_length) { 5 }

    it_should_behave_like "a resource"
    it_should_behave_like "a resource with a collection GET endpoint"
    it_should_behave_like "a resource with a singular GET endpoint"

  end
end
