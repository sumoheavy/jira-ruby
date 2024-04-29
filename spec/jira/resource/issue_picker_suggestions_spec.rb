require 'spec_helper'

describe JIRA::Resource::IssuePickerSuggestions do
  let(:client) do
    double('client', options: {
      rest_base_path: '/jira/rest/api/2'
    })
  end

  describe 'relationships' do
    subject do
      described_class.new(client, attrs: {
        'sections' => [{ 'id' => 'hs' }, { 'id' => 'cs' }]
      })
    end

    it 'has the correct relationships' do
      expect(subject).to have_many(:sections, JIRA::Resource::IssuePickerSuggestionsIssue)
      expect(subject.sections.length).to eq(2)
    end
  end

  describe '#all' do
    let(:response) { double }
    let(:issue_picker_suggestions) { double }

    before do
      allow(response).to receive(:body).and_return('{"sections":[{"id": "cs"}]}')
      allow(client).to receive(:IssuePickerSuggestions).and_return(issue_picker_suggestions)
      allow(issue_picker_suggestions).to receive(:build)
    end

    it 'autocompletes issues' do
      allow(response).to receive(:body).and_return('{"sections":[{"id": "cs"}]}')
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/picker?query=query')
                                     .and_return(response)

      expect(client).to receive(:IssuePickerSuggestions).and_return(issue_picker_suggestions)
      expect(issue_picker_suggestions).to receive(:build).with({ 'sections' => [{ 'id' => 'cs' }] })

      described_class.all(client, 'query')
    end

    it 'autocompletes issues with current jql' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/picker?query=query&currentJQL=project+%3D+PR')
                                     .and_return(response)

      described_class.all(client, 'query', current_jql: 'project = PR')
    end

    it 'autocompletes issues with current issue jey' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/picker?query=query&currentIssueKey=PR-42')
                                     .and_return(response)

      described_class.all(client, 'query', current_issue_key: 'PR-42')
    end

    it 'autocompletes issues with current project id' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/picker?query=query&currentProjectId=PR')
                                     .and_return(response)

      described_class.all(client, 'query', current_project_id: 'PR')
    end

    it 'autocompletes issues with show sub tasks' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/picker?query=query&showSubTasks=true')
                                     .and_return(response)

      described_class.all(client, 'query', show_sub_tasks: true)
    end

    it 'autocompletes issues with show sub tasks parent' do
      expect(client).to receive(:get).with('/jira/rest/api/2/issue/picker?query=query&showSubTaskParent=true')
                                     .and_return(response)

      described_class.all(client, 'query', show_sub_task_parent: true)
    end
  end
end
