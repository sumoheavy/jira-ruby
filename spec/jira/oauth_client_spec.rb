require 'spec_helper'

describe JIRA::OauthClient do

  let(:oauth_client) do
    options = { :consumer_key => 'foo', :consumer_secret => 'bar' }
    options = JIRA::Client::DEFAULT_OPTIONS.merge(options)
    JIRA::OauthClient.new(options)
  end

  let(:response) do
    response = double("response")
    allow(response).to receive(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  describe "authenticating with oauth" do
    it "prepends the context path to all authorization and rest paths" do
      options = [:request_token_path, :authorize_path, :access_token_path]
      defaults = JIRA::Client::DEFAULT_OPTIONS.merge(JIRA::OauthClient::DEFAULT_OPTIONS)
      options.each do |key|
        expect(oauth_client.options[key]).to eq(defaults[:context_path] + defaults[key])
      end
    end

    it "creates a Oauth::Consumer on initialize" do
      expect(oauth_client.consumer.class).to eq(OAuth::Consumer)
      expect(oauth_client.consumer.key).to eq(oauth_client.key)
      expect(oauth_client.consumer.secret).to eq(oauth_client.secret)
    end

    it "returns an OAuth request_token" do
      # Cannot just check for method delegation as http connection will be attempted
      request_token = OAuth::RequestToken.new(oauth_client.consumer)
      allow(oauth_client).to receive(:get_request_token).and_return(request_token)
      expect(oauth_client.get_request_token).to eq(request_token)
    end

    it "allows setting the request token" do
      token = double()
      expect(OAuth::RequestToken).to receive(:new).with(oauth_client.consumer, 'foo', 'bar').and_return(token)

      request_token = oauth_client.set_request_token('foo', 'bar')

      expect(request_token).to eq(token)
      expect(oauth_client.request_token).to eq(token)
    end

    it "allows setting the consumer key" do
      expect(oauth_client.key).to eq('foo')
    end

    it "allows setting the consumer secret" do
      expect(oauth_client.secret).to eq('bar')
    end

    describe "the access token" do

      it "initializes" do
        request_token = OAuth::RequestToken.new(oauth_client.consumer)
        allow(oauth_client).to receive(:get_request_token).and_return(request_token)
        mock_access_token = double()
        expect(request_token).to receive(:get_access_token).with(:oauth_verifier => 'abc123').and_return(mock_access_token)
        oauth_client.init_access_token(:oauth_verifier => 'abc123')
        expect(oauth_client.access_token).to eq(mock_access_token)
      end

      it "raises an exception when accessing without initialisation" do
        expect {
          oauth_client.access_token
        }.to raise_exception(JIRA::OauthClient::UninitializedAccessTokenError,
                             "init_access_token must be called before using the client")
      end

      it "allows setting the access token" do
        token = double()
        expect(OAuth::AccessToken).to receive(:new).with(oauth_client.consumer, 'foo', 'bar').and_return(token)

        access_token = oauth_client.set_access_token('foo', 'bar')

        expect(access_token).to eq(token)
        expect(oauth_client.access_token).to eq(token)
      end
    end

    describe "http" do
      it "responds to the http methods" do
        headers = double()
        mock_access_token = double()
        allow(oauth_client).to receive(:access_token).and_return(mock_access_token)
        [:delete, :get, :head].each do |method|
          expect(mock_access_token).to receive(method).with('/path', headers).and_return(response)
          oauth_client.make_request(method, '/path', '', headers)
        end
        [:post, :put].each do |method|
          expect(mock_access_token).to receive(method).with('/path', '', headers).and_return(response)
          oauth_client.make_request(method, '/path', '', headers)
        end
      end

      it "performs a request" do
        body = nil
        headers = double()
        access_token = double()
        expect(access_token).to receive(:send).with(:get, '/foo', headers).and_return(response)
        allow(oauth_client).to receive(:access_token).and_return(access_token)
        oauth_client.request(:get, '/foo', body, headers)
      end
    end
  end
end
