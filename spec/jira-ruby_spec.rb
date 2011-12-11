require 'spec_helper'

describe JiraRuby::Client do

  subject {JiraRuby::Client.new('foo','bar')}
  
  it "creates an instance" do
    subject.class.should == JiraRuby::Client
  end

  it "sets consumer key" do
    subject.key.should == 'foo'
  end

  it "sets consumer secret" do
    subject.secret.should == 'bar'
  end

  it "sets the default options" do
    JiraRuby::Client::DEFAULT_OPTIONS.each do |key, value|
      subject.options[key].should == value
    end
  end

  it "allows the overriding of some options" do
    # Check it overrides a given option ...
    client = JiraRuby::Client.new('foo', 'bar', :site => 'http://foo.com/')
    client.options[:site].should == 'http://foo.com/'

    # ... but leaves the rest intact
    JiraRuby::Client::DEFAULT_OPTIONS.keys.reject do |key|
      key == :site
    end.each do |key|
      client.options[key].should == JiraRuby::Client::DEFAULT_OPTIONS[key]
    end

    JiraRuby::Client::DEFAULT_OPTIONS[:site].should_not == 'http://foo.com/'
  end

  # To avoid having to validate options after initialisation, e.g. setting
  # client.options[:invalid] = 'foo'
  it "freezes the options" do
    subject.options.should be_frozen
  end

  it "creates a Oauth::Consumer on initialize" do
    subject.consumer.class.should == OAuth::Consumer
    subject.consumer.key.should == subject.key
    subject.consumer.secret.should == subject.secret
  end

  it "returns an OAuth request_token" do
    # Cannot just check for method delegation as http connection will be attempted
    request_token = OAuth::RequestToken.new(subject.consumer)
    subject.consumer.stub(:get_request_token => request_token)
    subject.get_request_token.should == request_token
  end

  describe "access token" do

    it "initializes the access token" do
      request_token = OAuth::RequestToken.new(subject.consumer)
      subject.consumer.stub(:get_request_token => request_token)
      mock_access_token = mock()
      request_token.should_receive(:get_access_token).with(:oauth_verifier => 'abc123').and_return(mock_access_token)
      subject.init_access_token(:oauth_verifier => 'abc123')
      subject.access_token.should == mock_access_token
    end

    it "raises an exception when accessing without initialisation" do
      lambda do
        subject.access_token
      end.should raise_exception(JiraRuby::Client::UninitializedAccessTokenError, "init_access_token must be called before using the client")
    end

  end

  describe "http" do

    it "responds to the http methods" do
      mock_access_token = mock()
      subject.stub(:access_token => mock_access_token)
      [:delete, :get, :head].each do |method|
        mock_access_token.should_receive(:request).with(method, '/path', {'Accept' => 'application/json'})
        subject.send(method, '/path')
      end
      [:post, :put].each do |method|
        mock_access_token.should_receive(:request).with(method, '/path', '', {'Accept' => 'application/json'})
        subject.send(method, '/path')
      end
    end

  end

end
