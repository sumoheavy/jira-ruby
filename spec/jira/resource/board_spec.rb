require 'spec_helper'
require 'active_support/core_ext/hash'

describe JIRA::Resource::Board do
  let(:client) do
    double(options: {
             rest_base_path: '/jira/rest/api/2',
             context_path: ''
           })
  end

  let(:board) do
    response = double
    api_json_board = "{
      \"id\": 84,
      \"self\": \"http://www.example.com/jira/rest/agile/1.0/board/84\",
      \"name\": \"scrum board\",
      \"type\": \"scrum\"
    }"
    allow(response).to receive(:body).and_return(api_json_board)
    allow(client).to receive(:get).with('/rest/agile/1.0/board/84')
                                  .and_return(response)

    allow(client).to receive(:Board).and_return(JIRA::Resource::BoardFactory.new(client))
    described_class.find(client, '84')
  end

  it 'finds all boards' do
    response = double
    allow(response).to receive(:body).and_return(get_mock_response('board/all.json'))
    expect(client).to receive(:get).with('/rest/agile/1.0/board')
                                   .and_return(response)
    expect(client).to receive(:Board).twice.and_return(JIRA::Resource::BoardFactory.new(client))
    boards = described_class.all(client)
    expect(boards.count).to eq(2)
  end

  it 'finds one board by id' do
    expect(board).to be_a(described_class)
  end

  describe '#issues' do
    it 'finds all issues' do
      issues_response = double

      allow(issues_response).to receive(:body).and_return(get_mock_response('board/84_issues.json'))
      allow(board).to receive(:id).and_return(84)
      expect(client).to receive(:get).with('/rest/agile/1.0/board/84/issue')
                                     .and_return(issues_response)
      expect(client).to receive(:Issue).and_return(JIRA::Resource::IssueFactory.new(client))

      expect(board.issues.size).to be(1)
    end

    describe 'pagination' do
      subject { described_class.new(client) }

      let(:client) { JIRA::Client.new }

      before do
        allow(subject).to receive(:id).and_return('123')
      end

      context 'when there are multiple pages of results' do
        let(:first_page) do
          double(body: {
            'startAt' => 0,
            'maxResults' => 1,
            'total' => 2,
            'issues' => []
          }.to_json)
        end
        let(:second_page) do
          double(body: {
            'startAt' => 1,
            'maxResults' => 1,
            'total' => 2,
            'issues' => []
          }.to_json)
        end

        it 'makes multiple requests and increments the startAt param' do
          expect(client).to receive(:get).and_return(first_page)
          expect(client).to receive(:get).and_return(second_page)
          subject.issues
        end
      end

      context 'when there is only one page of results' do
        let(:only_page) do
          double(body: {
            'startAt' => 0,
            'maxResults' => 2,
            'total' => 2,
            'issues' => []
          }.to_json)
        end

        it 'only requires one request' do
          expect(client).to receive(:get).once.and_return(only_page)
          subject.issues
        end
      end
    end
  end

  it 'gets all sprints for a board' do
    response = double

    allow(response).to receive(:body).and_return(get_mock_response('board/84_sprints.json'))
    allow(board).to receive(:id).and_return(84)
    expect(client).to receive(:get).with('/rest/agile/1.0/board/84/sprint?').and_return(response)
    expect(client).to receive(:Sprint).twice.and_return(JIRA::Resource::SprintFactory.new(client))
    expect(board.sprints.size).to be(2)
  end

  it 'gets board configuration for a board' do
    response = double

    allow(response).to receive(:body).and_return(get_mock_response('board/84_configuration.json'))
    allow(board).to receive(:id).and_return(84)
    expect(client).to receive(:get).with('/rest/agile/1.0/board/84/configuration').and_return(response)
    expect(client).to receive(:BoardConfiguration).and_return(JIRA::Resource::BoardConfigurationFactory.new(client))
    expect(board.configuration).not_to be_nil
  end
end
