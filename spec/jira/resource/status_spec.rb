require 'spec_helper'

describe JIRA::Resource::Status do

  let(:client) do
    client = double(options: { rest_base_path: '/jira/rest/api/2' })
    allow(client).to receive(:Field).and_return(JIRA::Resource::FieldFactory.new(client))
    allow(client).to receive(:cache).and_return(OpenStruct.new)
    client
  end

  describe '#status_category' do
    subject do
      JIRA::Resource::Status.new(client, attrs: JSON.parse(File.read('spec/mock_responses/status/1.json')))
    end

    it 'has a status_category relationship' do
      expect(subject).to have_one(:status_category, JIRA::Resource::StatusCategory)
      expect(subject.status_category.name).to eq('To Do')
    end
  end
end