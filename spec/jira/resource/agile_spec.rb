require 'spec_helper'

describe JIRA::Resource::Agile do
  let(:client) do
    client = double(options: { rest_base_path: '/jira/rest/api/2', context_path: '/jira' })
    allow(client).to receive(:Issue).and_return(JIRA::Resource::IssueFactory.new(client))
    client
  end
  let(:response) { double }
  # This is the JQL query for the issue ids in the board/1_issues.json fixture.
  let(:board_issues_jql_url) do
    '/jira/rest/api/2/search/jql?jql=id+IN%2810546%2C+10547%2C+10556%2C' \
      '+10557%2C+10558%2C+10559%2C+10600%2C+10601%2C+10604%29'
  end

  # This method expects a GET of an agile endpoint. It adds the given path to the
  # agile base path.
  def expect_agile_get(path)
    expect(client).to receive(:get).with("/jira/rest/agile/1.0#{path}").and_return(response)
  end

  describe '#all' do
    it 'queries url without parameters' do
      expect_agile_get '/board'
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      described_class.all(client)
    end
  end

  describe '#get_backlog_issues' do
    it 'queries the url without parameters' do
      expect_agile_get '/board/1/backlog?maxResults=100'
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      described_class.get_backlog_issues(client, 1)
    end
  end

  describe '#get_board_issues' do
    it 'queries correct url without parameters' do
      expect_agile_get '/board/1/issue?'
      expect(response).to receive(:body).and_return(get_mock_response('board/1_issues.json'))

      expect(client).to receive(:get).with(board_issues_jql_url).and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1_issues.json'))

      issues = described_class.get_board_issues(client, 1)
      expect(issues).to be_an(Array)
      expect(issues.size).to be(9)

      issues.each do |issue|
        expect(issue.class).to eq(JIRA::Resource::Issue)
        expect(issue).not_to be_expanded
      end
    end

    it 'queries correct url with parameters' do
      expect_agile_get '/board/1/issue?startAt=50'
      expect(response).to receive(:body).and_return(get_mock_response('board/1_issues.json'))

      expect(client).to receive(:get).with(board_issues_jql_url).and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1_issues.json'))

      issues = described_class.get_board_issues(client, 1, startAt: 50)
      expect(issues).to be_an(Array)
      expect(issues.size).to be(9)

      issues.each do |issue|
        expect(issue.class).to eq(JIRA::Resource::Issue)
        expect(issue).not_to be_expanded
      end
    end
  end

  describe '#get_sprints' do
    it 'queries correct url without parameters' do
      expect_agile_get '/board/1/sprint?maxResults=100'
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      described_class.get_sprints(client, 1)
    end

    it 'queries correct url with parameters' do
      expect_agile_get '/board/1/sprint?startAt=50&maxResults=100'
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      described_class.get_sprints(client, 1, startAt: 50)
    end

    it 'works with pagination starting at 0' do
      expect_agile_get '/board/1/sprint?maxResults=1&startAt=0'
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      described_class.get_sprints(client, 1, maxResults: 1, startAt: 0)
    end

    it 'works with pagination not starting at 0' do
      expect_agile_get '/board/1/sprint?maxResults=1&startAt=1'
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      described_class.get_sprints(client, 1, maxResults: 1, startAt: 1)
    end
  end

  describe '#get_sprint_issues' do
    it 'queries correct url without parameters' do
      expect_agile_get '/sprint/1/issue?maxResults=100'
      expect(response).to receive(:body).and_return(get_mock_response('sprint/1_issues.json'))

      described_class.get_sprint_issues(client, 1)
    end

    it 'queries correct url with parameters' do
      expect_agile_get '/sprint/1/issue?startAt=50&maxResults=100'
      expect(response).to receive(:body).and_return(get_mock_response('sprint/1_issues.json'))

      described_class.get_sprint_issues(client, 1, startAt: 50)
    end
  end

  describe '#get_projects_full' do
    it 'queries correct url without parameters' do
      expect_agile_get '/board/1/project/full'
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      described_class.get_projects_full(client, 1)
    end
  end

  describe '#get_projects' do
    it 'queries correct url without parameters' do
      expect_agile_get '/board/1/project?maxResults=100'
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      described_class.get_projects(client, 1)
    end

    it 'queries correct url with parameters' do
      expect_agile_get '/board/1/project?startAt=50&maxResults=100'
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      described_class.get_projects(client, 1, startAt: 50)
    end
  end
end
