require 'spec_helper'

describe JIRA::Base do

  class JIRA::Resource::Deadbeef < JIRA::Base # :nodoc:
  end

  class JIRA::Resource::HasOneExample < JIRA::Base # :nodoc:
    has_one :deadbeef
    has_one :muffin, :class => JIRA::Resource::Deadbeef
    has_one :brunchmuffin, :class => JIRA::Resource::Deadbeef,
                           :nested_under => 'nested'
    has_one :breakfastscone,
            :class => JIRA::Resource::Deadbeef,
            :nested_under => ['nested','breakfastscone']
    has_one :irregularly_named_thing,
            :class => JIRA::Resource::Deadbeef,
            :attribute_key => 'irregularlyNamedThing'
  end

  class JIRA::Resource::HasManyExample < JIRA::Base # :nodoc:
    has_many :deadbeefs
    has_many :brunchmuffins, :class => JIRA::Resource::Deadbeef,
                           :nested_under => 'nested'
    has_many :breakfastscones,
             :class => JIRA::Resource::Deadbeef,
             :nested_under => ['nested','breakfastscone']
    has_many :irregularly_named_things,
             :class => JIRA::Resource::Deadbeef,
             :attribute_key => 'irregularlyNamedThings'

  end

  let(:client)  { mock("client") }
  let(:attrs)   { Hash.new }

  subject { JIRA::Resource::Deadbeef.new(client, :attrs => attrs) }

  it "assigns the client and attrs" do
    subject.client.should == client
    subject.attrs.should  == attrs
  end

  it "returns all the deadbeefs" do
    response = mock()
    response.should_receive(:body).and_return('[{"self":"http://deadbeef/","id":"98765"}]')
    client.should_receive(:get).with('/jira/rest/api/2/deadbeef').and_return(response)
    JIRA::Resource::Deadbeef.should_receive(:rest_base_path).and_return('/jira/rest/api/2/deadbeef')
    deadbeefs = JIRA::Resource::Deadbeef.all(client)
    deadbeefs.length.should == 1
    first = deadbeefs.first
    first.class.should == JIRA::Resource::Deadbeef
    first.attrs['self'].should  == 'http://deadbeef/'
    first.attrs['id'].should   == '98765'
    first.expanded?.should be_false
  end

  it "finds a deadbeef by id" do
    response = mock()
    response.stub(:body).and_return('{"self":"http://deadbeef/","id":"98765"}')
    client.should_receive(:get).with('/jira/rest/api/2/deadbeef/98765').and_return(response)
    JIRA::Resource::Deadbeef.should_receive(:rest_base_path).and_return('/jira/rest/api/2/deadbeef')
    deadbeef = JIRA::Resource::Deadbeef.find(client, '98765')
    deadbeef.client.should == client
    deadbeef.attrs['self'].should  == 'http://deadbeef/'
    deadbeef.attrs['id'].should   == '98765'
    deadbeef.expanded?.should be_true
  end

  it "builds a deadbeef" do
    deadbeef = JIRA::Resource::Deadbeef.build(client, 'id' => "98765" )
    deadbeef.expanded?.should be_false

    deadbeef.client.should == client
    deadbeef.attrs['id'].should   == '98765'
  end

  it "returns the endpoint name" do
    subject.class.endpoint_name.should == 'deadbeef'
  end

  it "returns the path_component" do
    attrs['id'] = '123'
    subject.path_component.should == '/deadbeef/123'
  end

  it "returns the path component for unsaved instances" do
    subject.path_component.should == '/deadbeef'
  end

  it "converts to a symbol" do
    subject.to_sym.should == :deadbeef
  end

  describe "rest_base_path" do

    before(:each) do
      client.should_receive(:options).and_return(:rest_base_path => '/deadbeef/bar')
    end

    it "returns the rest_base_path" do
      subject.rest_base_path.should == '/deadbeef/bar/deadbeef'
    end

    it "returns the rest_base_path with a prefix" do
      subject.rest_base_path('/baz/').should == '/deadbeef/bar/baz/deadbeef'
    end

    it "has a class method that returns the rest_base_path" do
      subject.class.rest_base_path(client).should == '/deadbeef/bar/deadbeef'
    end
  end

  it "parses json" do
    described_class.parse_json('{"foo":"bar"}').should == {"foo" => "bar"}
  end

  describe "dynamic instance methods" do

    let(:attrs) { {'foo' => 'bar', 'flum' => 'goo', 'object_id' => 'dummy'} }
    subject     { JIRA::Resource::Deadbeef.new(client, :attrs => attrs) }

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

    subject     { JIRA::Resource::Deadbeef.new(client, :attrs => {'id' => '98765'}) }

    describe "not cached" do

      before(:each) do
        response = mock()
        response.stub(:body).and_return('{"self":"http://deadbeef/","id":"98765"}')
        client.should_receive(:get).with('/jira/rest/api/2/deadbeef/98765').and_return(response)
        JIRA::Resource::Deadbeef.should_receive(:rest_base_path).and_return('/jira/rest/api/2/deadbeef')
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
        subject.id.should  == "98765"
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

    subject { JIRA::Resource::Deadbeef.new(client) }

    before(:each) do
      subject.should_receive(:url).and_return('/foo/bar')
    end

    it "POSTs a new record" do
      response.stub(:body => '{"id":"123"}')
      subject.stub(:new_record? => true)
      client.should_receive(:post).with('/foo/bar','{"foo":"bar"}').and_return(response)
      subject.save("foo" => "bar").should be_true
      subject.id.should == "123"
      subject.expanded.should be_false
    end

    it "PUTs an existing record" do
      response.stub(:body => nil)
      subject.stub(:new_record? => false)
      client.should_receive(:put).with('/foo/bar','{"foo":"bar"}').and_return(response)
      subject.save("foo" => "bar").should be_true
      subject.expanded.should be_false
    end

    it "merges attrs on save" do
      response.stub(:body => nil)
      client.should_receive(:post).with('/foo/bar','{"foo":{"fum":"dum"}}').and_return(response)
      subject.attrs = {"foo" => {"bar" => "baz"}}
      subject.save({"foo" => {"fum" => "dum"}})
      subject.foo.should == {"bar" => "baz", "fum" => "dum"}
    end

    it "returns false when an invalid field is set" do # The JIRA REST API apparently ignores fields that you aren't allowed to set manually
      response.stub(:body => '{"errorMessages":["blah"]}', :status => 400)
      subject.stub(:new_record? => false)
      client.should_receive(:put).with('/foo/bar','{"invalid_field":"foobar"}').and_raise(JIRA::HTTPError.new(response))
      subject.save("invalid_field" => "foobar").should be_false
    end

  end

  describe "save!" do
    let(:response) { mock() }

    subject { JIRA::Resource::Deadbeef.new(client) }

    before(:each) do
      subject.should_receive(:url).and_return('/foo/bar')
    end

    it "POSTs a new record" do
      response.stub(:body => '{"id":"123"}')
      subject.stub(:new_record? => true)
      client.should_receive(:post).with('/foo/bar','{"foo":"bar"}').and_return(response)
      subject.save!("foo" => "bar").should be_true
      subject.id.should == "123"
      subject.expanded.should be_false
    end

    it "PUTs an existing record" do
      response.stub(:body => nil)
      subject.stub(:new_record? => false)
      client.should_receive(:put).with('/foo/bar','{"foo":"bar"}').and_return(response)
      subject.save!("foo" => "bar").should be_true
      subject.expanded.should be_false
    end

    it "throws an exception when an invalid field is set" do
      response.stub(:body => '{"errorMessages":["blah"]}', :status => 400)
      subject.stub(:new_record? => false)
      client.should_receive(:put).with('/foo/bar','{"invalid_field":"foobar"}').and_raise(JIRA::HTTPError.new(response))
      lambda do
        subject.save!("invalid_field" => "foobar")
      end.should raise_error(JIRA::HTTPError)
    end
  end

  describe "set_attrs" do
    it "merges hashes correctly when clobber is true (default)" do
      subject.attrs = {"foo" => {"bar" => "baz"}}
      subject.set_attrs({"foo" => {"fum" => "dum"}})
      subject.foo.should == {"fum" => "dum"}
    end

    it "merges hashes correctly when clobber is false" do
      subject.attrs = {"foo" => {"bar" => "baz"}}
      subject.set_attrs({"foo" => {"fum" => "dum"}}, false)
      subject.foo.should == {"bar" => "baz", "fum" => "dum"}
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
      subject.attrs['id'] = nil
      subject.new_record?.should be_true
    end

    it "returns false for new_record? when id is set" do
      subject.attrs['id'] = '123'
      subject.new_record?.should be_false
    end

  end

  describe "has_errors?" do

    it "returns true when the response contains errors" do
      attrs["errors"] = {"invalid" => "Field invalid"}
      subject.has_errors?.should be_true
    end

    it "returns false when the response does not contain any errors" do
      subject.has_errors?.should be_false
    end

  end

  describe 'url' do

    before(:each) do
      client.stub(:options => {:rest_base_path => '/foo/bar'})
    end

    it "returns self as the URL if set" do
      attrs['self'] = 'http://foo/bar'
      subject.url.should == "http://foo/bar"
    end

    it "generates the URL from id if self not set" do
      attrs['self'] = nil
      attrs['id'] = '98765'
      subject.url.should == "/foo/bar/deadbeef/98765"
    end

    it "generates the URL from rest_base_path if self and id not set" do
      attrs['self'] = nil
      attrs['id']  = nil
      subject.url.should == "/foo/bar/deadbeef"
    end

    it "has a class method for the collection path" do
      JIRA::Resource::Deadbeef.collection_path(client).should == "/foo/bar/deadbeef"
      #Should accept an optional prefix (flum in this case)
      JIRA::Resource::Deadbeef.collection_path(client, '/flum/').should == "/foo/bar/flum/deadbeef"
    end

    it "has a class method for the singular path" do
      JIRA::Resource::Deadbeef.singular_path(client, 'abc123').should == "/foo/bar/deadbeef/abc123"
      #Should accept an optional prefix (flum in this case)
      JIRA::Resource::Deadbeef.singular_path(client, 'abc123', '/flum/').should == "/foo/bar/flum/deadbeef/abc123"
    end
  end

  it "returns the formatted attrs from to_s" do
    subject.attrs['foo']  = 'bar'
    subject.attrs['dead'] = 'beef'

    subject.to_s.should match(/#<JIRA::Resource::Deadbeef:\d+ @attrs=#{attrs.inspect}>/)
  end

  it "returns the key attribute" do
    subject.class.key_attribute.should == :id
  end

  it "returns the key value" do
    subject.attrs['id'] = '123'
    subject.key_value.should == '123'
  end

  it "converts to json" do
    subject.attrs = {"foo" => "bar","dead" => "beef"}

    subject.to_json.should == '{"foo":"bar","dead":"beef"}'
  end

  describe "extract attrs from response" do

    subject { JIRA::Resource::Deadbeef.new(client, :attrs => {}) }

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

  describe "nesting" do

    it "defaults collection_attributes_are_nested to false" do
      JIRA::Resource::Deadbeef.collection_attributes_are_nested.should be_false
    end

    it "allows collection_attributes_are_nested to be set" do
      JIRA::Resource::Deadbeef.nested_collections true
      JIRA::Resource::Deadbeef.collection_attributes_are_nested.should be_true
    end

  end

  describe "has_many" do

    subject { JIRA::Resource::HasManyExample.new(client, :attrs => {'deadbeefs' => [{'id' => '123'}]}) }

    it "returns a collection of instances for has_many relationships" do
      subject.deadbeefs.class.should == JIRA::HasManyProxy
      subject.deadbeefs.length.should == 1
      subject.deadbeefs.each do |deadbeef|
        deadbeef.class.should == JIRA::Resource::Deadbeef
      end
    end

    it "returns an empty collection for empty has_many relationships" do
      subject = JIRA::Resource::HasManyExample.new(client)
      subject.deadbeefs.length.should == 0
    end

    it "allows the has_many attributes to be nested inside another attribute" do
      subject = JIRA::Resource::HasManyExample.new(client, :attrs => {'nested' => {'brunchmuffins' => [{'id' => '123'},{'id' => '456'}]}})
      subject.brunchmuffins.length.should == 2
      subject.brunchmuffins.each do |brunchmuffin|
        brunchmuffin.class.should == JIRA::Resource::Deadbeef
      end
    end

    it "allows it to be deeply nested" do
      subject = JIRA::Resource::HasManyExample.new(client, :attrs => {'nested' => {
        'breakfastscone' => { 'breakfastscones' => [{'id' => '123'},{'id' => '456'}] }
      }})
      subject.breakfastscones.length.should == 2
      subject.breakfastscones.each do |breakfastscone|
        breakfastscone.class.should == JIRA::Resource::Deadbeef
      end
    end

    it "short circuits missing deeply nested attrs" do
      subject = JIRA::Resource::HasManyExample.new(client, :attrs => {
                                                  'nested' => {}
      })
      subject.breakfastscones.length.should == 0
    end

    it "allows the attribute key to be specified" do
      subject = JIRA::Resource::HasManyExample.new(client, :attrs => {'irregularlyNamedThings' => [{'id' => '123'},{'id' => '456'}]})
      subject.irregularly_named_things.length.should == 2
      subject.irregularly_named_things.each do |thing|
        thing.class.should == JIRA::Resource::Deadbeef
      end
    end

    it "can build child instances" do
      deadbeef = subject.deadbeefs.build
      deadbeef.class.should == JIRA::Resource::Deadbeef
    end

  end

  describe "has_one" do

    subject { JIRA::Resource::HasOneExample.new(client, :attrs => {'deadbeef' => {'id' => '123'}}) }

    it "returns an instance for a has one relationship" do
      subject.deadbeef.class.should == JIRA::Resource::Deadbeef
      subject.deadbeef.id.should == '123'
    end

    it "returns nil when resource attribute is nonexistent" do
      subject = JIRA::Resource::HasOneExample.new(client)
      subject.deadbeef.should be_nil
    end

    it "returns an instance with a different class name to the attribute name" do
      subject = JIRA::Resource::HasOneExample.new(client, :attrs => {'muffin' => {'id' => '123'}})
      subject.muffin.class.should == JIRA::Resource::Deadbeef
      subject.muffin.id.should == '123'
    end

    it "allows the has_one attributes to be nested inside another attribute" do
      subject = JIRA::Resource::HasOneExample.new(client, :attrs => {'nested' => {'brunchmuffin' => {'id' => '123'}}})
      subject.brunchmuffin.class.should == JIRA::Resource::Deadbeef
      subject.brunchmuffin.id.should == '123'
    end

    it "allows it to be deeply nested" do
      subject = JIRA::Resource::HasOneExample.new(client, :attrs => {'nested' => {
        'breakfastscone' => { 'breakfastscone' => {'id' => '123'} }
      }})
      subject.breakfastscone.class.should == JIRA::Resource::Deadbeef
      subject.breakfastscone.id.should == '123'
    end

    it "allows the attribute key to be specified" do
      subject = JIRA::Resource::HasOneExample.new(client, :attrs => {'irregularlyNamedThing' => {'id' => '123'}})
      subject.irregularly_named_thing.class.should == JIRA::Resource::Deadbeef
      subject.irregularly_named_thing.id.should == '123'
    end

  end

  describe "belongs_to" do

    class JIRA::Resource::BelongsToExample < JIRA::Base
      belongs_to :deadbeef
    end

    let(:deadbeef) { JIRA::Resource::Deadbeef.new(client, :attrs => {'id' => "999"}) }

    subject { JIRA::Resource::BelongsToExample.new(client, :attrs => {'id' => '123'}, :deadbeef => deadbeef) }

    it "sets up an accessor for the belongs to relationship" do
      subject.deadbeef.should == deadbeef
    end

    it "raises an exception when initialized without a belongs_to instance" do
      lambda do
        JIRA::Resource::BelongsToExample.new(client, :attrs => {'id' => '123'})
      end.should raise_exception(ArgumentError,"Required option :deadbeef missing")
    end

    it "returns the right url" do
      client.stub(:options => { :rest_base_path => "/foo" })
      subject.url.should == "/foo/deadbeef/999/belongstoexample/123"
    end

    it "can be initialized with an instance or a key value" do
      client.stub(:options => { :rest_base_path => "/foo" })
      subject = JIRA::Resource::BelongsToExample.new(client, :attrs => {'id' => '123'}, :deadbeef_id => '987')
      subject.url.should == "/foo/deadbeef/987/belongstoexample/123"
    end

  end
end
