require 'spec_helper'

describe JIRA::OauthClient do
  let(:oauth_client) do
    options = { consumer_key: 'foo', consumer_secret: 'bar' }
    options = JIRA::Client::DEFAULT_OPTIONS.merge(options)
    JIRA::OauthClient.new(options)
  end

  let(:response) do
    response = double('response')
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  describe 'authenticating with oauth' do
    it 'prepends the context path to all authorization and rest paths' do
      options = %i[request_token_path authorize_path access_token_path]
      defaults = JIRA::Client::DEFAULT_OPTIONS.merge(JIRA::OauthClient::DEFAULT_OPTIONS)
      options.each do |key|
        expect(oauth_client.options[key]).to eq(defaults[:context_path] + defaults[key])
      end
    end

    it 'creates a Oauth::Consumer on initialize' do
      expect(oauth_client.consumer.class).to eq(OAuth::Consumer)
      expect(oauth_client.consumer.key).to eq(oauth_client.key)
      expect(oauth_client.consumer.secret).to eq(oauth_client.secret)
    end

    it 'returns an OAuth request_token' do
      # Cannot just check for method delegation as http connection will be attempted
      request_token = OAuth::RequestToken.new(oauth_client.consumer)
      allow(oauth_client).to receive(:get_request_token).and_return(request_token)
      expect(oauth_client.get_request_token).to eq(request_token)
    end

    it 'could pre-process the response body in a block' do
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      allow_any_instance_of(OAuth::Consumer).to receive(:request).and_return(response)
      allow(response).to receive(:body).and_return('&oauth_token=token&oauth_token_secret=secret&password=top_secret')

      result = oauth_client.request_token do |response_body|
        CGI.parse(response_body).each_with_object({}) do |(k, v), h|
          next if k == 'password'

          h[k.strip.to_sym] = v.first
        end
      end

      expect(result).to be_an_instance_of(OAuth::RequestToken)
      expect(result.consumer).to eql(oauth_client.consumer)
      expect(result.params[:oauth_token]).to eql('token')
      expect(result.params[:oauth_token_secret]).to eql('secret')
      expect(result.params[:password]).to be_falsey
    end

    it 'allows setting the request token' do
      token = double
      expect(OAuth::RequestToken).to receive(:new).with(oauth_client.consumer, 'foo', 'bar').and_return(token)

      request_token = oauth_client.set_request_token('foo', 'bar')

      expect(request_token).to eq(token)
      expect(oauth_client.request_token).to eq(token)
    end

    it 'allows setting the consumer key' do
      expect(oauth_client.key).to eq('foo')
    end

    it 'allows setting the consumer secret' do
      expect(oauth_client.secret).to eq('bar')
    end

    describe 'the access token' do
      it 'initializes' do
        request_token = OAuth::RequestToken.new(oauth_client.consumer)
        allow(oauth_client).to receive(:get_request_token).and_return(request_token)
        mock_access_token = double
        expect(request_token).to receive(:get_access_token).with({ oauth_verifier: 'abc123' }).and_return(mock_access_token)
        oauth_client.init_access_token(oauth_verifier: 'abc123')
        expect(oauth_client.access_token).to eq(mock_access_token)
      end

      it 'raises an exception when accessing without initialisation' do
        expect do
          oauth_client.access_token
        end.to raise_exception(JIRA::OauthClient::UninitializedAccessTokenError,
                               'init_access_token must be called before using the client')
      end

      it 'allows setting the access token' do
        token = double
        expect(OAuth::AccessToken).to receive(:new).with(oauth_client.consumer, 'foo', 'bar').and_return(token)

        access_token = oauth_client.set_access_token('foo', 'bar')

        expect(access_token).to eq(token)
        expect(oauth_client.access_token).to eq(token)
      end
    end

    describe 'http' do
      let(:headers) { double }
      let(:access_token) { double }
      let(:body) { nil }

      before do
        allow(oauth_client).to receive(:access_token).and_return(access_token)
      end

      it 'responds to the http methods' do
        %i[delete get head].each do |method|
          expect(access_token).to receive(method).with('/path', headers).and_return(response)
          oauth_client.make_request(method, '/path', '', headers)
        end
        %i[post put].each do |method|
          expect(access_token).to receive(method).with('/path', '', headers).and_return(response)
          oauth_client.make_request(method, '/path', '', headers)
        end
      end

      it 'performs a request' do
        expect(access_token).to receive(:send).with(:get, '/foo', headers).and_return(response)


        oauth_client.request(:get, '/foo', body, headers)
      end

      context 'for a multipart request' do
        subject { oauth_client.make_multipart_request('/path', data, headers) }

        let(:data) { {} }
        let(:headers) { {} }

        it 'signs the access_token and performs the request' do
          expect(access_token).to receive(:sign!).with(an_instance_of(Net::HTTP::Post::Multipart))
          expect(oauth_client.consumer).to receive_message_chain(:http, :request).with(an_instance_of(Net::HTTP::Post::Multipart))

          subject
        end
      end
    end

    describe 'auth type is oauth_2legged' do
      let(:oauth__2legged_client) do
        options = { consumer_key: 'foo', consumer_secret: 'bar', auth_type: :oauth_2legged }
        options = JIRA::Client::DEFAULT_OPTIONS.merge(options)
        JIRA::OauthClient.new(options)
      end

      it 'responds to the http methods adding oauth_token parameter' do
        headers = double
        mock_access_token = double
        allow(oauth__2legged_client).to receive(:access_token).and_return(mock_access_token)
        %i[delete get head].each do |method|
          expect(mock_access_token).to receive(method).with('/path?oauth_token=', headers).and_return(response)
          oauth__2legged_client.make_request(method, '/path', '', headers)
        end
        %i[post put].each do |method|
          expect(mock_access_token).to receive(method).with('/path?oauth_token=', '', headers).and_return(response)
          oauth__2legged_client.make_request(method, '/path', '', headers)
        end
      end

      it 'responds to the http methods adding oauth_token parameter to any existing parameters' do
        headers = double
        mock_access_token = double
        allow(oauth__2legged_client).to receive(:access_token).and_return(mock_access_token)
        %i[delete get head].each do |method|
          expect(mock_access_token).to receive(method).with('/path?any_param=toto&oauth_token=', headers).and_return(response)
          oauth__2legged_client.make_request(method, '/path?any_param=toto', '', headers)
        end
        %i[post put].each do |method|
          expect(mock_access_token).to receive(method).with('/path?any_param=toto&oauth_token=', '', headers).and_return(response)
          oauth__2legged_client.make_request(method, '/path?any_param=toto', '', headers)
        end
      end
    end
  end
end
