require 'spec_helper'

describe JIRA::Resource::Field do

  let(:client) do
    client = double(options: {rest_base_path: '/jira/rest/api/2'}  )
    allow(client).to receive(:Field).and_return(JIRA::Resource::FieldFactory.new(client))
    allow(client).to receive(:cache).and_return(OpenStruct.new)
    client
  end
  
  describe "field_mappings" do
    subject {
      JIRA::Resource::Field.new(client, :attrs => {
        'priority' => 1
      })
    }

    it "can find a standard field" do
      expect(subject.priority).to eq(1)
    end
  end

end
