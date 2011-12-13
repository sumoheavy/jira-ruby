require 'spec_helper'

describe Jira::Resource::Component do


  let(:client) do
    client = Jira::Client.new('foo', 'bar')
    client.set_access_token('abc', '123')
    client
  end

  before(:each) do
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2/component/10000").
                 to_return(:body => get_mock_response('component/10000.json'))
    stub_request(:delete,
                 "http://localhost:2990/jira/rest/api/2/component/10000").
                 to_return(:body => nil)
  end

  it "should get a single component by id" do
    component = client.Component.find(10000)

    component.self.should == "http://localhost:2990/jira/rest/api/2/component/10000"
    component.id.should   == "10000"
    component.name.should == "Cheesecake"
  end

  it "builds and fetches single component" do
    component = client.Component.build('id' => 10000)
    component.fetch

    component.self.should   == "http://localhost:2990/jira/rest/api/2/component/10000"
    component.id.should    == "10000"
    component.name.should == "Cheesecake"
  end

  it "deletes a component" do
    component = client.Component.build('id' => "10000")
    component.delete.should be_true
  end

end
