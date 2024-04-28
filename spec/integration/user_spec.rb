require 'spec_helper'

describe JIRA::Resource::User do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { 'admin' }

    let(:expected_attributes) do
      {
        'self' => 'http://localhost:2990/jira/rest/api/2/user?username=admin',
        'name' => key,
        'emailAddress' => 'admin@example.com'
      }
    end

    it_behaves_like 'a resource'
    it_behaves_like 'a resource with a singular GET endpoint'

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
