require 'spec_helper'

describe JIRA::Resource::Worklog do

  before(:each) do
    stub_request(:get, "http://foo:bar@localhost:2990/jira/rest/api/2/worklog")
      .with(headers: {
        'Accept'=>'application/json',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'User-Agent'=>'Ruby'
      })
      .to_return(:status => 200, :body => '{"worklogs":[{"self":"http://localhost:2990/jira/rest/api/2/issue/10002/worklog/10000","id":"10000","comment":"Some epic work."},{"self":"http://localhost:2990/jira/rest/api/2/issue/10002/worklog/10001","id":"10001","comment":"Another worklog."},{"self":"http://localhost:2990/jira/rest/api/2/issue/10002/worklog/10002","id":"10002","comment":"More work."}]}', :headers => {})
  end


  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }


    let(:key) { "10000" }

    let(:target) { JIRA::Resource::Worklog.new(client, :attrs => {'id' => '99999'}, :issue_id => '54321') }

    let(:expected_collection_length) { 3 }

    let(:belongs_to) {
      JIRA::Resource::Issue.new(client, :attrs => {
        'id' => '10002', 'fields' => {
          'comment' => {'comments' => []}
        }
      })
    }

    let(:expected_attributes) do
      {
        'self' => "http://localhost:2990/jira/rest/api/2/issue/10002/worklog/10000",
        'id'   => key,
        'comment' => "Some epic work."
      }
    end

    let(:attributes_for_post) {
      {"timeSpent" => "2d"}
    }
    let(:expected_attributes_from_post) {
      { "id" => "10001", "timeSpent" => "2d"}
    }

    let(:attributes_for_put) {
      {"timeSpent" => "2d"}
    }
    let(:expected_attributes_from_put) {
      { "id" => "10001", "timeSpent" => "4d"}
    }

    it_should_behave_like "a resource"
    it_should_behave_like "a resource with a collection GET endpoint"
    it_should_behave_like "a resource with a singular GET endpoint"
    it_should_behave_like "a resource with a DELETE endpoint"
    it_should_behave_like "a resource with a POST endpoint"
    it_should_behave_like "a resource with a PUT endpoint"

  end
end
