require 'spec_helper'

describe JIRA::HasManyProxy do

  class Foo ; end

  subject { JIRA::HasManyProxy.new(parent, Foo, collection) }

  let(:parent)      { double("parent") }
  let(:collection)  { double("collection") }

  it "has a target class" do
    expect(subject.target_class).to eq(Foo)
  end

  it "has a parent" do
    expect(subject.parent).to eq(parent)
  end

  it "has a collection" do
    expect(subject.collection).to eq(collection)
  end

  it "can build a new instance" do
    client = double('client')
    foo = double('foo')
    allow(parent).to receive(:client).and_return(client)
    allow(parent).to receive(:to_sym).and_return(:parent)
    expect(Foo).to receive(:new).with(client, :attrs => {'foo' => 'bar'}, :parent => parent).and_return(foo)
    expect(collection).to receive(:<<).with(foo)
    expect(subject.build('foo' => 'bar')).to eq(foo)
  end

  it "can get all the instances" do
    foo = double('foo')
    client = double('client')
    allow(parent).to receive(:client).and_return(client)
    allow(parent).to receive(:to_sym).and_return(:parent)
    expect(Foo).to receive(:all).with(client, :parent => parent).and_return(foo)
    expect(subject.all).to eq(foo)
  end

  it "delegates missing methods to the collection" do
    expect(collection).to receive(:missing_method)
    subject.missing_method
  end
end
