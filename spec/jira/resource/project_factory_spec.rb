require 'spec_helper'

describe JIRA::Resource::ProjectFactory do
  let(:client)  { double }
  subject       { JIRA::Resource::ProjectFactory.new(client) }

  it 'initializes correctly' do
    expect(subject.class).to eq(JIRA::Resource::ProjectFactory)
    expect(subject.client).to eq(client)
  end
end
