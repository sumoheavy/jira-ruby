require 'spec_helper'

describe JIRA::Resource::Watcher do

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }


    let(:target) { JIRA::Resource::Watcher.new(client, :attrs => {'id' => '99999'}, :issue_id => '10002') }

    let(:belongs_to) {
      JIRA::Resource::Issue.new(client, :attrs => {
        'id' => '10002',
        'fields' => {
          'comment' => {'comments' => []}
        }
      })
    }

    let(:expected_attributes) do
      {
        "self" => "http://localhost:2990/jira/rest/api/2/issue/10002/watchers",
        "isWatching": false,
        "watchCount": 1,
        "watchers": [
            {
                "self": "http://www.example.com/jira/rest/api/2/user?username=admin",
                "name": "admin",
                "displayName": "admin",
                "active": false
            }
        ]
      }
    end

    describe "watchers" do
      it "should returns all the watchers" do

       stub_request(:get,
                    site_url + "/jira/rest/api/2/issue/10002").
                    to_return(:status => 200, :body => get_mock_response('issue/10002.json'))

       stub_request(:get,
                    site_url + "/jira/rest/api/2/issue/10002/watchers").
                    to_return(:status => 200, :body => get_mock_response('issue/10002/watchers.json'))

          issue = client.Issue.find("10002")
          watchers = client.Watcher.all(options = {:issue => issue})
          expect(watchers.length).to eq(1)
      end

    end

    it_should_behave_like "a resource"

  end

end
