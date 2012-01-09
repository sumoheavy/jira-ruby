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

  it_should_behave_like "a resource"
  it_should_behave_like "a resource with a singular GET endpoint"
  it_should_behave_like "a resource with a DELETE endpoint"
  it_should_behave_like "a resource with a POST endpoint"
  it_should_behave_like "a resource with a PUT endpoint"

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
