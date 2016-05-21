require 'spec_helper'

describe JIRA::Client do
  before(:each) do
    stub_request(:post, "https://foo:bar@localhost:2990/rest/auth/1/session").
      to_return(:status => 200, :body => "", :headers => {})
  end

  let(:oauth_client) do
    JIRA::Client.new({ :consumer_key => 'foo', :consumer_secret => 'bar' })
  end

  let(:basic_client) do
    JIRA::Client.new({ :username => 'foo', :password => 'bar', :auth_type => :basic })
  end

  let(:cookie_client) do
    JIRA::Client.new({ :username => 'foo', :password => 'bar', :auth_type => :cookie })
  end

  let(:clients) { [oauth_client, basic_client, cookie_client] }

  let(:response) do
    response = double("response")
    allow(response).to receive(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  let(:headers) { {'Accept' => 'application/json'} }
  let(:content_type_header) { {'Content-Type' => 'application/json'} }
  let(:merged_headers) { headers.merge(content_type_header) }

  it "creates an instance" do
    clients.each {|client| expect(client.class).to eq(JIRA::Client) }
  end

  it "allows the overriding of some options" do
    client = JIRA::Client.new({:consumer_key => 'foo', :consumer_secret => 'bar', :site => 'http://foo.com/'})
    expect(client.options[:site]).to eq('http://foo.com/')
    expect(JIRA::Client::DEFAULT_OPTIONS[:site]).not_to eq('http://foo.com/')
  end

  it "prepends the context path to the rest base path" do
    options = [:rest_base_path]
    defaults = JIRA::Client::DEFAULT_OPTIONS
    options.each do |key|
      clients.each { |client| expect(client.options[key]).to eq(defaults[:context_path] + defaults[key]) }
    end
  end

  # To avoid having to validate options after initialisation, e.g. setting
  # client.options[:invalid] = 'foo'
  it "freezes the options" do
    clients.each { |client| expect(client.options).to be_frozen }
  end

  it "merges headers" do
    clients.each { |client| expect(client.send(:merge_default_headers, {})).to eq({'Accept' => 'application/json'}) }
  end

  describe "creates instances of request clients" do
    specify "that are of the correct class" do
      expect(oauth_client.request_client.class).to eq(JIRA::OauthClient)
      expect(basic_client.request_client.class).to eq(JIRA::HttpClient)
      expect(cookie_client.request_client.class).to eq(JIRA::HttpClient)
    end

    specify "which have a corresponding auth type option" do
      expect(oauth_client.options[:auth_type]).to eq(:oauth)
      expect(basic_client.options[:auth_type]).to eq(:basic)
      expect(cookie_client.options[:auth_type]).to eq(:cookie)
    end

    describe "like oauth" do

      it "allows setting an access token" do
        token = double()
        expect(OAuth::AccessToken).to receive(:new).with(oauth_client.consumer, 'foo', 'bar').and_return(token)
        access_token = oauth_client.set_access_token('foo', 'bar')

        expect(access_token).to eq(token)
        expect(oauth_client.access_token).to eq(token)
      end

      it "allows initializing the access token" do
        request_token = OAuth::RequestToken.new(oauth_client.consumer)
        allow(oauth_client.consumer).to receive(:get_request_token).and_return(request_token)
        mock_access_token = double()
        expect(request_token).to receive(:get_access_token).with(:oauth_verifier => 'abc123').and_return(mock_access_token)
        oauth_client.init_access_token(:oauth_verifier => 'abc123')
        expect(oauth_client.access_token).to eq(mock_access_token)
      end

      specify "that has specific default options" do
        options = [:signature_method, :private_key_file]
        options.each do |key|
          expect(oauth_client.options[key]).to eq(JIRA::Client::DEFAULT_OPTIONS[key])
        end
      end
    end

    describe "like basic http" do
      it "sets the username and password" do
        expect(basic_client.options[:username]).to eq('foo')
        expect(basic_client.options[:password]).to eq('bar')

        expect(cookie_client.options[:username]).to eq('foo')
        expect(cookie_client.options[:password]).to eq('bar')
      end
    end

  end

  describe "has http methods" do
    before do
      oauth_client.set_access_token("foo", "bar")
    end

    specify "that merge default headers" do
      # stubbed response for generic client request method
      expect(oauth_client).to receive(:request).exactly(5).times.and_return(response)
      expect(basic_client).to receive(:request).exactly(5).times.and_return(response)
      expect(cookie_client).to receive(:request).exactly(5).times.and_return(response)

      # response for merging headers for http methods with no body
      expect(oauth_client).to receive(:merge_default_headers).exactly(3).times.with({})
      expect(basic_client).to receive(:merge_default_headers).exactly(3).times.with({})
      expect(cookie_client).to receive(:merge_default_headers).exactly(3).times.with({})

      # response for merging headers for http methods with body
      expect(oauth_client).to receive(:merge_default_headers).exactly(2).times.with(content_type_header)
      expect(basic_client).to receive(:merge_default_headers).exactly(2).times.with(content_type_header)
      expect(cookie_client).to receive(:merge_default_headers).exactly(2).times.with(content_type_header)

      [:delete, :get, :head].each do |method|
        oauth_client.send(method, '/path', {})
        basic_client.send(method, '/path', {})
        cookie_client.send(method, '/path', {})
      end

      [:post, :put].each do |method|
        oauth_client.send(method, '/path', '', content_type_header)
        basic_client.send(method, '/path', '', content_type_header)
        cookie_client.send(method, '/path', '', content_type_header)
      end
    end

    specify "that call the generic request method" do
      [:delete, :get, :head].each do |method|
        expect(oauth_client).to receive(:request).with(method, '/path', nil, headers).and_return(response)
        expect(basic_client).to receive(:request).with(method, '/path', nil, headers).and_return(response)
        expect(cookie_client).to receive(:request).with(method, '/path', nil, headers).and_return(response)
        oauth_client.send(method, '/path', {})
        basic_client.send(method, '/path', {})
        cookie_client.send(method, '/path', {})
      end

      [:post, :put].each do |method|
        expect(oauth_client).to receive(:request).with(method, '/path', '', merged_headers)
        expect(basic_client).to receive(:request).with(method, '/path', '', merged_headers)
        expect(cookie_client).to receive(:request).with(method, '/path', '', merged_headers)
        oauth_client.send(method, '/path', '', {})
        basic_client.send(method, '/path', '', {})
        cookie_client.send(method, '/path', '', {})
      end
    end

    describe "that call a oauth client" do
      specify "which makes a request" do
        [:delete, :get, :head].each do |method|
          expect(oauth_client.request_client).to receive(:make_request).with(method, '/path', nil, headers).and_return(response)
          oauth_client.send(method, '/path', {})
        end
        [:post, :put].each do |method|
          expect(oauth_client.request_client).to receive(:make_request).with(method, '/path', '', merged_headers).and_return(response)
          oauth_client.send(method, '/path', '', {})
        end
      end
    end

    describe "that call a http client" do
      it "which makes a request" do
        [:delete, :get, :head].each do |method|
          expect(basic_client.request_client).to receive(:make_request).with(method, '/path', nil, headers).and_return(response)
          basic_client.send(method, '/path', headers)

          expect(cookie_client.request_client).to receive(:make_request).with(method, '/path', nil, headers).and_return(response)
          cookie_client.send(method, '/path', headers)
        end
        [:post, :put].each do |method|
          expect(basic_client.request_client).to receive(:make_request).with(method, '/path', '', merged_headers).and_return(response)
          basic_client.send(method, '/path', '', headers)

          expect(cookie_client.request_client).to receive(:make_request).with(method, '/path', '', merged_headers).and_return(response)
          cookie_client.send(method, '/path', '', headers)
        end
      end
    end
  end

  describe "Resource Factories" do
    it "gets all projects" do
      expect(JIRA::Resource::Project).to receive(:all).with(oauth_client).and_return([])
      expect(JIRA::Resource::Project).to receive(:all).with(basic_client).and_return([])
      expect(JIRA::Resource::Project).to receive(:all).with(cookie_client).and_return([])

      expect(oauth_client.Project.all).to eq([])
      expect(basic_client.Project.all).to eq([])
      expect(cookie_client.Project.all).to eq([])
    end

    it "finds a single project" do
      find_result = double()
      expect(JIRA::Resource::Project).to receive(:find).with(oauth_client, '123').and_return(find_result)
      expect(JIRA::Resource::Project).to receive(:find).with(basic_client, '123').and_return(find_result)
      expect(JIRA::Resource::Project).to receive(:find).with(cookie_client, '123').and_return(find_result)

      expect(oauth_client.Project.find('123')).to eq(find_result)
      expect(basic_client.Project.find('123')).to eq(find_result)
      expect(cookie_client.Project.find('123')).to eq(find_result)
    end
  end
end
