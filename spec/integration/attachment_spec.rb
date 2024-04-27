require 'spec_helper'

describe JIRA::Resource::Attachment do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '10000' }

    let(:target) { JIRA::Resource::Attachment.new(client, attrs: { 'id' => '99999' }, issue_id: '10002') }

    let(:expected_attributes) do
      {
        'self' => 'http://localhost:2990/jira/rest/api/2/attachment/10000',
        'size' => 15_360,
        'filename' => 'ballmer.png'
      }
    end

    let(:belongs_to) do
      JIRA::Resource::Issue.new(client, attrs: {
                                  'id' => '10002',
                                  'fields' => {
                                    'attachment' => { 'attachments' => [] }
                                  }
                                })
    end

    it_should_behave_like 'a resource with a singular GET endpoint'
    it_should_behave_like 'a resource with a DELETE endpoint'
  end
end
