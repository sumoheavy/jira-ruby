require 'spec_helper'

describe JIRA::Resource::UserFactory do
  let(:client) do
    instance_double('Client', options: { rest_base_path: '/jira/rest/api/2' })
  end

  subject { JIRA::Resource::UserFactory.new(client) }

  describe '#myself' do
    let(:response) do
      instance_double(
        'Response', body: get_mock_response('user_accountId=1234567890abcdef01234567.json')
      )
    end

    let(:user) { subject.myself }

    before(:each) do
      allow(client).to receive(:get).with(
        '/jira/rest/api/2/myself'
      ).and_return(response)
    end

    it 'returns a JIRA::Resource::User with correct attrs' do
      expect(user).to be_a(JIRA::Resource::User)
      expect(user.name).to eq('admin')
      expect(user.emailAddress).to eq('admin@example.com')
    end
  end
end
