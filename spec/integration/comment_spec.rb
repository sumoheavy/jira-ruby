require 'spec_helper'

describe JIRA::Resource::Comment do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '10000' }

    let(:target) { JIRA::Resource::Comment.new(client, attrs: { 'id' => '99999' }, issue_id: '54321') }

    let(:expected_collection_length) { 2 }

    let(:belongs_to) do
      JIRA::Resource::Issue.new(client, attrs: {
                                  'id' => '10002',
                                  'fields' => {
                                    'comment' => { 'comments' => [] }
                                  }
                                })
    end

    let(:expected_attributes) do
      {
        'self' => 'http://localhost:2990/jira/rest/api/2/issue/10002/comment/10000',
        'id' => key,
        'body' => 'This is a comment. Creative.'
      }
    end

    let(:attributes_for_post) do
      { 'body' => 'new comment' }
    end
    let(:expected_attributes_from_post) do
      { 'id' => '10001', 'body' => 'new comment' }
    end

    let(:attributes_for_put) do
      { 'body' => 'new body' }
    end
    let(:expected_attributes_from_put) do
      { 'id' => '10000', 'body' => 'new body' }
    end

    it_should_behave_like 'a resource'
    it_should_behave_like 'a resource with a collection GET endpoint'
    it_should_behave_like 'a resource with a singular GET endpoint'
    it_should_behave_like 'a resource with a DELETE endpoint'
    it_should_behave_like 'a resource with a POST endpoint'
    it_should_behave_like 'a resource with a PUT endpoint'
  end
end
