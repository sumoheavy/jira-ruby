require 'spec_helper'

describe JIRA::HasManyProxy do

  class Foo ; end

  subject { JIRA::HasManyProxy.new(parent, Foo, collection) }

  let(:parent)      { double("parent") }
  let(:collection)  { double("collection") }

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
    client = double('client')
    foo = double('foo')
    parent.stub(:client => client, :to_sym => :parent)
    Foo.should_receive(:new).with(client, :attrs => {'foo' => 'bar'}, :parent => parent).and_return(foo)
    collection.should_receive(:<<).with(foo)
    subject.build('foo' => 'bar').should == foo
  end

  it "can get all the instances" do
    foo = double('foo')
    client = double('client')
    parent.stub(:client => client, :to_sym => :parent)
    Foo.should_receive(:all).with(client, :parent => parent).and_return(foo)
    subject.all.should == foo
  end

  it "delegates missing methods to the collection" do
    collection.should_receive(:missing_method)
    subject.missing_method
  end
end
