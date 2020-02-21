require 'spec_helper'

describe JIRA::Resource::User do


  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }


    let(:key) { "admin" }

    let(:expected_attributes) do
      {
        'self' => "http://localhost:2990/jira/rest/api/2/user?username=admin",
        'name' => key,
        'emailAddress' => 'admin@example.com'
      }
    end

    it_should_behave_like "a resource"
    it_should_behave_like "a resource with a singular GET endpoint"
  end

  describe "#all" do
    let(:client) { JIRA::Client.new({ :username => 'foo', :password => 'bar', :auth_type => :basic, site: site }) }
    let(:base_path) { client.options[:rest_base_path] }

    before do
      allow(client).to receive_message_chain(:User, :build).with("users") { [] }
      expect(client).to receive_message_chain(:User, :build).with("User1")
    end

    context "when the client is a cloud instance" do
      let(:site) { "https://foo.atlassian.net" }

      it "gets users with maxResults of 1000" do
        allow(client).to receive(:get)
          .with("#{base_path}/user/search?query=&maxResults=1000") { OpenStruct.new(body: '["User1"]') }

        JIRA::Resource::User.all(client)
      end
    end

    context "when the client is not a cloud instance" do
      let(:site) { "https://foo.onprem.com" }

      before do
        allow(client).to receive(:get)
          .with("#{base_path}/user/search?username=@&maxResults=1000") { OpenStruct.new(body: '["User1"]') }
      end

      it "gets users with maxResults of 1000" do
        JIRA::Resource::User.all(client)
      end

      context "when there is a context path on the client" do
        let(:client) { JIRA::Client.new({ :username => 'foo', :password => 'bar', :auth_type => :basic, site: site, context_path: '/context_path' }) }

        it "applies the context path to the url" do
          JIRA::Resource::User.all(client)
        end
      end
    end
  end
end
