require 'spec_helper'

describe JIRA::Resource::User do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '1234567890abcdef01234567' }

    let(:expected_attributes) do
      {
        'id' => '1234567890abcdef01234567',
        'self' => 'http://localhost:2990/jira/rest/api/2/user?accountId=1234567890abcdef01234567',
        'name' => 'admin',
        'emailAddress' => 'admin@example.com',
        'avatarUrls' => {
          '16x16' => 'http://localhost:2990/jira/secure/useravatar?size=small&avatarId=10122',
          '48x48' => 'http://localhost:2990/jira/secure/useravatar?avatarId=10122'
        },
        'displayName' => 'admin',
        'active' => true,
        'timeZone' => 'Pacific/Auckland',
        'groups' => {
          'size' => 3,
          'items' => []
        },
        'expand' => 'groups'
      }
    end

    it_should_behave_like 'a resource'
    it_should_behave_like 'a resource with a singular GET endpoint'

    describe '#all' do
      let(:client) do
        client = double(options: { rest_base_path: '/jira/rest/api/2' })
        allow(client).to receive(:get).with('/rest/api/2/users/search?username=_&maxResults=1000').and_return(JIRA::Resource::UserFactory.new(client))
        client
      end

      before do
        allow(client).to receive(:get)
          .with('/rest/api/2/users/search?username=_&maxResults=1000') { OpenStruct.new(body: '["User1"]') }
        allow(client).to receive_message_chain(:User, :build).with('users') { [] }
      end

      it 'gets users with maxResults of 1000' do
        expect(client).to receive(:get).with('/rest/api/2/users/search?username=_&maxResults=1000')
        expect(client).to receive_message_chain(:User, :build).with('User1')
        JIRA::Resource::User.all(client)
      end
    end
  end
end
