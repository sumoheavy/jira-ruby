require 'spec_helper'

describe JIRA::BaseFactory do
  class JIRA::Resource::FooFactory < JIRA::BaseFactory; end
  class JIRA::Resource::Foo; end

  subject       { JIRA::Resource::FooFactory.new(client) }

  let(:client)  { double }

  it 'initializes correctly' do
    expect(subject.class).to        eq(JIRA::Resource::FooFactory)
    expect(subject.client).to       eq(client)
    expect(subject.target_class).to eq(JIRA::Resource::Foo)
  end

  it 'proxies all to the target class' do
    expect(JIRA::Resource::Foo).to receive(:all).with(client)
    subject.all
  end

  it 'proxies find to the target class' do
    expect(JIRA::Resource::Foo).to receive(:find).with(client, 'FOO')
    subject.find('FOO')
  end

  it 'returns the target class' do
    expect(subject.target_class).to eq(JIRA::Resource::Foo)
  end

  it 'proxies build to the target class' do
    attrs = double
    expect(JIRA::Resource::Foo).to receive(:build).with(client, attrs)
    subject.build(attrs)
  end

  it 'proxies collection path to the target class' do
    expect(JIRA::Resource::Foo).to receive(:collection_path).with(client)
    subject.collection_path
  end

  it 'proxies singular path to the target class' do
    expect(JIRA::Resource::Foo).to receive(:singular_path).with(client, 'FOO')
    subject.singular_path('FOO')
  end
end
