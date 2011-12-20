require 'spec_helper'

describe JIRA::Resource::BaseFactory do

  class JIRA::Resource::FooFactory < JIRA::Resource::BaseFactory ; end
  class JIRA::Resource::Foo ; end

  let(:client)  { mock() }
  subject       { JIRA::Resource::FooFactory.new(client) }

  it "initializes correctly" do
    subject.class.should        == JIRA::Resource::FooFactory
    subject.client.should       == client
    subject.target_class.should == JIRA::Resource::Foo
  end

  it "proxies all to the target class" do
    JIRA::Resource::Foo.should_receive(:all).with(client)
    subject.all
  end

  it "proxies find to the target class" do
    JIRA::Resource::Foo.should_receive(:find).with(client, 'FOO')
    subject.find('FOO')
  end

  it "returns the target class" do
    subject.target_class.should == JIRA::Resource::Foo
  end

  it "proxies build to the target class" do
    attrs = mock()
    JIRA::Resource::Foo.should_receive(:build).with(client, attrs)
    subject.build(attrs)
  end
end
