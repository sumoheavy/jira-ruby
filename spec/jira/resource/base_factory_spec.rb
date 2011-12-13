require 'spec_helper'

describe Jira::Resource::BaseFactory do

  class Jira::Resource::FooFactory < Jira::Resource::BaseFactory ; end
  class Jira::Resource::Foo ; end

  let(:client)  { mock() }
  subject       { Jira::Resource::FooFactory.new(client) }

  it "initializes correctly" do
    subject.class.should        == Jira::Resource::FooFactory
    subject.client.should       == client
    subject.target_class.should == Jira::Resource::Foo
  end

  it "proxies all to the target class" do
    Jira::Resource::Foo.should_receive(:all).with(client)
    subject.all
  end

  it "proxies find to the target class" do
    Jira::Resource::Foo.should_receive(:find).with(client, 'FOO')
    subject.find('FOO')
  end

  it "returns the target class" do
    subject.target_class.should == Jira::Resource::Foo
  end

  it "proxies build to the target class" do
    attrs = mock()
    Jira::Resource::Foo.should_receive(:build).with(client, attrs)
    subject.build(attrs)
  end
end
