require 'spec_helper'

describe JIRA::Resource::Filter do
  let(:client) do
    client = double
    allow(client).to receive(:Issue).and_return(JIRA::Resource::IssueFactory.new(self))
    client
  end
  let(:collection_path) { '/rest/api/2/filter' }
  let(:jira_user) do
    {
      self: 'https://localhost/rest/api/2/user?username=ljharb',
      name: 'ljharb',
      avatarUrls: {
        '16x16' => 'https://localhost/secure/useravatar?size=small&ownerId=ljharb&avatarId=1',
        '48x48' => 'https://localhost/secure/useravatar?ownerId=ljharb&avatarId=1'
      },
      displayName: 'Jordan Harband',
      active: true
    }
  end
  let(:filter_attrs) do
    {
      self: "https://localhost#{collection_path}/42",
      id: 42,
      name: 'Resolved Tickets',
      description: '',
      owner: jira_user,
      jql: '"Git Repository" ~ jira-ruby AND status = Resolved',
      viewUrl: 'https://localhost/secure/IssueNavigator.jspa?mode=hide&requestId=42',
      searchUrl: 'https://localhost/rest/api/2/search?jql=%22Git+Repository%22+~+jira-ruby+AND+status+%3D+Resolved',
      favourite: false,
      sharePermissions: [
        {
          id: 123,
          type: 'global'
        }
      ],
      subscriptions: {
        size: 0,
        items: []
      }
    }
  end
  let(:filter_response) do
    response = double
    allow(response).to receive(:body).and_return(filter_attrs.to_json)
    response
  end
  let(:filter) do
    allow(client).to receive(:get).with("#{collection_path}/42").and_return(filter_response)
    allow(described_class).to receive(:collection_path).and_return(collection_path)
    described_class.find(client, 42)
  end
  let(:jql_issue) do
    {
      id: '663147',
      self: 'https://localhost/rest/api/2/issue/663147',
      key: 'JIRARUBY-2386',
      fields: {
        reporter: jira_user,
        created: '2013-12-11T23:28:02.000+0000',
        assignee: jira_user
      }
    }
  end
  let(:jql_attrs) do
    {
      startAt: 0,
      maxResults: 50,
      total: 2,
      issues: [jql_issue]
    }
  end
  let(:issue_jql_response) do
    response = double
    allow(response).to receive(:body).and_return(jql_attrs.to_json)
    response
  end

  it 'can be found by ID' do
    expect(JSON.parse(filter.attrs.to_json)).to eql(JSON.parse(filter_attrs.to_json))
  end

  it 'returns issues' do
    expect(filter).to be_present
    allow(client).to receive(:options).and_return(rest_base_path: 'localhost')
    expect(client).to receive(:get)
      .with("localhost/search?jql=#{CGI.escape(filter.jql)}")
      .and_return(issue_jql_response)
    issues = filter.issues
    expect(issues).to be_an(Array)
    expect(issues.size).to be(1)
    expected_issue = client.Issue.build(JSON.parse(jql_issue.to_json))
    expect(issues.first.attrs).to eql(expected_issue.attrs)
  end
end
