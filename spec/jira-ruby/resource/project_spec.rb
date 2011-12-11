require 'spec_helper'

describe JiraRuby::Resource::Project do

  let(:client)  { mock() }
  let(:attrs)   { mock() }

  subject { JiraRuby::Resource::Project.new(client, attrs) }

  it "assigns the client and attrs" do
    subject.client.should == client
    subject.attrs.should  == attrs
  end

  it "returns all the projects" do
    response = mock()
    response.should_receive(:body).and_return('[{"self":"http://foo/","key":"FOO"}]')
    client.should_receive(:get).with('/jira/rest/api/2.0.alpha1/project').and_return(response)
    JiraRuby::Resource::Project.all(client).should == []
  end
end
