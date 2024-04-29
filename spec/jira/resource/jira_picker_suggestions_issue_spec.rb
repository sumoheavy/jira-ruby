require 'spec_helper'

describe JIRA::Resource::IssuePickerSuggestionsIssue do
  let(:client) { double('client') }

  describe 'relationships' do
    subject do
      described_class.new(client, attrs: {
        'issues' => [{ 'id' => '1' }, { 'id' => '2' }]
      })
    end

    it 'has the correct relationships' do
      expect(subject).to have_many(:issues, JIRA::Resource::SuggestedIssue)
      expect(subject.issues.length).to eq(2)
    end
  end
end
