require 'spec_helper'

describe JIRA::Resource::Comment do

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { "10000" }

    let(:target) { JIRA::Resource::Comment.new(client, :attrs => {'id' => '99999'}, :issue_id => '54321') }

    let(:expected_collection_length) { 2 }

    let(:belongs_to) {
      JIRA::Resource::Issue.new(client, :attrs => {
        'id' => '10002',
        'fields' => {
          'comment' => {'comments' => []}
        }
      })
    }

    let(:expected_attributes) do
      {
        'self' => "http://localhost:2990/jira/rest/api/2/issue/10002/comment/10000",
        'id'   => key,
        'body' => "This is a comment. Creative."
      }
    end

    let(:attributes_for_post) {
      { "body" => "new comment" }
    }
    let(:expected_attributes_from_post) {
      { "id" => "10001", "body" => "new comment"}
    }

    let(:attributes_for_put) {
      {"body" => "new body"}
    }
    let(:expected_attributes_from_put) {
      { "id" => "10000", "body" => "new body" }
    }
    before(:each) do
      stub_request(:get, "http://foo:bar@localhost:2990/jira/rest/api/2/comment")
        .with(headers: {
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Ruby'
        })
        .to_return(:status => 200, :body => '{"comments":[{"self":"http://localhost:2990/jira/rest/api/2/issue/10002/comment/10000","id":"10000","body":"This is a comment. Creative."},{"self":"http://localhost:2990/jira/rest/api/2/issue/10002/comment/10001","id":"10001","body":"Another comment."}]}', :headers => {})
    end
    it_should_behave_like "a resource"
    it_should_behave_like "a resource with a collection GET endpoint"
    it_should_behave_like "a resource with a singular GET endpoint"
    it_should_behave_like "a resource with a DELETE endpoint"
    it_should_behave_like "a resource with a POST endpoint"
    it_should_behave_like "a resource with a PUT endpoint"

  end

end
