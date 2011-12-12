require 'spec_helper'

describe JiraRuby::Resource::BaseFactory do

  class JiraRuby::Resource::FooFactory < JiraRuby::Resource::BaseFactory ; end
  class JiraRuby::Resource::Foo ; end

  let(:client)  { mock() }
  subject       { JiraRuby::Resource::FooFactory.new(client) }

  it "initializes correctly" do
    subject.class.should        == JiraRuby::Resource::FooFactory
    subject.client.should       == client
    subject.target_class.should == JiraRuby::Resource::Foo
  end

  it "proxies all to the target class" do
    JiraRuby::Resource::Foo.should_receive(:all).with(client)
    subject.all
  end

  it "proxies find to the target class" do
    JiraRuby::Resource::Foo.should_receive(:find).with(client, 'FOO')
    subject.find('FOO')
  end

end
