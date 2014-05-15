require 'spec_helper'

describe JIRA::Resource::Issue do

  let(:client) { double(options: {rest_base_path: '/jira/rest/api/2'}) }

  it "should find an issue by key or id" do
    response = double()
    response.stub(:body).and_return('{"key":"foo","id":"101"}')
    JIRA::Resource::Issue.stub(:collection_path).and_return('/jira/rest/api/2/issue')
    client.should_receive(:get).with('/jira/rest/api/2/issue/foo').
      and_return(response)
    client.should_receive(:get).with('/jira/rest/api/2/issue/101').
      and_return(response)

    issue_from_id = JIRA::Resource::Issue.find(client,101)
    issue_from_key = JIRA::Resource::Issue.find(client,'foo')

    issue_from_id.attrs.should == issue_from_key.attrs
  end

  it "should search an issue with a jql query string" do
    response = double()
    issue = double()
    response.stub(:body).and_return('{"issues": {"key":"foo"}}')
    client.should_receive(:get).with('/jira/rest/api/2/search?jql=foo+bar&startAt=0&maxResults=50').
      and_return(response)
    client.should_receive(:Issue).and_return(issue)
    issue.should_receive(:build).with(["key", "foo"]).and_return('')

    JIRA::Resource::Issue.jql(client,'foo bar').should == ['']
  end

  it "should search an issue with a jql query string and fields" do
    response = double()
    issue = double()
    response.stub(:body).and_return('{"issues": {"key":"foo"}}')
    client.should_receive(:get).with('/jira/rest/api/2/search?jql=foo+bar&startAt=0&maxResults=50%26fields%3Dfoo%2Cbar').
      and_return(response)
    client.should_receive(:Issue).and_return(issue)
    issue.should_receive(:build).with(["key", "foo"]).and_return('')

    JIRA::Resource::Issue.jql(client,'foo bar',['foo','bar']).should == ['']
  end

  it "should search an issue with a jql query string, start at, and maxResults" do
    response = double()
    issue = double()
    response.stub(:body).and_return('{"issues": {"key":"foo"}}')
    client.should_receive(:get).with('/jira/rest/api/2/search?jql=foo+bar&startAt=1&maxResults=3').
      and_return(response)
    client.should_receive(:Issue).and_return(issue)
    issue.should_receive(:build).with(["key", "foo"]).and_return('')

    JIRA::Resource::Issue.jql(client,'foo bar', nil, 1, 3).should == ['']
  end

  it "provides direct accessors to the fields" do
    subject = JIRA::Resource::Issue.new(client, :attrs => {'fields' => {'foo' =>'bar'}})
    subject.should respond_to(:foo)
    subject.foo.should == 'bar'
  end

  describe "relationships" do
    subject {
      JIRA::Resource::Issue.new(client, :attrs => {
        'id' => '123',
        'fields' => {
          'reporter'    => {'foo' => 'bar'},
          'assignee'    => {'foo' => 'bar'},
          'project'     => {'foo' => 'bar'},
          'priority'    => {'foo' => 'bar'},
          'issuetype'   => {'foo' => 'bar'},
          'status'      => {'foo' => 'bar'},
          'components'  => [{'foo' => 'bar'}, {'baz' => 'flum'}],
          'versions'    => [{'foo' => 'bar'}, {'baz' => 'flum'}],
          'comment'     => { 'comments' => [{'foo' => 'bar'}, {'baz' => 'flum'}]},
          'attachment'  => [{'foo' => 'bar'}, {'baz' => 'flum'}],
          'worklog'     => { 'worklogs' => [{'foo' => 'bar'}, {'baz' => 'flum'}]},
        }
      })
    }

    it "has the correct relationships" do
      subject.should have_one(:reporter, JIRA::Resource::User)
      subject.reporter.foo.should == 'bar'

      subject.should have_one(:assignee, JIRA::Resource::User)
      subject.assignee.foo.should == 'bar'

      subject.should have_one(:project, JIRA::Resource::Project)
      subject.project.foo.should == 'bar'

      subject.should have_one(:issuetype, JIRA::Resource::Issuetype)
      subject.issuetype.foo.should == 'bar'

      subject.should have_one(:priority, JIRA::Resource::Priority)
      subject.priority.foo.should == 'bar'

      subject.should have_one(:status, JIRA::Resource::Status)
      subject.status.foo.should == 'bar'

      subject.should have_many(:components, JIRA::Resource::Component)
      subject.components.length.should == 2

      subject.should have_many(:comments, JIRA::Resource::Comment)
      subject.comments.length.should == 2

      subject.should have_many(:attachments, JIRA::Resource::Attachment)
      subject.attachments.length.should == 2

      subject.should have_many(:versions, JIRA::Resource::Version)
      subject.attachments.length.should == 2

      subject.should have_many(:worklogs, JIRA::Resource::Worklog)
      subject.worklogs.length.should == 2
    end
  end
end
