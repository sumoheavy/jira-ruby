require 'spec_helper'

describe JIRA::Resource::Issuetype do

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { "5" }

    let(:expected_attributes) do
      {
        'self' => "http://localhost:2990/jira/rest/api/2/issuetype/5",
        'id' => key,
        'name' => 'Sub-task'
      }
    end

    let(:expected_collection_length) { 5 }

    before(:each) do
      stub_request(:get, "http://foo:bar@localhost:2990/jira/rest/api/2/issuetype")
        .with(headers: {
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Ruby'
        })
        .to_return(:status => 200, :body => '[{"self":"http://localhost:2990/jira/rest/api/2/issuetype/5","id":"5","name":"Sub-task"},{"self":"http://localhost:2990/jira/rest/api/2/issuetype/1","id":"1","name":"Bug"},{"self":"http://localhost:2990/jira/rest/api/2/issuetype/2","id":"2","name":"Task"},{"self":"http://localhost:2990/jira/rest/api/2/issuetype/3","id":"3","name":"Story"},{"self":"http://localhost:2990/jira/rest/api/2/issuetype/4","id":"4","name":"Epic"}]', :headers => {})
    end

    it_should_behave_like "a resource"
    it_should_behave_like "a resource with a collection GET endpoint"
    it_should_behave_like "a resource with a singular GET endpoint"

  end
end
