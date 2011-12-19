require 'spec_helper'

describe JIRA::Client do

  subject {JIRA::Client.new('foo','bar')}

  let(:response) do
    response = mock("response")
    response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    response
  end
  
  it "creates an instance" do
    subject.class.should == JIRA::Client
  end

  it "sets consumer key" do
    subject.key.should == 'foo'
  end

  it "sets consumer secret" do
    subject.secret.should == 'bar'
  end

  it "sets the default options" do
    JIRA::Client::DEFAULT_OPTIONS.each do |key, value|
      subject.options[key].should == value
    end
  end

  it "allows the overriding of some options" do
    # Check it overrides a given option ...
    client = JIRA::Client.new('foo', 'bar', :site => 'http://foo.com/')
    client.options[:site].should == 'http://foo.com/'

    # ... but leaves the rest intact
    JIRA::Client::DEFAULT_OPTIONS.keys.reject do |key|
      key == :site
    end.each do |key|
      client.options[key].should == JIRA::Client::DEFAULT_OPTIONS[key]
    end

    JIRA::Client::DEFAULT_OPTIONS[:site].should_not == 'http://foo.com/'
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

  it "is possible to set the request token" do
    token = mock()
    OAuth::RequestToken.should_receive(:new).with(subject.consumer, 'foo', 'bar').and_return(token)

    request_token = subject.set_request_token('foo', 'bar')

    request_token.should         == token
    subject.request_token.should == token
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
      end.should raise_exception(JIRA::Client::UninitializedAccessTokenError, "init_access_token must be called before using the client")
    end

    it "is possible to set the access token" do
      token = mock()
      OAuth::AccessToken.should_receive(:new).with(subject.consumer, 'foo', 'bar').and_return(token)

      access_token = subject.set_access_token('foo', 'bar')

      access_token.should         == token
      subject.access_token.should == token
    end

  end

  describe "http" do

    it "responds to the http methods" do
      mock_access_token = mock()
      subject.stub(:access_token => mock_access_token)
      [:delete, :get, :head].each do |method|
        mock_access_token.should_receive(:request).with(method, '/path', {'Accept' => 'application/json'}).and_return(response)
        subject.send(method, '/path')
      end
      [:post, :put].each do |method|
        mock_access_token.should_receive(:request).with(method,
                                                        '/path', '',
                                                        {'Accept' => 'application/json', 'Content-Type' => 'application/json'}).and_return(response)
        subject.send(method, '/path')
      end
    end

    it "performs a request" do
      access_token = mock()
      access_token.should_receive(:request).with(:get, '/foo').and_return(response)
      subject.stub(:access_token => access_token)
      subject.request(:get, '/foo')
    end

    it "raises an exception for non success responses" do
      response = mock()
      response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(false)
      access_token = mock()
      access_token.should_receive(:request).with(:get, '/foo').and_return(response)
      subject.stub(:access_token => access_token)
      
      lambda do
        subject.request(:get, '/foo')
      end.should raise_exception(JIRA::Resource::HTTPError)
    end

  end

  describe "Resource Factories" do

    it "gets all projects" do
      JIRA::Resource::Project.should_receive(:all).with(subject).and_return([])
      subject.Project.all.should == []
    end

    it "finds a single project" do
      find_result = mock()
      JIRA::Resource::Project.should_receive(:find).with(subject, '123').and_return(find_result)
      subject.Project.find('123').should == find_result
    end

  end

end
