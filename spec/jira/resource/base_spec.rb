require 'spec_helper'

describe Jira::Resource::Base do

  class Jira::Resource::Foo < Jira::Resource::Base ; end

  let(:client)  { mock() }
  let(:attrs)   { mock() }

  subject { Jira::Resource::Foo.new(client, attrs) }

  it "assigns the client and attrs" do
    subject.client.should == client
    subject.attrs.should  == attrs
  end

  it "returns all the foos" do
    response = mock()
    response.should_receive(:body).and_return('[{"self":"http://foo/","key":"FOO"}]')
    client.should_receive(:get).with('/jira/rest/api/2.0.alpha1/foo').and_return(response)
    Jira::Resource::Foo.should_receive(:rest_base_path).and_return('/jira/rest/api/2.0.alpha1/foo')
    foos = Jira::Resource::Foo.all(client)
    foos.length.should == 1
    first = foos.first
    first.class.should == Jira::Resource::Foo
    first.attrs['self'].should  == 'http://foo/'
    first.attrs['key'].should   == 'FOO'
  end

  it "finds a foo by key" do
    response = mock()
    response.should_receive(:body).and_return('{"self":"http://foo/","key":"FOO"}')
    client.should_receive(:get).with('/jira/rest/api/2.0.alpha1/foo/FOO').and_return(response)
    Jira::Resource::Foo.should_receive(:rest_base_path).and_return('/jira/rest/api/2.0.alpha1/foo')
    foo = Jira::Resource::Foo.find(client, 'FOO')
    foo.client.should == client
    foo.attrs['self'].should  == 'http://foo/'
    foo.attrs['key'].should   == 'FOO'
  end

  it "returns the endpoint name" do
    subject.class.endpoint_name.should == 'foo'
  end


  describe "rest_base_path" do

    before(:each) do
      client.should_receive(:options).and_return(:rest_base_path => '/foo/bar')
    end

    it "returns the rest_base_path" do
      subject.rest_base_path.should == '/foo/bar/foo'
    end

    it "has a class method that returns the rest_base_path" do
      subject.class.rest_base_path(client).should == '/foo/bar/foo'
    end
  end

  describe "dynamic instance methods" do

    let(:attrs) { {'foo' => 'bar', 'flum' => 'goo', 'object_id' => 'dummy'} }
    subject     { Jira::Resource::Foo.new(client, attrs.to_json) }

    it "responds to each of the top level attribute names" do
      foo = Jira::Resource::Foo.new(client, attrs)
      foo.should respond_to(:foo)
      foo.should respond_to('flum')
      foo.should respond_to(:object_id)

      foo.foo.should  == 'bar'
      foo.flum.should == 'goo'

      # Should not override existing method names, but should still allow
      # access to their values via the attrs[] hash
      foo.object_id.should_not == 'dummy'
      foo.attrs['object_id'].should == 'dummy'
    end
  end

end
