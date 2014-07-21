require 'spec_helper'

describe JIRA::Resource::Issue do

  let(:client) { double(options: {rest_base_path: '/jira/rest/api/2'}) }

  it "should find an issue by key or id" do
    response = double()
    allow(response).to receive(:body).and_return('{"key":"foo","id":"101"}')
    allow(JIRA::Resource::Issue).to receive(:collection_path).and_return('/jira/rest/api/2/issue')
    expect(client).to receive(:get).with('/jira/rest/api/2/issue/foo').
      and_return(response)
    expect(client).to receive(:get).with('/jira/rest/api/2/issue/101').
      and_return(response)

    issue_from_id = JIRA::Resource::Issue.find(client,101)
    issue_from_key = JIRA::Resource::Issue.find(client,'foo')

    expect(issue_from_id.attrs).to eq(issue_from_key.attrs)
  end

  it "should search an issue with a jql query string" do
    response = double()
    issue = double()
    allow(response).to receive(:body).and_return('{"issues": {"key":"foo"}}')
    expect(client).to receive(:get).with('/jira/rest/api/2/search?jql=foo+bar').
      and_return(response)
    expect(client).to receive(:Issue).and_return(issue)
    expect(issue).to receive(:build).with(["key", "foo"]).and_return('')

    expect(JIRA::Resource::Issue.jql(client,'foo bar')).to eq([''])
  end

  it "should search an issue with a jql query string and fields" do
    response = double()
    issue = double()
    allow(response).to receive(:body).and_return('{"issues": {"key":"foo"}}')
    expect(client).to receive(:get).with('/jira/rest/api/2/search?jql=foo+bar%26fields%3Dfoo%2Cbar').
      and_return(response)
    expect(client).to receive(:Issue).and_return(issue)
    expect(issue).to receive(:build).with(["key", "foo"]).and_return('')

    expect(JIRA::Resource::Issue.jql(client,'foo bar',['foo','bar'])).to eq([''])
  end

  it "provides direct accessors to the fields" do
    subject = JIRA::Resource::Issue.new(client, :attrs => {'fields' => {'foo' =>'bar'}})
    expect(subject).to respond_to(:foo)
    expect(subject.foo).to eq('bar')
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
      expect(subject).to have_one(:reporter, JIRA::Resource::User)
      expect(subject.reporter.foo).to eq('bar')

      expect(subject).to have_one(:assignee, JIRA::Resource::User)
      expect(subject.assignee.foo).to eq('bar')

      expect(subject).to have_one(:project, JIRA::Resource::Project)
      expect(subject.project.foo).to eq('bar')

      expect(subject).to have_one(:issuetype, JIRA::Resource::Issuetype)
      expect(subject.issuetype.foo).to eq('bar')

      expect(subject).to have_one(:priority, JIRA::Resource::Priority)
      expect(subject.priority.foo).to eq('bar')

      expect(subject).to have_one(:status, JIRA::Resource::Status)
      expect(subject.status.foo).to eq('bar')

      expect(subject).to have_many(:components, JIRA::Resource::Component)
      expect(subject.components.length).to eq(2)

      expect(subject).to have_many(:comments, JIRA::Resource::Comment)
      expect(subject.comments.length).to eq(2)

      expect(subject).to have_many(:attachments, JIRA::Resource::Attachment)
      expect(subject.attachments.length).to eq(2)

      expect(subject).to have_many(:versions, JIRA::Resource::Version)
      expect(subject.attachments.length).to eq(2)

      expect(subject).to have_many(:worklogs, JIRA::Resource::Worklog)
      expect(subject.worklogs.length).to eq(2)
    end
  end
end
