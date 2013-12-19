require 'spec_helper'

describe JIRA::OauthClient do

  let(:oauth_client) do
    options = { :consumer_key => 'foo', :consumer_secret => 'bar' }
    options = JIRA::Client::DEFAULT_OPTIONS.merge(options)
    JIRA::OauthClient.new(options)
  end

  let(:response) do
    response = double("response")
    response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    response
  end
  
  describe "authenticating with oauth" do
    it "prepends the context path to all authorization and rest paths" do
      options = [:request_token_path, :authorize_path, :access_token_path]
      defaults = JIRA::Client::DEFAULT_OPTIONS.merge(JIRA::OauthClient::DEFAULT_OPTIONS)
      options.each do |key|
        oauth_client.options[key].should == defaults[:context_path] + defaults[key]
      end
    end

    it "creates a Oauth::Consumer on initialize" do
      oauth_client.consumer.class.should == OAuth::Consumer
      oauth_client.consumer.key.should == oauth_client.key
      oauth_client.consumer.secret.should == oauth_client.secret
    end

    it "returns an OAuth request_token" do
      # Cannot just check for method delegation as http connection will be attempted
      request_token = OAuth::RequestToken.new(oauth_client.consumer)
      oauth_client.consumer.stub(:get_request_token => request_token)
      oauth_client.get_request_token.should == request_token
    end

    it "allows setting the request token" do
      token = double()
      OAuth::RequestToken.should_receive(:new).with(oauth_client.consumer, 'foo', 'bar').and_return(token)

      request_token = oauth_client.set_request_token('foo', 'bar')

      request_token.should == token
      oauth_client.request_token.should == token
    end

    it "allows setting the consumer key" do
      oauth_client.key.should == 'foo'
    end

    it "allows setting the consumer secret" do
      oauth_client.secret.should == 'bar'
    end

    describe "the access token" do

      it "initializes" do
        request_token = OAuth::RequestToken.new(oauth_client.consumer)
        oauth_client.consumer.stub(:get_request_token => request_token)
        mock_access_token = double()
        request_token.should_receive(:get_access_token).with(:oauth_verifier => 'abc123').and_return(mock_access_token)
        oauth_client.init_access_token(:oauth_verifier => 'abc123')
        oauth_client.access_token.should == mock_access_token
      end

      it "raises an exception when accessing without initialisation" do
        expect {
          oauth_client.access_token
        }.to raise_exception(JIRA::OauthClient::UninitializedAccessTokenError, 
                             "init_access_token must be called before using the client")
      end

      it "allows setting the access token" do
        token = double()
        OAuth::AccessToken.should_receive(:new).with(oauth_client.consumer, 'foo', 'bar').and_return(token)

        access_token = oauth_client.set_access_token('foo', 'bar')

        access_token.should         == token
        oauth_client.access_token.should == token
      end
    end

    describe "http" do
      it "responds to the http methods" do
        headers = double()
        mock_access_token = double()
        oauth_client.stub(:access_token => mock_access_token)
        [:delete, :get, :head].each do |method|
          mock_access_token.should_receive(method).with('/path', headers).and_return(response)
          oauth_client.make_request(method, '/path', '', headers)
        end
        [:post, :put].each do |method|
          mock_access_token.should_receive(method).with('/path', '', headers).and_return(response)
          oauth_client.make_request(method, '/path', '', headers)
        end
      end

      it "performs a request" do
        body = nil
        headers = double()
        access_token = double()
        access_token.should_receive(:send).with(:get, '/foo', headers).and_return(response)
        oauth_client.stub(:access_token => access_token)
        oauth_client.request(:get, '/foo', body, headers)
      end
    end
  end
end
