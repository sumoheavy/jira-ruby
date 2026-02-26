require 'spec_helper'

describe JIRA::Resource::Issue do
  class JIRAResourceDelegation < SimpleDelegator # :nodoc:
  end

  let(:client) do
    client = double(options: { rest_base_path: '/jira/rest/api/2' })
    allow(client).to receive(:Field).and_return(JIRA::Resource::FieldFactory.new(client))
    allow(client).to receive(:field_map_cache).and_return(nil)
    client
  end

  describe '#respond_to?' do
    describe 'when decorated by SimpleDelegator' do
      before do
        response = double
        allow(response).to receive(:body).and_return('{"key":"foo","id":"101"}')
        allow(described_class).to receive(:collection_path).and_return('/jira/rest/api/2/issue')
        allow(client).to receive(:get).with('/jira/rest/api/2/issue/101')
                                      .and_return(response)

        issue = described_class.find(client, 101)
        @decorated = JIRAResourceDelegation.new(issue)
      end

      it 'responds to key' do
        expect(@decorated.respond_to?(:key)).to be(true)
      end

      it 'does not raise an error' do
        expect do
          @issue.respond_to?(:project)
        end.not_to raise_error
      end
    end
  end

  it 'finds all issues' do
    response = double
    empty_response = double
    issue = double

    allow(response).to receive(:body).and_return('{"issues":[{"id":"1","summary":"Bugs Everywhere"}]}')
    expect(client).to receive(:get).with('/jira/rest/api/2/search/jql?expand=transitions.fields&maxResults=1000&startAt=0')
                                   .and_return(response)
    allow(empty_response).to receive(:body).and_return('{"issues":[]}')
    expect(client).to receive(:get).with('/jira/rest/api/2/search/jql?expand=transitions.fields&maxResults=1000&startAt=1')
                                   .and_return(empty_response)

    expect(client).to receive(:Issue).and_return(issue)
    expect(issue).to receive(:build).with({ 'id' => '1', 'summary' => 'Bugs Everywhere' })

    described_class.all(client)
  end

  it 'finds an issue by key or id' do
    response = double

    allow(response).to receive(:body).and_return('{"key":"foo","id":"101"}')
    allow(described_class).to receive(:collection_path).and_return('/jira/rest/api/2/issue')
    expect(client).to receive(:get).with('/jira/rest/api/2/issue/foo')
                                   .and_return(response)
    expect(client).to receive(:get).with('/jira/rest/api/2/issue/101')
                                   .and_return(response)

    issue_from_id = described_class.find(client, 101)
    issue_from_key = described_class.find(client, 'foo')

    expect(issue_from_id.attrs).to eq(issue_from_key.attrs)
  end

  describe '.jql' do
    subject { described_class.jql(client, 'foo bar', args) }

    let(:args) { {} }
    let(:issue) { double }
    let(:response) { double }
    let(:response_string) { '{"issues": {"key":"foo"}, "isLast": true}' }

    before do
      allow(response).to receive(:body).and_return(response_string)
      allow(client).to receive(:Issue).and_return(issue)
      allow(issue).to receive(:build).with(%w[key foo]).and_return('')
    end

    it 'searches an issue with a jql query string' do
      expect(client).to receive(:get).with('/jira/rest/api/2/search/jql?jql=foo+bar')
                                     .and_return(response)
      expect(described_class.jql(client, 'foo bar')).to eq([''])
    end

    it 'passes thorugh the reconcileIssues parameter' do
      expect(client).to receive(:get)
        .with('/jira/rest/api/2/search/jql?jql=foo+bar&reconcileIssues=true')
        .and_return(response)

      expect(described_class.jql(client, 'foo bar', reconcile_issues: true)).to eq([''])
    end

    it 'searches an issue with a jql query string and fields' do
      expect(client).to receive(:get)
        .with('/jira/rest/api/2/search/jql?jql=foo+bar&fields=foo,bar')
        .and_return(response)

      expect(described_class.jql(client, 'foo bar', fields: %w[foo bar])).to eq([''])
    end

    context 'when maxResults is provided' do
      let(:args) { { max_results: } }

      context 'with non-zero' do
        let(:max_results) { 3 }

        it 'searches an issue with a jql query string and maxResults' do
          expect(client).to receive(:get)
            .with('/jira/rest/api/2/search/jql?jql=foo+bar&maxResults=3')
            .and_return(response)

          expect(subject).to eq([''])
        end
      end

      context 'with zero' do
        let(:response_string) { '{"total": 1, "issues": []}' }
        let(:max_results) { 0 }

        it 'searches an issue with a jql query string and should return the count of tickets' do
          expect(client).to receive(:get)
            .with('/jira/rest/api/2/search/jql?jql=foo+bar&maxResults=0')
            .and_return(response)

          expect(subject).to eq(1)
        end
      end
    end

    it 'searches an issue with a jql query string and string expand' do
      expect(client).to receive(:get)
        .with('/jira/rest/api/2/search/jql?jql=foo+bar&expand=transitions')
        .and_return(response)

      expect(described_class.jql(client, 'foo bar', expand: 'transitions')).to eq([''])
    end

    it 'searches an issue with a jql query string and array expand' do
      expect(client).to receive(:get)
        .with('/jira/rest/api/2/search/jql?jql=foo+bar&expand=transitions')
        .and_return(response)

      expect(described_class.jql(client, 'foo bar', expand: %w[transitions])).to eq([''])
    end

    context 'when pagination is required' do
      let(:response_string) { '{"issues": [{"key":"foo"}], "isLast": false, "nextPageToken": "abc"}' }
      let(:second_response_string) { '{"issues": [{"key":"bar"}], "isLast": true}' }

      before do
        allow(issue).to receive(:build).with({ 'key' => 'foo' }).and_return('1')
        allow(issue).to receive(:build).with({ 'key' => 'bar' }).and_return('2')
      end

      it 'makes multiple requests' do
        expect(client).to receive(:get)
          .with('/jira/rest/api/2/search/jql?jql=foo+bar')
          .and_return(response)
        expect(client).to receive(:get)
          .with('/jira/rest/api/2/search/jql?jql=foo+bar&nextPageToken=abc')
          .and_return(double(body: second_response_string))

        expect(subject).to eq(%w[1 2])
      end
    end
  end

  describe '.jql_paged' do
    let(:issue) { double }
    let(:response) { double }

    before do
      allow(response).to receive(:body).and_return(response_string)
      allow(client).to receive(:Issue).and_return(issue)
      allow(issue).to receive(:build).with({ 'key' => 'foo' }).and_return('1')
      allow(issue).to receive(:build).with({ 'key' => 'bar' }).and_return('2')
      allow(issue).to receive(:build).with({ 'key' => 'baz' }).and_return('3')
    end

    context 'without next_page_token (first page)' do
      subject { described_class.jql_paged(client, 'foo bar', page_size: 2) }

      before { expect(client).to receive(:get).with('/jira/rest/api/2/search/jql?jql=foo+bar').and_return(response) }

      let(:response) { double }
      let(:response_string) { '{"issues": [{"key":"foo"},{"key":"bar"}], "isLast": false, "nextPageToken": "abc"}' }

      it { is_expected.to eq(issues: %w[1 2], next_page_token: 'abc', total: nil) }
    end

    context 'with next_page_token' do
      subject { described_class.jql_paged(client, 'foo bar', page_size: 2, next_page_token: 'abc') }

      let(:response_string) { '{"issues": [{"key":"baz"}], "isLast": true}' }

      before { expect(client).to receive(:get).with('/jira/rest/api/2/search/jql?jql=foo+bar&nextPageToken=abc').and_return(double(body: response_string)) }

      it { is_expected.to eq(issues: %w[3], next_page_token: nil, total: nil) }
    end
  end

  it 'returns meta data available for editing an issue' do
    subject = described_class.new(client, attrs: { 'fields' => { 'key' => 'TST=123' } })
    response = double

    allow(response).to receive(:body).and_return(
      '{"fields":{"summary":{"required":true,"name":"Summary","operations":["set"]}}}'
    )
    expect(client).to receive(:get)
      .with('/jira/rest/api/2/issue/TST=123/editmeta')
      .and_return(response)

    expect(subject.editmeta).to eq('summary' => { 'required' => true, 'name' => 'Summary', 'operations' => ['set'] })
  end

  it 'provides direct accessors to the fields' do
    subject = described_class.new(client, attrs: { 'fields' => { 'foo' => 'bar' } })
    expect(subject).to respond_to(:foo)
    expect(subject.foo).to eq('bar')
  end

  describe 'relationships' do
    subject do
      described_class.new(client, attrs: {
                            'id' => '123',
                            'fields' => {
                              'reporter' => { 'foo' => 'bar' },
                              'assignee' => { 'foo' => 'bar' },
                              'project' => { 'foo' => 'bar' },
                              'priority' => { 'foo' => 'bar' },
                              'issuetype' => { 'foo' => 'bar' },
                              'status' => { 'foo' => 'bar' },
                              'resolution' => { 'foo' => 'bar' },
                              'components' => [{ 'foo' => 'bar' }, { 'baz' => 'flum' }],
                              'versions' => [{ 'foo' => 'bar' }, { 'baz' => 'flum' }],
                              'comment' => { 'comments' => [{ 'foo' => 'bar' }, { 'baz' => 'flum' }] },
                              'attachment' => [{ 'foo' => 'bar' }, { 'baz' => 'flum' }],
                              'worklog' => { 'worklogs' => [{ 'foo' => 'bar' }, { 'baz' => 'flum' }] }
                            },
                            'properties' => [{ 'foo' => 'bar' }, { 'baz' => 'flum' }]
                          })
    end

    it 'has the correct relationships' do
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

      expect(subject).to have_one(:resolution, JIRA::Resource::Resolution)
      expect(subject.resolution.foo).to eq('bar')

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

      expect(subject).to have_many(:properties, JIRA::Resource::Properties)
      expect(subject.properties.length).to eq(2)
    end
  end
end
