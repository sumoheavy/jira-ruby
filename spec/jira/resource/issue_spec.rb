require 'spec_helper'

describe JIRA::Resource::Issue do

  let(:client) { mock() }

  it "should find an issue by key or id" do
    response = mock()
    response.stub(:body).and_return('{"key":"foo","id":"101"}')
    JIRA::Resource::Issue.stub(:rest_base_path).and_return('/jira/rest/api/2/issue')
    client.should_receive(:get).with('/jira/rest/api/2/issue/foo')
    .and_return(response)
    client.should_receive(:get).with('/jira/rest/api/2/issue/101')
    .and_return(response)

    issue_from_id = JIRA::Resource::Issue.find(client,101)
    issue_from_key = JIRA::Resource::Issue.find(client,'foo')

    issue_from_id.attrs.should == issue_from_key.attrs
  end

end
