require 'spec_helper'

describe JIRA::Resource::Watcher do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:target) { described_class.new(client, attrs: { 'id' => '99999' }, issue_id: '10002') }

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
        'self' => 'http://localhost:2990/jira/rest/api/2/issue/10002/watchers',
        isWatching: false,
        watchCount: 1,
        watchers: [
          {
            self: 'http://www.example.com/jira/rest/api/2/user?username=admin',
            name: 'admin',
            displayName: 'admin',
            active: false
          }
        ]
      }
    end

    describe 'watchers' do
      before do
        stub_request(:get, "#{site_url}/jira/rest/api/2/issue/10002")
          .to_return(status: 200, body: get_mock_response('issue/10002.json'))

        stub_request(:get, "#{site_url}/jira/rest/api/2/issue/10002/watchers")
          .to_return(status: 200, body: get_mock_response('issue/10002/watchers.json'))

        stub_request(:post, "#{site_url}/jira/rest/api/2/issue/10002/watchers")
          .to_return(status: 204, body: nil)
      end

      it 'returnses all the watchers' do
        issue = client.Issue.find('10002')
        watchers = client.Watcher.all({ issue: })
        expect(watchers.length).to eq(1)
      end

      it 'adds a watcher' do
        issue = client.Issue.find('10002')
        watcher = described_class.new(client, issue:)
        user_id = 'tester'
        watcher.save!(user_id)
      end
    end
  end
end
