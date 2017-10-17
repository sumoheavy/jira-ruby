require 'spec_helper'

describe JIRA::Base do

  class JIRADelegation < SimpleDelegator # :nodoc:
  end

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

  let(:client)  { double("client") }
  let(:attrs)   { Hash.new }

  subject { JIRA::Resource::Deadbeef.new(client, :attrs => attrs) }

  let(:decorated) { JIRADelegation.new(subject) }

  describe "#respond_to?" do
    describe "when decorated using SimpleDelegator" do
      it "responds to client" do
        expect(decorated.respond_to?(:client)).to eq(true)
      end
      it "does not raise an error" do
        expect {
          decorated.respond_to?(:client)
        }.not_to raise_error
      end
    end
  end

  it "assigns the client and attrs" do
    expect(subject.client).to eq(client)
    expect(subject.attrs).to eq(attrs)
  end

  it "returns all the deadbeefs" do
    response = double()
    expect(response).to receive(:body).and_return('[{"self":"http://deadbeef/","id":"98765"}]')
    expect(client).to receive(:get).with('/jira/rest/api/2/deadbeef').and_return(response)
    expect(JIRA::Resource::Deadbeef).to receive(:collection_path).and_return('/jira/rest/api/2/deadbeef')
    deadbeefs = JIRA::Resource::Deadbeef.all(client)
    expect(deadbeefs.length).to eq(1)
    first = deadbeefs.first
    expect(first.class).to eq(JIRA::Resource::Deadbeef)
    expect(first.attrs['self']).to eq('http://deadbeef/')
    expect(first.attrs['id']).to eq('98765')
    expect(first.expanded?).to be_falsey
  end

  it "finds a deadbeef by id" do
    response = instance_double("Response", body: '{"self":"http://deadbeef/","id":"98765"}')
    expect(client).to receive(:get).with('/jira/rest/api/2/deadbeef/98765').and_return(response)
    expect(JIRA::Resource::Deadbeef).to receive(:collection_path).and_return('/jira/rest/api/2/deadbeef')
    deadbeef = JIRA::Resource::Deadbeef.find(client, '98765')
    expect(deadbeef.client).to eq(client)
    expect(deadbeef.attrs['self']).to eq('http://deadbeef/')
    expect(deadbeef.attrs['id']).to eq('98765')
    expect(deadbeef.expanded?).to be_truthy
  end

  it "finds a deadbeef containing changelog by id" do
    response = instance_double(
      "Response",
      body: '{"self":"http://deadbeef/","id":"98765","changelog":{"histories":[]}}'
    )
    expect(client).to receive(:get).with('/jira/rest/api/2/deadbeef/98765?expand=changelog').and_return(response)

    expect(JIRA::Resource::Deadbeef).to receive(:collection_path).and_return('/jira/rest/api/2/deadbeef')

    deadbeef = JIRA::Resource::Deadbeef.find(client, '98765', {expand:'changelog'})
    expect(deadbeef.client).to eq(client)
    expect(deadbeef.attrs['self']).to eq('http://deadbeef/')
    expect(deadbeef.attrs['id']).to eq('98765')
    expect(deadbeef.expanded?).to be_truthy
    expect(deadbeef.attrs['changelog']['histories']).to eq([])
  end

  it "builds a deadbeef" do
    deadbeef = JIRA::Resource::Deadbeef.build(client, 'id' => "98765" )
    expect(deadbeef.expanded?).to be_falsey

    expect(deadbeef.client).to eq(client)
    expect(deadbeef.attrs['id']).to eq('98765')
  end

  it "returns the endpoint name" do
    expect(subject.class.endpoint_name).to eq('deadbeef')
  end

  it "returns the path_component" do
    attrs['id'] = '123'
    expect(subject.path_component).to eq('/deadbeef/123')
  end

  it "returns the path component for unsaved instances" do
    expect(subject.path_component).to eq('/deadbeef')
  end

  it "converts to a symbol" do
    expect(subject.to_sym).to eq(:deadbeef)
  end

  describe "collection_path" do

    before(:each) do
      expect(client).to receive(:options).and_return(:rest_base_path => '/deadbeef/bar')
    end

    it "returns the collection_path" do
      expect(subject.collection_path).to eq('/deadbeef/bar/deadbeef')
    end

    it "returns the collection_path with a prefix" do
      expect(subject.collection_path('/baz/')).to eq('/deadbeef/bar/baz/deadbeef')
    end

    it "has a class method that returns the collection_path" do
      expect(subject.class.collection_path(client)).to eq('/deadbeef/bar/deadbeef')
    end
  end

  it "parses json" do
    expect(described_class.parse_json('{"foo":"bar"}')).to eq({"foo" => "bar"})
  end

  describe "dynamic instance methods" do

    let(:attrs) { {'foo' => 'bar', 'flum' => 'goo', 'object_id' => 'dummy'} }
    subject     { JIRA::Resource::Deadbeef.new(client, :attrs => attrs) }

    it "responds to each of the top level attribute names" do
      expect(subject).to respond_to(:foo)
      expect(subject).to respond_to('flum')
      expect(subject).to respond_to(:object_id)

      expect(subject.foo).to eq('bar')
      expect(subject.flum).to eq('goo')

      # Should not override existing method names, but should still allow
      # access to their values via the attrs[] hash
      expect(subject.object_id).not_to eq('dummy')
      expect(subject.attrs['object_id']).to eq('dummy')
    end
  end

  describe "fetch" do

    subject     { JIRA::Resource::Deadbeef.new(client, :attrs => {'id' => '98765'}) }

    describe "not cached" do

      before(:each) do
        response = instance_double("Response", body: '{"self":"http://deadbeef/","id":"98765"}')
        expect(client).to receive(:get).with('/jira/rest/api/2/deadbeef/98765').and_return(response)
        expect(JIRA::Resource::Deadbeef).to receive(:collection_path).and_return('/jira/rest/api/2/deadbeef')
      end

      it "sets expanded to true after fetch" do
        expect(subject.expanded?).to be_falsey
        subject.fetch
        expect(subject.expanded?).to be_truthy
      end

      it "performs a fetch" do
        expect(subject.expanded?).to be_falsey
        subject.fetch
        expect(subject.self).to eq("http://deadbeef/")
        expect(subject.id).to eq("98765")
      end

      it "performs a fetch if already fetched and force flag is true" do
        subject.expanded = true
        subject.fetch(true)
      end

    end

    describe "cached" do
      it "doesn't perform a fetch if already fetched" do
        subject.expanded = true
        expect(client).not_to receive(:get)
        subject.fetch
      end
    end

    context "with expand parameter 'changelog'" do
      it "fetchs changelogs '" do
        response = instance_double(
          "Response",
          body: '{"self":"http://deadbeef/","id":"98765","changelog":{"histories":[]}}'
        )
        expect(client).to receive(:get).with('/jira/rest/api/2/deadbeef/98765?expand=changelog').and_return(response)

        expect(JIRA::Resource::Deadbeef).to receive(:collection_path).and_return('/jira/rest/api/2/deadbeef')

        subject.fetch(false, {expand:'changelog'})

        expect(subject.self).to eq("http://deadbeef/")
        expect(subject.id).to eq("98765")
        expect(subject.changelog['histories']).to eq([])
      end
    end
  end

  describe "save" do

    let(:response) { double() }

    subject { JIRA::Resource::Deadbeef.new(client) }

    before(:each) do
      expect(subject).to receive(:url).and_return('/foo/bar')
    end

    it "POSTs a new record" do
      response = instance_double("Response", body: '{"id":"123"}')
      allow(subject).to receive(:new_record?) { true }
      expect(client).to receive(:post).with('/foo/bar','{"foo":"bar"}').and_return(response)
      expect(subject.save("foo" => "bar")).to be_truthy
      expect(subject.id).to eq("123")
      expect(subject.expanded).to be_falsey
    end

    it "PUTs an existing record" do
      response = instance_double("Response", body: nil)
      allow(subject).to receive(:new_record?) { false }
      expect(client).to receive(:put).with('/foo/bar','{"foo":"bar"}').and_return(response)
      expect(subject.save("foo" => "bar")).to be_truthy
      expect(subject.expanded).to be_falsey
    end

    it "merges attrs on save" do
      response = instance_double("Response", body: nil)
      expect(client).to receive(:post).with('/foo/bar','{"foo":{"fum":"dum"}}').and_return(response)
      subject.attrs = {"foo" => {"bar" => "baz"}}
      subject.save({"foo" => {"fum" => "dum"}})
      expect(subject.foo).to eq({"bar" => "baz", "fum" => "dum"})
    end

    it "returns false when an invalid field is set" do # The JIRA REST API apparently ignores fields that you aren't allowed to set manually
      response = instance_double("Response", body: '{"errorMessages":["blah"]}', status: 400)
      allow(subject).to receive(:new_record?) { false }
      expect(client).to receive(:put).with('/foo/bar','{"invalid_field":"foobar"}').and_raise(JIRA::HTTPError.new(response))
      expect(subject.save("invalid_field" => "foobar")).to be_falsey
    end

    it "returns false with exception details when non json response body (unauthorized)" do # Unauthorized requests return a non-json body. This makes sure we can handle non-json bodies on HTTPError
      response = double("Response", body: 'totally invalid json', code: 401, message: "Unauthorized")
      expect(client).to receive(:post).with('/foo/bar','{"foo":"bar"}').and_raise(JIRA::HTTPError.new(response))
      expect(subject.save("foo" => "bar")).to be_falsey
      expect(subject.attrs["exception"]["code"]).to eq(401)
      expect(subject.attrs["exception"]["message"]).to eq("Unauthorized")
    end
  end

  describe "save!" do
    let(:response) { double() }

    subject { JIRA::Resource::Deadbeef.new(client) }

    before(:each) do
      expect(subject).to receive(:url).and_return('/foo/bar')
    end

    it "POSTs a new record" do
      response = instance_double("Response", body: '{"id":"123"}')
      allow(subject).to receive(:new_record?) { true }
      expect(client).to receive(:post).with('/foo/bar','{"foo":"bar"}').and_return(response)
      expect(subject.save!("foo" => "bar")).to be_truthy
      expect(subject.id).to eq("123")
      expect(subject.expanded).to be_falsey
    end

    it "PUTs an existing record" do
      response = instance_double("Response", body: nil)
      allow(subject).to receive(:new_record?) { false }
      expect(client).to receive(:put).with('/foo/bar','{"foo":"bar"}').and_return(response)
      expect(subject.save!("foo" => "bar")).to be_truthy
      expect(subject.expanded).to be_falsey
    end

    it "throws an exception when an invalid field is set" do
      response = instance_double("Response", body: '{"errorMessages":["blah"]}', status: 400)
      allow(subject).to receive(:new_record?) { false }
      expect(client).to receive(:put).with('/foo/bar','{"invalid_field":"foobar"}').and_raise(JIRA::HTTPError.new(response))
      expect(lambda{ subject.save!("invalid_field" => "foobar") }).to raise_error(JIRA::HTTPError)
    end
  end

  describe "set_attrs" do
    it "merges hashes correctly when clobber is true (default)" do
      subject.attrs = {"foo" => {"bar" => "baz"}}
      subject.set_attrs({"foo" => {"fum" => "dum"}})
      expect(subject.foo).to eq({"fum" => "dum"})
    end

    it "merges hashes correctly when clobber is false" do
      subject.attrs = {"foo" => {"bar" => "baz"}}
      subject.set_attrs({"foo" => {"fum" => "dum"}}, false)
      expect(subject.foo).to eq({"bar" => "baz", "fum" => "dum"})
    end
  end

  describe "delete" do

    before(:each) do
      expect(client).to receive(:delete).with('/foo/bar')
      allow(subject).to receive(:url) { '/foo/bar' }
    end

    it "flags itself as deleted" do
      expect(subject.deleted?).to be_falsey
      subject.delete
      expect(subject.deleted?).to be_truthy
    end

    it "sends a DELETE request" do
      subject.delete
    end

  end

  describe "new_record?" do

    it "returns true for new_record? when new object" do
      subject.attrs['id'] = nil
      expect(subject.new_record?).to be_truthy
    end

    it "returns false for new_record? when id is set" do
      subject.attrs['id'] = '123'
      expect(subject.new_record?).to be_falsey
    end

  end

  describe "has_errors?" do

    it "returns true when the response contains errors" do
      attrs["errors"] = {"invalid" => "Field invalid"}
      expect(subject.has_errors?).to be_truthy
    end

    it "returns false when the response does not contain any errors" do
      expect(subject.has_errors?).to be_falsey
    end

  end

  describe 'url' do

    before(:each) do
      allow(client).to receive(:options) { {:rest_base_path => '/foo/bar'} }
    end

    it "returns self as the URL if set" do
      attrs['self'] = 'http://foo/bar'
      expect(subject.url).to eq("http://foo/bar")
    end

    it "generates the URL from id if self not set" do
      attrs['self'] = nil
      attrs['id'] = '98765'
      expect(subject.url).to eq("/foo/bar/deadbeef/98765")
    end

    it "generates the URL from collection_path if self and id not set" do
      attrs['self'] = nil
      attrs['id']  = nil
      expect(subject.url).to eq("/foo/bar/deadbeef")
    end

    it "has a class method for the collection path" do
      expect(JIRA::Resource::Deadbeef.collection_path(client)).to eq("/foo/bar/deadbeef")
      #Should accept an optional prefix (flum in this case)
      expect(JIRA::Resource::Deadbeef.collection_path(client, '/flum/')).to eq("/foo/bar/flum/deadbeef")
    end

    it "has a class method for the singular path" do
      expect(JIRA::Resource::Deadbeef.singular_path(client, 'abc123')).to eq("/foo/bar/deadbeef/abc123")
      #Should accept an optional prefix (flum in this case)
      expect(JIRA::Resource::Deadbeef.singular_path(client, 'abc123', '/flum/')).to eq("/foo/bar/flum/deadbeef/abc123")
    end
  end

  it "returns the formatted attrs from to_s" do
    subject.attrs['foo']  = 'bar'
    subject.attrs['dead'] = 'beef'

    expect(subject.to_s).to match(/#<JIRA::Resource::Deadbeef:\d+ @attrs=#{Regexp.quote(attrs.inspect)}>/)
  end

  it "returns the key attribute" do
    expect(subject.class.key_attribute).to eq(:id)
  end

  it "returns the key value" do
    subject.attrs['id'] = '123'
    expect(subject.key_value).to eq('123')
  end

  it "converts to json" do
    subject.attrs = { 'foo' => 'bar', 'dead' => 'beef' }
    expect(subject.to_json).to eq(subject.attrs.to_json)

    h       = { 'key' => subject }
    h_attrs = { 'key' => subject.attrs }
    expect(h.to_json).to eq(h_attrs.to_json)
  end

  describe "extract attrs from response" do

    subject { JIRA::Resource::Deadbeef.new(client, :attrs => {}) }

    it "sets the attrs from a response" do
      response = instance_double("Response", body: '{"foo":"bar"}')

      expect(subject.set_attrs_from_response(response)).to eq({'foo' => 'bar'})
      expect(subject.foo).to eq("bar")
    end

    it "doesn't clobber existing attrs not in response" do
      response = instance_double("Response", body: '{"foo":"bar"}')

      subject.attrs = {'flum' => 'flar'}
      expect(subject.set_attrs_from_response(response)).to eq({'foo' => 'bar'})
      expect(subject.foo).to eq("bar")
      expect(subject.flum).to eq("flar")
    end

    it "handles nil response body" do
      response = instance_double("Response", body: nil)

      subject.attrs = {'flum' => 'flar'}
      expect(subject.set_attrs_from_response(response)).to be_nil
      expect(subject.flum).to eq('flar')
    end
  end

  describe "nesting" do

    it "defaults collection_attributes_are_nested to false" do
      expect(JIRA::Resource::Deadbeef.collection_attributes_are_nested).to be_falsey
    end

    it "allows collection_attributes_are_nested to be set" do
      JIRA::Resource::Deadbeef.nested_collections true
      expect(JIRA::Resource::Deadbeef.collection_attributes_are_nested).to be_truthy
    end

  end

  describe "has_many" do

    subject { JIRA::Resource::HasManyExample.new(client, :attrs => {'deadbeefs' => [{'id' => '123'}]}) }

    it "returns a collection of instances for has_many relationships" do
      expect(subject.deadbeefs.class).to eq(JIRA::HasManyProxy)
      expect(subject.deadbeefs.length).to eq(1)
      subject.deadbeefs.each do |deadbeef|
        expect(deadbeef.class).to eq(JIRA::Resource::Deadbeef)
      end
    end

    it "returns an empty collection for empty has_many relationships" do
      subject = JIRA::Resource::HasManyExample.new(client)
      expect(subject.deadbeefs.length).to eq(0)
    end

    it "allows the has_many attributes to be nested inside another attribute" do
      subject = JIRA::Resource::HasManyExample.new(client, :attrs => {'nested' => {'brunchmuffins' => [{'id' => '123'},{'id' => '456'}]}})
      expect(subject.brunchmuffins.length).to eq(2)
      subject.brunchmuffins.each do |brunchmuffin|
        expect(brunchmuffin.class).to eq(JIRA::Resource::Deadbeef)
      end
    end

    it "allows it to be deeply nested" do
      subject = JIRA::Resource::HasManyExample.new(client, :attrs => {'nested' => {
        'breakfastscone' => { 'breakfastscones' => [{'id' => '123'},{'id' => '456'}] }
      }})
      expect(subject.breakfastscones.length).to eq(2)
      subject.breakfastscones.each do |breakfastscone|
        expect(breakfastscone.class).to eq(JIRA::Resource::Deadbeef)
      end
    end

    it "short circuits missing deeply nested attrs" do
      subject = JIRA::Resource::HasManyExample.new(client, :attrs => {
                                                  'nested' => {}
      })
      expect(subject.breakfastscones.length).to eq(0)
    end

    it "allows the attribute key to be specified" do
      subject = JIRA::Resource::HasManyExample.new(client, :attrs => {'irregularlyNamedThings' => [{'id' => '123'},{'id' => '456'}]})
      expect(subject.irregularly_named_things.length).to eq(2)
      subject.irregularly_named_things.each do |thing|
        expect(thing.class).to eq(JIRA::Resource::Deadbeef)
      end
    end

    it "can build child instances" do
      deadbeef = subject.deadbeefs.build
      expect(deadbeef.class).to eq(JIRA::Resource::Deadbeef)
    end

  end

  describe "has_one" do

    subject { JIRA::Resource::HasOneExample.new(client, :attrs => {'deadbeef' => {'id' => '123'}}) }

    it "returns an instance for a has one relationship" do
      expect(subject.deadbeef.class).to eq(JIRA::Resource::Deadbeef)
      expect(subject.deadbeef.id).to eq('123')
    end

    it "returns nil when resource attribute is nonexistent" do
      subject = JIRA::Resource::HasOneExample.new(client)
      expect(subject.deadbeef).to be_nil
    end

    it "returns an instance with a different class name to the attribute name" do
      subject = JIRA::Resource::HasOneExample.new(client, :attrs => {'muffin' => {'id' => '123'}})
      expect(subject.muffin.class).to eq(JIRA::Resource::Deadbeef)
      expect(subject.muffin.id).to eq('123')
    end

    it "allows the has_one attributes to be nested inside another attribute" do
      subject = JIRA::Resource::HasOneExample.new(client, :attrs => {'nested' => {'brunchmuffin' => {'id' => '123'}}})
      expect(subject.brunchmuffin.class).to eq(JIRA::Resource::Deadbeef)
      expect(subject.brunchmuffin.id).to eq('123')
    end

    it "allows it to be deeply nested" do
      subject = JIRA::Resource::HasOneExample.new(client, :attrs => {'nested' => {
        'breakfastscone' => { 'breakfastscone' => {'id' => '123'} }
      }})
      expect(subject.breakfastscone.class).to eq(JIRA::Resource::Deadbeef)
      expect(subject.breakfastscone.id).to eq('123')
    end

    it "allows the attribute key to be specified" do
      subject = JIRA::Resource::HasOneExample.new(client, :attrs => {'irregularlyNamedThing' => {'id' => '123'}})
      expect(subject.irregularly_named_thing.class).to eq(JIRA::Resource::Deadbeef)
      expect(subject.irregularly_named_thing.id).to eq('123')
    end

  end

  describe "belongs_to" do

    class JIRA::Resource::BelongsToExample < JIRA::Base
      belongs_to :deadbeef
    end

    let(:deadbeef) { JIRA::Resource::Deadbeef.new(client, :attrs => {'id' => "999"}) }

    subject { JIRA::Resource::BelongsToExample.new(client, :attrs => {'id' => '123'}, :deadbeef => deadbeef) }

    it "sets up an accessor for the belongs to relationship" do
      expect(subject.deadbeef).to eq(deadbeef)
    end

    it "raises an exception when initialized without a belongs_to instance" do
      expect(lambda {
        JIRA::Resource::BelongsToExample.new(client, :attrs => {'id' => '123'})
      }).to raise_exception(ArgumentError,"Required option :deadbeef missing")
    end

    it "returns the right url" do
      allow(client).to receive(:options) { { :rest_base_path => "/foo" } }
      expect(subject.url).to eq("/foo/deadbeef/999/belongstoexample/123")
    end

    it "can be initialized with an instance or a key value" do
      allow(client).to receive(:options) { { :rest_base_path => "/foo" } }
      subject = JIRA::Resource::BelongsToExample.new(client, :attrs => {'id' => '123'}, :deadbeef_id => '987')
      expect(subject.url).to eq("/foo/deadbeef/987/belongstoexample/123")
    end

  end
end
