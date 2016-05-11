require 'spec_helper'
require 'active_support/core_ext/hash'

describe JIRA::Resource::Board do

  class JIRAResourceDelegation < SimpleDelegator # :nodoc:
  end

  let(:client) { double(options: {
    rest_base_path: '/jira/rest/api/2',
    context_path: ''
  }) }

  let(:board) {
    response = double()
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
    JIRA::Resource::Board.find(client, "84")
  }

  it "should find all boards" do
    response = double()
    api_json = <<eos
    {
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
eos
    allow(response).to receive(:body).and_return(api_json)
    expect(client).to receive(:get).with('/rest/agile/1.0/board')
      .and_return(response)
    expect(client).to receive(:Board).twice.and_return(JIRA::Resource::BoardFactory.new(client))
    boards = JIRA::Resource::Board.all(client)
    expect(boards.count).to eq(2)
  end

  it "should find one board by id" do
    expect(board).to be_a(JIRA::Resource::Board)
  end

  it "should find all issues" do
    issues_response = double()

    api_json_issues = <<eos 
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
eos

    allow(issues_response).to receive(:body).and_return(api_json_issues)
    allow(board).to receive(:id).and_return(84)
    expect(client).to receive(:get).with('/rest/agile/1.0/board/84/issue?').
      and_return(issues_response)
    expect(client).to receive(:Issue).and_return(JIRA::Resource::IssueFactory.new(client))

    expect(board.issues.size).to be(1)
  end

  it "should get all sprints for a board" do
    response = double()

    api_json = <<-eos
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
    eos
    allow(response).to receive(:body).and_return(api_json)
    allow(board).to receive(:id).and_return(84)
    expect(client).to receive(:get).with('/rest/agile/1.0/board/84/sprint?').and_return(response)
    expect(client).to receive(:Sprint).twice.and_return(JIRA::Resource::SprintFactory.new(client))
    expect(board.sprints.size).to be(2)
  end

end
