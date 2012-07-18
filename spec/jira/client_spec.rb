require 'spec_helper'

describe JIRA::Client do

  let(:oauth_client) do
    JIRA::Client.new({ :consumer_key => 'foo', :consumer_secret => 'bar' })
  end

  let(:basic_client) do
    JIRA::Client.new({ :username => 'foo', :password => 'bar', :auth_type => :basic })
  end

  let(:clients) { [oauth_client, basic_client] }

  let(:response) do
    response = mock("response")
    response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  let(:headers) { {'Accept' => 'application/json'} }
  let(:content_type_header) { {'Content-Type' => 'application/json'} }
  let(:merged_headers) { headers.merge(content_type_header) }
  
  it "creates an instance" do
    clients.each {|client| client.class.should == JIRA::Client }
  end

  it "allows the overriding of some options" do
    client = JIRA::Client.new({:consumer_key => 'foo', :consumer_secret => 'bar', :site => 'http://foo.com/'})
    client.options[:site].should == 'http://foo.com/'
    JIRA::Client::DEFAULT_OPTIONS[:site].should_not == 'http://foo.com/'
  end

  it "prepends the context path to the rest base path" do
    options = [:rest_base_path]
    defaults = JIRA::Client::DEFAULT_OPTIONS
    options.each do |key|
      clients.each { |client| client.options[key].should == defaults[:context_path] + defaults[key] }
    end
  end

  # To avoid having to validate options after initialisation, e.g. setting
  # client.options[:invalid] = 'foo'
  it "freezes the options" do
    clients.each { |client| client.options.should be_frozen }
  end

  it "merges headers" do
    clients.each { |client| client.send(:merge_default_headers, {}).should == {'Accept' => 'application/json'} }
  end

  describe "creates instances of request clients" do
    specify "that are of the correct class" do
      oauth_client.request_client.class.should == JIRA::OauthClient
      basic_client.request_client.class.should == JIRA::HttpClient
    end

    specify "which have a corresponding auth type option" do
      oauth_client.options[:auth_type].should == :oauth
      basic_client.options[:auth_type].should == :basic
    end

    describe "like oauth" do

      it "allows setting an access token" do
        token = mock()
        OAuth::AccessToken.should_receive(:new).with(oauth_client.consumer, 'foo', 'bar').and_return(token)
        access_token = oauth_client.set_access_token('foo', 'bar')

        access_token.should         == token
        oauth_client.access_token.should == token
      end

      it "allows initializing the access token" do
        request_token = OAuth::RequestToken.new(oauth_client.consumer)
        oauth_client.consumer.stub(:get_request_token => request_token)
        mock_access_token = mock()
        request_token.should_receive(:get_access_token).with(:oauth_verifier => 'abc123').and_return(mock_access_token)
        oauth_client.init_access_token(:oauth_verifier => 'abc123')
        oauth_client.access_token.should == mock_access_token
      end

      specify "that has specific default options" do
        options = [:signature_method, :private_key_file]
        options.each do |key|
          oauth_client.options[key].should == JIRA::Client::DEFAULT_OPTIONS[key]
        end
      end
    end

    describe "like basic http" do
      it "sets the username and password" do
        basic_client.options[:username].should == 'foo'
        basic_client.options[:password].should == 'bar'
      end
    end
  end

  describe "has http methods" do
    before do
      oauth_client.set_access_token("foo", "bar")
    end

    specify "that merge default headers" do
      # stubbed response for generic client request method
      oauth_client.should_receive(:request).exactly(5).times.and_return(response)
      basic_client.should_receive(:request).exactly(5).times.and_return(response)

      # response for merging headers for http methods with no body
      oauth_client.should_receive(:merge_default_headers).exactly(3).times.with({})
      basic_client.should_receive(:merge_default_headers).exactly(3).times.with({})

      # response for merging headers for http methods with body
      oauth_client.should_receive(:merge_default_headers).exactly(2).times.with(content_type_header)
      basic_client.should_receive(:merge_default_headers).exactly(2).times.with(content_type_header)

      [:delete, :get, :head].each do |method|
        oauth_client.send(method, '/path', {})
        basic_client.send(method, '/path', {})
      end

      [:post, :put].each do |method|
        oauth_client.send(method, '/path', '', content_type_header)
        basic_client.send(method, '/path', '', content_type_header)
      end
    end

    specify "that call the generic request method" do
      [:delete, :get, :head].each do |method|
        oauth_client.should_receive(:request).with(method, '/path', nil, headers).and_return(response)
        basic_client.should_receive(:request).with(method, '/path', nil, headers).and_return(response)
        oauth_client.send(method, '/path', {})
        basic_client.send(method, '/path', {})
      end

      [:post, :put].each do |method|
        oauth_client.should_receive(:request).with(method, '/path', '', merged_headers)
        basic_client.should_receive(:request).with(method, '/path', '', merged_headers)
        oauth_client.send(method, '/path', '', {})
        basic_client.send(method, '/path', '', {})
      end
    end

    describe "that call a oauth client" do
      specify "which makes a request" do
        [:delete, :get, :head].each do |method|
          oauth_client.request_client.should_receive(:make_request).with(method, '/path', nil, headers).and_return(response)
          oauth_client.send(method, '/path', {})
        end
        [:post, :put].each do |method|
          oauth_client.request_client.should_receive(:make_request).with(method, '/path', '', merged_headers).and_return(response)
          oauth_client.send(method, '/path', '', {})
        end
      end
    end
    
    describe "that call a http client" do
      it "which makes a request" do
        [:delete, :get, :head].each do |method|
          basic_client.request_client.should_receive(:make_request).with(method, '/path', nil, headers).and_return(response)
          basic_client.send(method, '/path', headers)
        end
        [:post, :put].each do |method|
          basic_client.request_client.should_receive(:make_request).with(method, '/path', '', merged_headers).and_return(response)
          basic_client.send(method, '/path', '', headers)
        end
      end
    end
  end
  
  describe "Resource Factories" do
    it "gets all projects" do
      JIRA::Resource::Project.should_receive(:all).with(oauth_client).and_return([])
      JIRA::Resource::Project.should_receive(:all).with(basic_client).and_return([])
      oauth_client.Project.all.should == []
      basic_client.Project.all.should == []
    end

    it "finds a single project" do
      find_result = mock()
      JIRA::Resource::Project.should_receive(:find).with(oauth_client, '123').and_return(find_result)
      JIRA::Resource::Project.should_receive(:find).with(basic_client, '123').and_return(find_result)
      oauth_client.Project.find('123').should == find_result
      basic_client.Project.find('123').should == find_result
    end
  end
end
