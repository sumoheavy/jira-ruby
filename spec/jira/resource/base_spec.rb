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
    client.should_receive(:get).with('/jira/rest/api/2/deadbeef').and_return(response)
    Jira::Resource::Deadbeef.should_receive(:rest_base_path).and_return('/jira/rest/api/2/deadbeef')
    deadbeefs = Jira::Resource::Deadbeef.all(client)
    deadbeefs.length.should == 1
    first = deadbeefs.first
    first.class.should == Jira::Resource::Deadbeef
    first.attrs['self'].should  == 'http://deadbeef/'
    first.attrs['key'].should   == 'FOO'
    first.expanded?.should be_false
  end

  it "finds a deadbeef by key" do
    response = mock()
    response.stub(:body).and_return('{"self":"http://deadbeef/","key":"FOO"}')
    client.should_receive(:get).with('/jira/rest/api/2/deadbeef/FOO').and_return(response)
    Jira::Resource::Deadbeef.should_receive(:rest_base_path).and_return('/jira/rest/api/2/deadbeef')
    deadbeef = Jira::Resource::Deadbeef.find(client, 'FOO')
    deadbeef.client.should == client
    deadbeef.attrs['self'].should  == 'http://deadbeef/'
    deadbeef.attrs['key'].should   == 'FOO'
    deadbeef.expanded?.should be_true
  end

  it "builds a deadbeef" do
    deadbeef = Jira::Resource::Deadbeef.build(client, 'key' => "FOO" )
    deadbeef.expanded?.should be_false

    deadbeef.client.should == client
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

  describe "fetch" do

    subject     { Jira::Resource::Deadbeef.new(client, :attrs => {'key' => 'FOO'}) }

    describe "not cached" do

      before(:each) do
        response = mock()
        response.stub(:body).and_return('{"self":"http://deadbeef/","key":"FOO"}')
        client.should_receive(:get).with('/jira/rest/api/2/deadbeef/FOO').and_return(response)
        Jira::Resource::Deadbeef.should_receive(:rest_base_path).and_return('/jira/rest/api/2/deadbeef')
      end

      it "sets expanded to true after fetch" do
        subject.expanded?.should be_false
        subject.fetch
        subject.expanded?.should be_true
      end

      it "performs a fetch" do
        subject.expanded?.should be_false
        subject.fetch
        subject.self.should == "http://deadbeef/"
        subject.key.should  == "FOO"
      end

      it "performs a fetch if already fetched and force flag is true" do
        subject.expanded = true
        subject.fetch(true)
      end

    end

    describe "cached" do
      it "doesn't perform a fetch if already fetched" do
        subject.expanded = true
        client.should_not_receive(:get)
        subject.fetch
      end
    end

  end

  describe "save" do

    let(:response) { mock() }

    subject { Jira::Resource::Deadbeef.new(client) }

    before(:each) do
      subject.should_receive(:url).and_return('/foo/bar')
      subject.should_receive(:to_json).and_return('{"foo":"bar"}')
    end

    it "POSTs a new record" do
      response.stub(:body => '{"id":"123"}')
      subject.stub(:new_record? => true)
      client.should_receive(:post).with('/foo/bar','{"foo":"bar"}').and_return(response)
      subject.save.should be_true
      subject.id.should == "123"
      subject.expanded.should be_false
    end

    it "PUTs an existing record" do
      response.stub(:body => nil)
      subject.stub(:new_record? => false)
      client.should_receive(:put).with('/foo/bar','{"foo":"bar"}').and_return(response)
      subject.save.should be_true
      subject.expanded.should be_false
    end

  end

  describe "delete" do

    before(:each) do
      client.should_receive(:delete).with('/foo/bar')
      subject.stub(:url => '/foo/bar')
    end

    it "flags itself as deleted" do
      subject.deleted?.should be_false
      subject.delete
      subject.deleted?.should be_true
    end

    it "sends a DELETE request" do
      subject.delete
    end

  end

  describe "new_record?" do

    it "returns true for new_record? when new object" do
      subject.attrs.stub(:[]).with('id').and_return(nil)
      subject.new_record?.should be_true
    end

    it "returns false for new_record? when id is set" do
      subject.attrs.stub(:[]).with('id').and_return('123')
      subject.new_record?.should be_false
    end

  end

  describe 'url' do
    it "returns self as the URL if set" do
      attrs.stub(:[]).with('self').and_return('http://foo/bar')
      subject.url.should == "http://foo/bar"
    end

    it "generates the URL from key if self not set" do
      attrs.stub(:[]).with('self').and_return(nil)
      attrs.stub(:[]).with('key').and_return('FOO')
      subject.stub(:rest_base_path => 'http://foo/bar')
      subject.url.should == "http://foo/bar/FOO"
    end

    it "generates the URL from rest_base_path if self and key not set" do
      attrs.stub(:[]).with('self').and_return(nil)
      attrs.stub(:[]).with('key').and_return(nil)
      subject.stub(:rest_base_path => 'http://foo/bar')
      subject.url.should == "http://foo/bar"
    end
  end

  it "returns the formatted attrs from to_s" do
    subject.attrs.stub(:[]).with('foo').and_return('bar')
    subject.attrs.stub(:[]).with('dead').and_return('beef')

    subject.to_s.should match(/#<Jira::Resource::Deadbeef:\d+ @attrs=#{attrs.inspect}>/)
  end

  it "returns the key attribute" do
    subject.class.key_attribute.should == :key
  end

  it "converts to json" do
    subject.attrs.stub(:to_json => '{"foo":"bar","dead":"beef"}')

    subject.to_json.should == '{"foo":"bar","dead":"beef"}'
  end

  describe "extract attrs from response" do

    subject { Jira::Resource::Deadbeef.new(client, :attrs => {}) }

    it "sets the attrs from a response" do
      response = mock()
      response.stub(:body).and_return('{"foo":"bar"}')

      subject.set_attrs_from_response(response).should == {'foo' => 'bar'}
      subject.foo.should == "bar"
    end

    it "doesn't clobber existing attrs not in response" do
      response = mock()
      response.stub(:body).and_return('{"foo":"bar"}')

      subject.attrs = {'flum' => 'flar'}
      subject.set_attrs_from_response(response).should == {'foo' => 'bar'}
      subject.foo.should == "bar"
      subject.flum.should == "flar"
    end

    it "handles nil response body" do
      response = mock()
      response.stub(:body).and_return(nil)

      subject.attrs = {'flum' => 'flar'}
      subject.set_attrs_from_response(response).should be_nil
      subject.flum.should == 'flar'
    end
  end

end
