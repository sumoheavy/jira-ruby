require 'spec_helper'

describe JIRA::Resource::Component do


  let(:client) do
    client = JIRA::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  let(:key) { "10000" }

  let(:expected_attributes) do
    {
      'self' => "http://localhost:2990/jira/rest/api/2/component/10000",
      'id'   => key,
      'name' => "Cheesecake"
    }
  end

  before(:each) do
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2/component/10000").
                 to_return(:status => 200,:body => get_mock_response('component/10000.json'))
    stub_request(:delete,
                 "http://localhost:2990/jira/rest/api/2/component/10000").
                 to_return(:status => 204, :body => nil)
    stub_request(:post,
                 "http://localhost:2990/jira/rest/api/2/component").
                 with(:body => '{"name":"Test component","project":"SAMPLEPROJECT"}').
                 to_return(:status => 201, :body => get_mock_response('component.post.json'))
    stub_request(:put,
                 "http://localhost:2990/jira/rest/api/2/component/10000").
                 with(:body => '{"name":"Jammy"}').
                 to_return(:status => 200, :body => get_mock_response('component/10000.put.json'))
    stub_request(:put,
                 "http://localhost:2990/jira/rest/api/2/component/10000").
                 with(:body => '{"invalid":"field"}').
                 to_return(:status => 400, :body => get_mock_response('component/10000.put.invalid.json'))
  end

  it_should_behave_like "a resource with a singular GET endpoint"

  it "builds and fetches single component" do
    component = client.Component.build('id' => 10000)
    component.fetch

    component.should have_attributes(expected_attributes)
  end

  it "deletes a component" do
    component = client.Component.build('id' => "10000")
    component.delete.should be_true
  end

  it "saves a new component" do
    component = client.Component.build
    component.save({"name" => "Test component", "project" => "SAMPLEPROJECT"}).should be_true
    component.id.should   == "10001"
    component.name.should == "Test component"
  end

  it "saves an existing component" do
    component = client.Component.build('id' => '10000')
    component.fetch
    component.save('name' => 'Jammy').should be_true
    component.id.should == "10000"
    component.name.should == "Jammy"
  end

  it "fails to save a component with an invalid field" do
    component = client.Component.build('id' => '10000')
    component.fetch
    component.save('invalid' => 'field').should be_false
  end

  it "throws an exception when save! fails" do
    component = client.Component.build('id' => '10000')
    component.fetch
    lambda do
      component.save!('invalid' => 'field')
    end.should raise_error(JIRA::Resource::HTTPError)
  end

end
