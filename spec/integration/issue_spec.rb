require 'spec_helper'

describe Jira::Resource::Issue do

  let(:client) do
    client = Jira::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:expected_attributes) do
    {
      'self'   => "http://localhost:2990/jira/rest/api/2/issue/10002",
      'key'    => "SAMPLEPROJECT-1",
      'expand' => "renderedFields,names,schema,transitions,editmeta,changelog"
    }
  end

  before(:each) do
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2/issue/10002").
                 to_return(:body => get_mock_response('issue/10002.json'))
    stub_request(:delete,
                 "http://localhost:2990/jira/rest/api/2/issue/10002").
                 to_return(:body => nil)
    stub_request(:post, "http://localhost:2990/jira/rest/api/2/issue").
                 to_return(:body => get_mock_response('issue.post.json'))
    stub_request(:put, "http://localhost:2990/jira/rest/api/2/issue/10002").
                 to_return(:body => nil)
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2/issue/99999").
                 to_return(:status => 404, :body => '{"errorMessages":["Issue Does Not Exist"],"errors": {}}')
  end

  it "should get a single issue by key" do
    issue = client.Issue.find('10002')

    issue.should have_attributes(expected_attributes)
  end

  it "should handle issue not found" do
    lambda do
      issue = client.Issue.find('99999')
    end.should raise_exception(Jira::Resource::HTTPError)
  end

  it "builds and fetches single issue" do
    issue = client.Issue.build('id' => '10002')
    issue.fetch

    issue.should have_attributes(expected_attributes)
  end

  it "deletes an issue" do
    issue = client.Issue.build('id' => "10002")
    issue.delete.should be_true
  end

  it "should save a new record" do
    subject = described_class.new(client)
    subject.save.should be_true
  end

  it "should save an existing record" do
    subject = client.Issue.build('id' => '10002')
    subject.fetch
    subject.save.should be_true
  end

end
