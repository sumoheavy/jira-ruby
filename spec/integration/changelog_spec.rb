require 'spec_helper'

describe JIRA::Resource::Changelog do


  let(:client) do
    client = JIRA::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  #stub_request(:get, "http://localhost:2990/jira/rest/api/2/issue/10014?expand=changelog").
  #         to_return(:status => 200, :body => get_mock_response('issue/10014.json'))

  

  it "should expand the changelog for items found through search" do

    stub_request(:get, "http://localhost:2990/jira/rest/api/2/issue/10014?expand=changelog").
           to_return(:status => 200, :body => get_mock_response('issue/10014.json'))
    stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?startAt=0").
             to_return(:status => 200, :body => get_mock_response('issue.json'))
    stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?startAt=10").
             to_return(:status => 200, :body => get_mock_response('issue.2.json'))

    subject = client.Issue.all.first
    subject.id.should == '10014'

    subject.changelog[0].id.should == '47939'
  end

end
