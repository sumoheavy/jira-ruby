require 'spec_helper'

describe JIRA::Resource::Agile do
  let(:client) { double(options: {rest_base_path: '/jira/rest/api/2', context_path: '/jira'}) }
  let(:response) { double }

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
end
