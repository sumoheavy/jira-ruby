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

  it "provides direct accessors to the fields" do
    subject = JIRA::Resource::Issue.new(client, :attrs => {'fields' => {'foo' =>'bar'}})
    subject.should respond_to(:foo)
    subject.foo.should == 'bar'
  end

  it "returns the reporter" do
    subject = JIRA::Resource::Issue.new(client, :attrs => {'fields' => {'reporter' => {'foo' => 'bar'}}})
    subject.reporter.class.should == JIRA::Resource::User
    subject.reporter.foo.should == 'bar'
  end

  it "returns the assignee" do
    subject = JIRA::Resource::Issue.new(client, :attrs => {'fields' => {'assignee' => {'foo' => 'bar'}}})
    subject.assignee.class.should == JIRA::Resource::User
    subject.assignee.foo.should == 'bar'
  end

  it "returns the project" do
    subject = JIRA::Resource::Issue.new(client, :attrs => {'fields' => {'project' => {'foo' => 'bar'}}})
    subject.project.class.should == JIRA::Resource::Project
    subject.project.foo.should == 'bar'
  end

  it "returns the issuetype" do
    subject = JIRA::Resource::Issue.new(client, :attrs => {'fields' => {'issuetype' => {'foo' => 'bar'}}})
    subject.issuetype.class.should == JIRA::Resource::Issuetype
    subject.issuetype.foo.should == 'bar'
  end

  it "has one priority" do
    subject = JIRA::Resource::Issue.new(client, :attrs => {'fields' => {'priority' => {'foo' => 'bar'}}})
    subject.priority.class.should == JIRA::Resource::Priority
    subject.priority.foo.should == 'bar'
  end

  it "has one status" do
    subject = JIRA::Resource::Issue.new(client, :attrs => {'fields' => {'status' => {'foo' => 'bar'}}})
    subject.status.class.should == JIRA::Resource::Status
    subject.status.foo.should == 'bar'
  end

end
