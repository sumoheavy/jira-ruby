require 'spec_helper'

describe JIRA::Resource::Issue do

  let(:client) do
    client = JIRA::Client.new('foo', 'bar')
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
                 to_return(:status => 200, :body => get_mock_response('issue/10002.json'))
    stub_request(:delete,
                 "http://localhost:2990/jira/rest/api/2/issue/10002").
                 to_return(:status => 204, :body => nil)
    stub_request(:post, "http://localhost:2990/jira/rest/api/2/issue").
                 with(:body => '{"foo":"bar"}').
                 to_return(:status => 201, :body => get_mock_response('issue.post.json'))
    stub_request(:put, "http://localhost:2990/jira/rest/api/2/issue/10002").
                 with(:body => '{"foo":"bar"}').
                 to_return(:status => 204, :body => nil)
    stub_request(:put, "http://localhost:2990/jira/rest/api/2/issue/10002").
                 with(:body => '{"fields":{"invalid":"field"}}').
                 to_return(:status => 400, :body => get_mock_response('issue/10002.put.invalid.json'))
    stub_request(:put, "http://localhost:2990/jira/rest/api/2/issue/10002").
                 with(:body => '{"missing":"fields and update"}').
                 to_return(:status => 400, :body => get_mock_response('issue/10002.put.missing_field_update.json'))
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
    end.should raise_exception(JIRA::Resource::HTTPError)
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
    subject.save('foo' => 'bar').should be_true
  end

  it "should save an existing record" do
    subject = client.Issue.build('id' => '10002')
    subject.fetch
    subject.save('foo' => 'bar').should be_true
  end

  it "fails to save with an invalid field" do
    subject = client.Issue.build('id' => '10002')
    subject.fetch
    subject.save('fields'=> {'invalid' => 'field'}).should be_false
  end

  it "fails to save when fields and update are missing" do
    subject = client.Issue.build('id' => '10002')
    subject.fetch
    subject.save('missing' => 'fields and update').should be_false
  end

  it "throws an exception when save! fails" do
    subject = client.Issue.build('id' => '10002')
    subject.fetch
    lambda do
      subject.save!('missing' => 'fields and update')
    end.should raise_error(JIRA::Resource::HTTPError)
  end

end
