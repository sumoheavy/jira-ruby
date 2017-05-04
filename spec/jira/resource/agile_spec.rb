require 'spec_helper'

describe JIRA::Resource::Agile do
  let(:client) { double(options: {rest_base_path: '/jira/rest/api/2', context_path: '/jira'}) }
  let(:response) { double }

  describe '#all' do
    it 'should query url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.all(client)
    end
  end

  describe '#get_backlog_issues' do
    it 'should query the url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/backlog?maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_backlog_issues(client, 1)
    end
  end

  describe '#get_sprints' do
    it 'should query correct url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/sprint?maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_sprints(client, 1)
    end

    it 'should query correct url with parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/sprint?startAt=50&maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_sprints(client, 1, startAt: 50)
    end
  end

  describe '#get_sprint_issues' do
    it 'should query correct url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/sprint/1/issue?maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('sprint/1_issues.json'))

      JIRA::Resource::Agile.get_sprint_issues(client, 1)
    end

    it 'should query correct url with parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/sprint/1/issue?startAt=50&maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('sprint/1_issues.json'))

      JIRA::Resource::Agile.get_sprint_issues(client, 1, startAt: 50)
    end
  end

  describe '#get_projects_full' do
    it 'should query correct url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/project/full').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_projects_full(client, 1)
    end
  end

  describe '#get_projects' do
    it 'should query correct url without parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/project?maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_projects(client, 1)
    end

    it 'should query correct url with parameters' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/project?startAt=50&maxResults=100').and_return(response)
      expect(response).to receive(:body).and_return(get_mock_response('board/1.json'))

      JIRA::Resource::Agile.get_projects(client, 1, startAt: 50)
    end
  end
end
