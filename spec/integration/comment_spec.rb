require 'spec_helper'

describe JIRA::Resource::Comment do


  let(:client) do
    client = JIRA::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:key) { "10000" }

  let(:target) { JIRA::Resource::Comment.new(client, :attrs => {'id' => '99999'}, :issue_id => '54321') }

  let(:belongs_to) {
    JIRA::Resource::Issue.new(client, :attrs => {
      'id' => '10002', 'fields' => {
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
    {"body" => "new comment"}
  }
  let(:expected_attributes_from_post) {
    { "id" => "10001", "body" => "new comment"}
  }

  #let(:attributes_for_put) {
  #  {"name" => "Jammy", "project" => "SAMPLEPROJECT" }
  #}
  #let(:expected_attributes_from_put) {
  #  { "id" => "10000", "name" => "Jammy" }
  #}

  it_should_behave_like "a resource"
  it_should_behave_like "a resource with a singular GET endpoint"
  it_should_behave_like "a resource with a DELETE endpoint"
  it_should_behave_like "a resource with a POST endpoint"
  # it_should_behave_like "a resource with a PUT endpoint"

end
