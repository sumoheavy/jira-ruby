require 'spec_helper'

describe JIRA::Resource::HasManyProxy do

  class Foo ; end

  subject { JIRA::Resource::HasManyProxy.new(parent, Foo, collection) }
  
  let(:parent)      { mock("parent") }
  let(:collection)  { mock("collection") }

  it "has a target class" do
    subject.target_class.should == Foo
  end

  it "has a parent" do
    subject.parent.should == parent
  end

  it "has a collection" do
    subject.collection.should == collection
  end

  it "can build a new instance" do
    client = mock('client')
    foo = mock('foo')
    parent.stub(:client => client, :to_sym => :foo)
    Foo.should_receive(:new).with(client, :attrs => {'foo' => 'bar'}, :foo => parent).and_return(foo)
    subject.build('foo' => 'bar').should == foo
  end

  it "delegates missing methods to the collection" do
    collection.should_receive(:missing_method)
    subject.missing_method
  end
end
