require 'spec_helper'

describe JIRA::Resource::Issue do

  class JIRAResourceDelegation < SimpleDelegator # :nodoc:
  end

  let(:client) { double(options: {rest_base_path: '/jira/rest/api/2'}) }

  describe "#respond_to?" do
    describe "when decorated by SimpleDelegator" do
      before(:each) do
        response = double()
        allow(response).to receive(:body).and_return('{"key":"foo","id":"101"}')
        allow(JIRA::Resource::Issue).to receive(:collection_path).and_return('/jira/rest/api/2/issue')
        allow(client).to receive(:get).with('/jira/rest/api/2/issue/101').
          and_return(response)

        issue = JIRA::Resource::Issue.find(client,101)
        @decorated = JIRAResourceDelegation.new( issue )
      end
      it "responds to key" do
        expect(@decorated.respond_to?(:key)).to eq(true)
      end
      it "does not raise an error" do
        expect {
          @issue.respond_to?(:project)
        }.not_to raise_error
      end
    end
  end

  it "should find all issues" do
    response = double()
    issue = double()

    allow(response).to receive(:body).and_return('{"issues":[{"id":"1","summary":"Bugs Everywhere"}]}')
    expect(client).to receive(:get).with('/jira/rest/api/2/search?expand=transitions.fields').
      and_return(response)
    expect(client).to receive(:Issue).and_return(issue)
    expect(issue).to receive(:build).with({"id"=>"1","summary"=>"Bugs Everywhere"})

    issues = JIRA::Resource::Issue.all(client)
  end

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
    expect(client).to receive(:get)
      .with('/jira/rest/api/2/search?jql=foo+bar&fields=foo,bar')
      .and_return(response)
    expect(client).to receive(:Issue).and_return(issue)
    expect(issue).to receive(:build).with(["key", "foo"]).and_return('')

    expect(JIRA::Resource::Issue.jql(client, 'foo bar', fields: ['foo','bar'])).to eq([''])
  end

  it "should search an issue with a jql query string, start at, and maxResults" do
    response = double()
    issue = double()

    allow(response).to receive(:body).and_return('{"issues": {"key":"foo"}}')
    expect(client).to receive(:get)
      .with('/jira/rest/api/2/search?jql=foo+bar&startAt=1&maxResults=3')
      .and_return(response)
    expect(client).to receive(:Issue).and_return(issue)
    expect(issue).to receive(:build).with(["key", "foo"]).and_return('')

    expect(JIRA::Resource::Issue.jql(client,'foo bar', start_at: 1, max_results: 3)).to eq([''])
  end

  it "should search an issue with a jql query string and string expand" do
    response = double()
    issue = double()

    allow(response).to receive(:body).and_return('{"issues": {"key":"foo"}}')
    expect(client).to receive(:get)
      .with('/jira/rest/api/2/search?jql=foo+bar&expand=transitions')
      .and_return(response)
    expect(client).to receive(:Issue).and_return(issue)
    expect(issue).to receive(:build).with(["key", "foo"]).and_return('')

    expect(JIRA::Resource::Issue.jql(client,'foo bar', expand: 'transitions')).to eq([''])
  end

  it "should search an issue with a jql query string and array expand" do
    response = double()
    issue = double()

    allow(response).to receive(:body).and_return('{"issues": {"key":"foo"}}')
    expect(client).to receive(:get)
      .with('/jira/rest/api/2/search?jql=foo+bar&expand=transitions')
      .and_return(response)
    expect(client).to receive(:Issue).and_return(issue)
    expect(issue).to receive(:build).with(["key", "foo"]).and_return('')

    expect(JIRA::Resource::Issue.jql(client,'foo bar', expand: %w(transitions))).to eq([''])
  end

  it 'should return meta data available for editing an issue' do
    subject = JIRA::Resource::Issue.new(client, :attrs => {'fields' => {'key' =>'TST=123'}})
    response = double()

    allow(response).to receive(:body).and_return(
      '{"fields":{"summary":{"required":true,"name":"Summary","operations":["set"]}}}'
    )
    expect(client).to receive(:get)
      .with('/jira/rest/api/2/issue/TST=123/editmeta')
      .and_return(response)

    expect(subject.editmeta).to eq({'summary' => {'required' => true, 'name' => 'Summary', 'operations' => ['set']}})
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
