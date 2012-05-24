require 'spec_helper'

describe JIRA::Resource::Issue do

  let(:client) do
    client = JIRA::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:key) { "10002" }

  let(:expected_attributes) do
    {
      'self'   => "http://localhost:2990/jira/rest/api/2/issue/10002",
      'key'    => "SAMPLEPROJECT-1",
      'expand' => "renderedFields,names,schema,transitions,editmeta,changelog"
    }
  end

  let(:attributes_for_post) {
    { 'foo' => 'bar' }
  }
  let(:expected_attributes_from_post) {
    { "id" => "10005", "key" => "SAMPLEPROJECT-4" }
  }

  let(:attributes_for_put) {
    { 'foo' => 'bar' }
  }
  let(:expected_attributes_from_put) {
    { 'foo' => 'bar' }
  }
  let(:expected_collection_length) { 11 }

  it_should_behave_like "a resource"
  it_should_behave_like "a resource with a singular GET endpoint"
  describe "GET all issues" do # JIRA::Resource::Issue.all uses the search endpoint
    let(:expected_attributes) {
      {
        "id"=>"10014",
        "self"=>"http://localhost:2990/jira/rest/api/2/issue/10014",
        "key"=>"SAMPLEPROJECT-13"
      }
    }
    before(:each) do
      stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?startAt=0").
                  to_return(:status => 200, :body => get_mock_response('issue.json'))
      stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?startAt=10").
                  to_return(:status => 200, :body => get_mock_response('issue.2.json'))
    end
    it_should_behave_like "a resource with a collection GET endpoint"
  end

  describe "GET issues from search" do
    let(:query) { "assignee = 'admin'" }

    let(:expected_attributes) {
      {
        "id"=>"10014",
        "self"=>"http://localhost:2990/jira/rest/api/2/issue/10014",
        "key"=>"SAMPLEPROJECT-13"
      }
    } 

    it "should get the collection" do
      stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?jql=" + URI.escape(query) + "&startAt=0").
                   to_return(:status => 200, :body => get_mock_response('issue.json'))
      stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?jql=" + URI.escape(query) + "&startAt=10").
                   to_return(:status => 200, :body => get_mock_response('issue.2.json'))
      collection = build_receiver.all(query)
      collection.length.should == expected_collection_length

      first = collection.first
      first.should have_attributes(expected_attributes)

    end

    it "should expand an item when needed" do
      stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?jql=" + URI.escape(query) + "&startAt=0").
                   to_return(:status => 200, :body => get_mock_response('issue.json'))
      stub_request(:get, "http://localhost:2990/jira/rest/api/2/search?jql=" + URI.escape(query) + "&startAt=10").
                   to_return(:status => 200, :body => get_mock_response('issue.2.json'))
      collection = build_receiver.all(query)
      collection.length.should == expected_collection_length

      first = collection.first

      stub_request(:get, "http://localhost:2990/jira/rest/api/2/issue/10014?expand=changelog").
                 to_return(:status => 200, :body => get_mock_response('issue/10014.json'))
      first.changelog.length.should == 2
    end

  end

  it "should provide a search interface" do
    JIRA::Resource::Issue.build_search_uri(client, "assignee = 'admin'", 0).should == "/jira/rest/api/2/search?startAt=0&jql=assignee%20=%20'admin'"
    JIRA::Resource::Issue.build_search_uri(client, nil, 0).should == "/jira/rest/api/2/search?startAt=0"
  end

  it_should_behave_like "a resource with a DELETE endpoint"
  it_should_behave_like "a resource with a POST endpoint"
  it_should_behave_like "a resource with a PUT endpoint"
  it_should_behave_like "a resource with a PUT endpoint that rejects invalid fields"

  describe "errors" do
    before(:each) do
      stub_request(:get,
                  "http://localhost:2990/jira/rest/api/2/issue/10002").
                  to_return(:status => 200, :body => get_mock_response('issue/10002.json'))
      stub_request(:put, "http://localhost:2990/jira/rest/api/2/issue/10002").
                  with(:body => '{"missing":"fields and update"}').
                  to_return(:status => 400, :body => get_mock_response('issue/10002.put.missing_field_update.json'))
    end

    it "fails to save when fields and update are missing" do
      subject = client.Issue.build('id' => '10002')
      subject.fetch
      subject.save('missing' => 'fields and update').should be_false
    end

  end

end
