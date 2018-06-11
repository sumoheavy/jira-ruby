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

    describe "#all" do
      let(:client) do
        client = double(options: {rest_base_path: '/jira/rest/api/2'}  )
        allow(client).to receive(:User).and_return(JIRA::Resource::UserFactory.new(client))
        client
      end

      let(:project_keys1) { (0...100).to_a.join(",") }

      let(:project_keys2) { (100...200).to_a.join(",") }

      let(:project_keys3) { (200...220).to_a.join(",") }

      projects = 220.times.map.with_index do |i|
        [OpenStruct.new(key: i.to_s) , OpenStruct.new(key: i.to_s)]
      end.flatten

      before do
        allow(client).to receive_message_chain(:Project, :all) { projects }
        allow(client).to receive(:get)
          .with("/jira/rest/api/2/user/assignable/multiProjectSearch?projectKeys=#{project_keys1}&maxResults=1000") { OpenStruct.new(body: '{"users":[]}') }
        allow(client).to receive(:get)
          .with("/jira/rest/api/2/user/assignable/multiProjectSearch?projectKeys=#{project_keys2}&maxResults=1000") { OpenStruct.new(body: '{"users":[]}') }
        allow(client).to receive(:get)
          .with("/jira/rest/api/2/user/assignable/multiProjectSearch?projectKeys=#{project_keys3}&maxResults=1000") { OpenStruct.new(body: '{"users":[]}') }
        allow(client).to receive_message_chain(:User, :build).with({"users"=>[]}) { "user" }
      end

      it "splits the projects by 100 and uniqs them to get users on projects" do
        expect(client).to receive(:get).with("/jira/rest/api/2/user/assignable/multiProjectSearch?projectKeys=#{project_keys1}&maxResults=1000")
        expect(client).to receive(:get).with("/jira/rest/api/2/user/assignable/multiProjectSearch?projectKeys=#{project_keys2}&maxResults=1000")
        expect(client).to receive(:get).with("/jira/rest/api/2/user/assignable/multiProjectSearch?projectKeys=#{project_keys3}&maxResults=1000")
        JIRA::Resource::User.all(client)
      end
    end
  end
end
