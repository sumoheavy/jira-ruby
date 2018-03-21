require 'spec_helper'

describe JIRA::Resource::Agile do
  let(:client) do
    double(
      'client',
      options: {
        context_path: '/jira',
        rest_base_path: '/rest/agile/1.0'
      }
    )
  end

  describe '.all' do
    let(:response) do
      instance_double(
        'Response',
        body: get_mock_response('agile/board.json')
      )
    end

    it 'returns json for all boards' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board').and_return(response)
      expect(described_class.all(client)).to be_a(Hash)
    end
  end

  describe '.get_backlog_issues' do
    let(:response) do
      instance_double(
        'Response',
        body: get_mock_response('agile/backlog.json')
      )
    end

    it 'returns Hash Object' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/backlog?maxResults=100').and_return(response)
      expect(described_class.get_backlog_issues(client, 1)).to be_a(Hash)
    end

    it 'escapes options' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/backlog?order=%2Bname&maxResults=100').and_return(response)
      expect(described_class.get_backlog_issues(client, 1, {order: '+name'})).to be_a(Hash)
    end
  end

  describe '.get_sprints' do
    let(:response) do
      instance_double(
        'Response',
        body: get_mock_response('agile/sprint.json')
      )
    end

    it 'returns Hash Object' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/sprint?maxResults=100').and_return(response)
      expect(described_class.get_sprints(client, 1)).to be_a(Hash)
    end

    it 'escapes options' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/board/1/sprint?order=%2Bname&maxResults=100').and_return(response)
      expect(described_class.get_sprints(client, 1, {order: '+name'})).to be_a(Hash)
    end
  end

  describe '.get_sprint_issues' do
    let(:response) do
      instance_double(
        'Response',
        body: get_mock_response('agile/sprint_issues.json')
      )
    end

    it 'returns Hash Object' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/sprint/1/issue?maxResults=100').and_return(response)
      expect(described_class.get_sprint_issues(client, 1)).to be_a(Hash)
    end

    it 'escapes options' do
      expect(client).to receive(:get).with('/jira/rest/agile/1.0/sprint/1/issue?order=%2Bname&maxResults=100').and_return(response)
      expect(described_class.get_sprint_issues(client, 1, {order: '+name'})).to be_a(Hash)
    end
  end
end