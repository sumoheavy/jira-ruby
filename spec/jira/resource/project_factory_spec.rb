require 'spec_helper'

describe JIRA::Resource::ProjectFactory do
  subject       { described_class.new(client) }

  let(:client)  { double }

  it 'initializes correctly' do
    expect(subject.class).to eq(described_class)
    expect(subject.client).to eq(client)
  end
end
