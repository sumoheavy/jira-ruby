require 'spec_helper'

describe JIRA::Resource::UserFactory do

  let(:client) {
    instance_double('Client', options: { rest_base_path: '/jira/rest/api/2' })
  }

  subject { JIRA::Resource::UserFactory.new(client) }

  describe "#myself" do
    let(:response) {
      instance_double(
        'Response', body: get_mock_response('user_username=admin.json')
      )
    }

    let(:user) { subject.myself }

    before(:each) do
      allow(client).to receive(:get).with(
        '/jira/rest/api/2/myself'
      ).and_return(response)
    end

    it "returns a JIRA::Resource::User with correct attrs" do
      expect(user).to be_a(JIRA::Resource::User)
      expect(user.name).to eq('admin')
      expect(user.emailAddress).to eq('admin@example.com')
    end
  end

  describe 'proxy' do
    it "proxies search path to the target class" do
      expect(JIRA::Resource::User).to receive(:search_path).with(client, 'FOO')
      subject.search_path('FOO')
    end

    it "proxies search to the target class" do
      expect(JIRA::Resource::User).to receive(:search).with(client, 'FOO')
      subject.search('FOO')
    end
  end

end
