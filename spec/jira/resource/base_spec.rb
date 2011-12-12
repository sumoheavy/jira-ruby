require 'spec_helper'

describe Jira::Resource::Base do

  class Jira::Resource::Deadbeef < Jira::Resource::Base ; end

  let(:client)  { mock() }
  let(:attrs)   { mock() }

  subject { Jira::Resource::Deadbeef.new(client, :attrs => attrs) }

  it "assigns the client and attrs" do
    subject.client.should == client
    subject.attrs.should  == attrs
  end

  it "returns all the deadbeefs" do
    response = mock()
    response.should_receive(:body).and_return('[{"self":"http://deadbeef/","key":"FOO"}]')
    client.should_receive(:get).with('/jira/rest/api/2.0.alpha1/deadbeef').and_return(response)
    Jira::Resource::Deadbeef.should_receive(:rest_base_path).and_return('/jira/rest/api/2.0.alpha1/deadbeef')
    deadbeefs = Jira::Resource::Deadbeef.all(client)
    deadbeefs.length.should == 1
    first = deadbeefs.first
    first.class.should == Jira::Resource::Deadbeef
    first.attrs['self'].should  == 'http://deadbeef/'
    first.attrs['key'].should   == 'FOO'
  end

  it "finds a deadbeef by key" do
    response = mock()
    response.should_receive(:body).and_return('{"self":"http://deadbeef/","key":"FOO"}')
    client.should_receive(:get).with('/jira/rest/api/2.0.alpha1/deadbeef/FOO').and_return(response)
    Jira::Resource::Deadbeef.should_receive(:rest_base_path).and_return('/jira/rest/api/2.0.alpha1/deadbeef')
    deadbeef = Jira::Resource::Deadbeef.find(client, 'FOO')
    deadbeef.client.should == client
    deadbeef.attrs['self'].should  == 'http://deadbeef/'
    deadbeef.attrs['key'].should   == 'FOO'
  end

  it "returns the endpoint name" do
    subject.class.endpoint_name.should == 'deadbeef'
  end


  describe "rest_base_path" do

    before(:each) do
      client.should_receive(:options).and_return(:rest_base_path => '/deadbeef/bar')
    end

    it "returns the rest_base_path" do
      subject.rest_base_path.should == '/deadbeef/bar/deadbeef'
    end

    it "has a class method that returns the rest_base_path" do
      subject.class.rest_base_path(client).should == '/deadbeef/bar/deadbeef'
    end
  end

  describe "dynamic instance methods" do

    let(:attrs) { {'foo' => 'bar', 'flum' => 'goo', 'object_id' => 'dummy'} }
    subject     { Jira::Resource::Deadbeef.new(client, :attrs => attrs) }

    it "responds to each of the top level attribute names" do
      subject.should respond_to(:foo)
      subject.should respond_to('flum')
      subject.should respond_to(:object_id)

      subject.foo.should  == 'bar'
      subject.flum.should == 'goo'

      # Should not override existing method names, but should still allow
      # access to their values via the attrs[] hash
      subject.object_id.should_not == 'dummy'
      subject.attrs['object_id'].should == 'dummy'
    end
  end

end
