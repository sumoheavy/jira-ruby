require 'spec_helper'

describe JIRA::Resource::User do

  let(:client) {
    instance_double('Client', options: { rest_base_path: '/jira/rest/api/2' })
  }

  describe '#search' do
    let(:response) {
      instance_double('Response', body: '[' + get_mock_response('user_username=admin.json') + ']')
    }

    let(:users) { JIRA::Resource::User.search(client, 'admin@example.com') }
    let(:user) { users.first }

    before(:each) do
      allow(client).to receive(:get).with(
        '/jira/rest/api/2/user/search?username=admin@example.com'
      ).and_return(response)
    end

    it 'returns a list with a user to search for' do
      expect(client).to receive(:get).with('/jira/rest/api/2/user/search?username=admin@example.com').and_return(response)
      expect(JIRA::Resource::User).to receive(:search_path).and_return('/jira/rest/api/2/user/search?username=admin@example.com')
      expect(users.length).to eq 1
      expect(user).to be_a(JIRA::Resource::User)
      expect(user.name).to eq('admin')
      expect(user.emailAddress).to eq('admin@example.com')
      expect(user.expanded?).to be_falsey
    end
  end
end
