require 'spec_helper'
require 'active_support/core_ext/hash'

describe JIRA::Resource::Board do
  class JIRAResourceDelegation < SimpleDelegator # :nodoc:
  end

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
    expect(client).to receive(:get).with('/rest/agile/1.0/board/84')
                                   .and_return(response)

    expect(client).to receive(:Board).and_return(JIRA::Resource::BoardFactory.new(client))
    described_class.find(client, '84')
  end

  it 'finds all boards' do
    response = double
    api_json = <<EOS
    {
         "maxResults": 50,
         "startAt": 0,
         "isLast": true,
         "values": [
            {
                "id": 84,
                "name": "scrum board",
                "type": "scrum"
            },
            {
                "id": 92,
                "name": "kanban board",
                "type": "kanban"
            }
        ]
    }
EOS
    allow(response).to receive(:body).and_return(api_json)
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

      api_json_issues = <<EOS
    {
        "expand": "names,schema",
        "startAt": 0,
        "maxResults": 50,
        "total": 1,
        "issues": [
            {
                "id": "10001",
                "fields": {
                    "sprint": {
                        "id": 37,
                        "state": "future",
                        "name": "sprint 2"
                    },
                    "description": "example bug report"
                }
            }
        ]
    }
EOS

      allow(issues_response).to receive(:body).and_return(api_json_issues)
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
        let(:result_1) do
          OpenStruct.new(body: {
            'startAt' => 0,
            'maxResults' => 1,
            'total' => 2,
            'issues' => []
          }.to_json)
        end
        let(:result_2) do
          OpenStruct.new(body: {
            'startAt' => 1,
            'maxResults' => 1,
            'total' => 2,
            'issues' => []
          }.to_json)
        end

        it 'makes multiple requests and increments the startAt param' do
          expect(client).to receive(:get).and_return(result_1)
          expect(client).to receive(:get).and_return(result_2)
          subject.issues
        end
      end

      context 'when there is only one page of results' do
        let(:result_1) do
          OpenStruct.new(body: {
            'startAt' => 0,
            'maxResults' => 2,
            'total' => 2,
            'issues' => []
          }.to_json)
        end

        it 'only requires one request' do
          expect(client).to receive(:get).once.and_return(result_1)
          subject.issues
        end
      end
    end
  end

  it 'gets all sprints for a board' do
    response = double

    api_json = <<-EOS
    {
        "values": [
            {
                "id": 37,
                "state": "closed",
                "name": "sprint 1"
            },
            {
                "id": 72,
                "state": "future",
                "name": "sprint 2"
            }
        ]
    }
EOS
    allow(response).to receive(:body).and_return(api_json)
    allow(board).to receive(:id).and_return(84)
    expect(client).to receive(:get).with('/rest/agile/1.0/board/84/sprint?').and_return(response)
    expect(client).to receive(:Sprint).twice.and_return(JIRA::Resource::SprintFactory.new(client))
    expect(board.sprints.size).to be(2)
  end

  it 'gets board configuration for a board' do
    response = double

    api_json = <<-EOS
      {
        "id":1,
        "name":"My Board",
        "type":"kanban",
        "self":"https://mycompany.atlassian.net/rest/agile/1.0/board/1/configuration",
        "location":{
          "type":"project",
          "key":"MYPROJ",
          "id":"10000",
          "self":"https://mycompany.atlassian.net/rest/api/2/project/10000",
          "name":"My Project"
        },
        "filter":{
          "id":"10000",
          "self":"https://mycompany.atlassian.net/rest/api/2/filter/10000"
        },
        "subQuery":{
          "query":"resolution = EMPTY OR resolution != EMPTY AND resolutiondate >= -5d"
        },
        "columnConfig":{
          "columns":[
            {
              "name":"Backlog",
              "statuses":[
                {
                  "id":"10000",
                  "self":"https://mycompany.atlassian.net/rest/api/2/status/10000"
                }
              ]
            }
          ],
          "constraintType":"issueCount"
        },
        "ranking":{
          "rankCustomFieldId":10011
        }
      }
EOS
    allow(response).to receive(:body).and_return(api_json)
    allow(board).to receive(:id).and_return(84)
    expect(client).to receive(:get).with('/rest/agile/1.0/board/84/configuration').and_return(response)
    expect(client).to receive(:BoardConfiguration).and_return(JIRA::Resource::BoardConfigurationFactory.new(client))
    expect(board.configuration).not_to be(nil)
  end
end
