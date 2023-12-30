require 'spec_helper'
require 'oauth2'

# Translates query string from a URI into a hash.
def query_params_to_h(uri)
  uri_object = URI.parse(uri)
  uri_object.query&.split('&')&.each_with_object({}) do |param, hash |
    if /(?<key>[\w%]+)=(?<value>[-_%\w]+)/ =~ param
      hash[key] = value
    end
  end
end

describe JIRA::Oauth2Client do
  let(:site) { 'https://jira_server' }
  let(:auth_site) { 'https://auth_server' }
  let(:client_id) { 'Client ID String Value' }
  let(:client_secret) { 'Client Secret String Value' }
  let(:auth_scheme) { 'headers' }
  let(:authorize_url) { '/custom/custom_authorize_url' }
  let(:token_url) { 'custom/custom_toke_url' }
  let(:redirect_uri) { 'http:/localhost/oauth2_auth_result' }
  let(:max_redirects) { 16 }
  let(:headers) { { 'X-SECURITY' => 'D1B844A0F8BD99CA616760F1FD23CB2AE04EAFE0035203F6E73D03E6CCD24777' } }
  let(:ssl_flag) { true }
  let(:ssl_version) { :TLSv1_2 }
  let(:ssl_verify) { 0 }
  let(:ca_path) { '/etc/ssl/certs/jira_ca,pem' }
  let(:client_cert) { 'jira_client.pem' }
  let(:client_key) { 'jira_client.key' }
  let(:minimum_options) do
    {
      site: site,
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri,
    }
  end
  let(:full_options) do
    minimum_options.merge(
      {
        use_ssl: ssl_flag,
        auth_scheme: auth_scheme,
        authorize_site: auth_site,
        authorize_url: authorize_url,
        token_url: token_url,
        max_redirects: max_redirects,
        default_headers: headers,
        # oauth2_client_options: { site: auth_site }
        ssl_version: ssl_version,
        ssl_verify_mode: ssl_verify,
        cert_path: ca_path,
        ssl_client_cert: client_cert,
        ssl_client_key: client_key,
      }
    )
  end
  let(:proxy_options) do
    full_options.merge(
      {
        proxy_uri: proxy_site,
        proxy_user: proxy_user,
        proxy_password: proxy_password
      }
    )
  end

  context 'options from before any OAuth 2 client' do
    describe '.new' do
      context 'setting options' do
        subject(:request_client) do
          JIRA::Oauth2Client.new(full_options)
        end

        it 'sets oauth2 client options' do
          expect(request_client.class).to eq(JIRA::Oauth2Client)
          expect(request_client.oauth2_client.class).to eq(OAuth2::Client)
          expect(request_client.client_id).to eq(client_id)
          expect(request_client.client_secret).to eq(client_secret)
          expect(request_client.oauth2_client_options[:site]).to eq(site)
          expect(request_client.oauth2_client_options[:use_ssl]).to eq(ssl_flag)
          expect(request_client.oauth2_client_options[:auth_scheme]).to eq(auth_scheme)
          expect(request_client.oauth2_client_options[:authorize_url]).to eq(authorize_url)
          expect(request_client.oauth2_client_options[:redirect_uri]).to eq(redirect_uri)
          expect(request_client.oauth2_client_options[:token_url]).to eq(token_url)
          expect(request_client.oauth2_client_options[:max_redirects]).to eq(max_redirects)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :version)).to eq(ssl_version)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :verify)).to eq(ssl_verify)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :ca_path)).to eq(ca_path)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :client_cert)).to eq(client_cert)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :client_key)).to eq(client_key)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :headers)).to eq(headers)
          expect(request_client.oauth2_client.site).to eq(site)
          expect(request_client.oauth2_client.id).to eq(client_id)
          expect(request_client.oauth2_client.secret).to eq(client_secret)
        end
      end

      context 'using default options' do
        subject(:request_client) do
          JIRA::Oauth2Client.new(minimum_options)
        end

        it 'uses default oauth2 client options' do
          expect(request_client.class).to eq(JIRA::Oauth2Client)
          expect(request_client.oauth2_client.class).to eq(OAuth2::Client)
          expect(request_client.client_id).to eq(client_id)
          expect(request_client.client_secret).to eq(client_secret)
          expect(request_client.oauth2_client_options[:site]).to eq(site)
          expect(request_client.oauth2_client_options[:use_ssl]).to eq(JIRA::Oauth2Client::DEFAULT_OAUTH2_CLIENT_OPTIONS[:use_ssl])
          expect(request_client.oauth2_client_options[:auth_scheme]).to eq(JIRA::Oauth2Client::DEFAULT_OAUTH2_CLIENT_OPTIONS[:auth_scheme])
          expect(request_client.oauth2_client_options[:authorize_url]).to eq(JIRA::Oauth2Client::DEFAULT_OAUTH2_CLIENT_OPTIONS[:authorize_url])
          expect(request_client.oauth2_client_options[:token_url]).to eq(JIRA::Oauth2Client::DEFAULT_OAUTH2_CLIENT_OPTIONS[:token_url])
          expect(request_client.oauth2_client_options[:redirect_uri]).to eq(redirect_uri)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :version)).to be_nil
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :verify)).to be_nil
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :ca_path)).to be_nil
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :client_cert)).to be_nil
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :client_key)).to be_nil
          expect(request_client.oauth2_client_options.dig(:connection_opts, :headers)).to be_nil
          expect(request_client.oauth2_client.site).to eq(site)
          expect(request_client.oauth2_client.id).to eq(client_id)
          expect(request_client.oauth2_client.secret).to eq(client_secret)
        end
      end

      context 'using a proxy' do
        let(:proxy_site) { 'https://proxy_server' }
        let(:proxy_user) { 'ironman' }
        let(:proxy_password) { 'iamironman' }
        subject(:request_client) do
          JIRA::Oauth2Client.new(proxy_options)
        end

        it 'creates a proxy configured Oauth2::Client on initialize' do
          expect(request_client.class).to eq(JIRA::Oauth2Client)
          expect(request_client.oauth2_client.class).to eq(OAuth2::Client)
          expect(request_client.client_id).to eq(client_id)
          expect(request_client.client_secret).to eq(client_secret)
          expect(request_client.oauth2_client_options[:site]).to eq(site)
          expect(request_client.oauth2_client_options[:use_ssl]).to eq(ssl_flag)
          expect(request_client.oauth2_client_options[:auth_scheme]).to eq(auth_scheme)
          expect(request_client.oauth2_client_options[:authorize_url]).to eq(authorize_url)
          expect(request_client.oauth2_client_options[:redirect_uri]).to eq(redirect_uri)
          expect(request_client.oauth2_client_options[:token_url]).to eq(token_url)
          expect(request_client.oauth2_client_options[:max_redirects]).to eq(max_redirects)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :version)).to eq(ssl_version)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :verify)).to eq(ssl_verify)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :ca_path)).to eq(ca_path)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :client_cert)).to eq(client_cert)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :ssl, :client_key)).to eq(client_key)
          expect(request_client.oauth2_client_options.dig(:connection_opts, :headers)).to eq(headers)
          expect(request_client.oauth2_client.site).to eq(site)
          expect(request_client.oauth2_client.id).to eq(client_id)
          expect(request_client.oauth2_client.secret).to eq(client_secret)
          expect(request_client.oauth2_client.options.dig(:connection_opts, :proxy, :uri)).to eq(proxy_site)
          expect(request_client.oauth2_client.options.dig(:connection_opts, :proxy, :user)).to eq(proxy_user)
          expect(request_client.oauth2_client.options.dig(:connection_opts, :proxy, :password)).to eq(proxy_password)
        end
      end

      context 'passing options to oauth2 client' do
        let(:oauth2_client) { instance_double(OAuth2::Client) }
        subject(:request_client) do
          JIRA::Oauth2Client.new(full_options)
        end

        it 'passes oauth2 client options to creating oauth2 client' do
          expect(OAuth2::Client).to receive(:new).with(client_id, client_secret, request_client.oauth2_client_options).and_return(oauth2_client)

          oauth2_client_result = request_client.oauth2_client

          expect(oauth2_client_result).to eq(oauth2_client)
        end
      end
    end
  end

  context 'prior to Authentication Request' do
    let(:redirect_uri) { 'http://localhost/auth_response' }
    subject(:request_client) do
      JIRA::Oauth2Client.new(site: auth_site,
                             client_id: client_id,
                             client_secret: client_secret)
    end

    describe '.authorize_url' do
      let(:state_given) { 'abc-123_unme' }

      context 'default generated CSRF state' do
        it 'provides authorization redirect URI' do

          authorize_url = request_client.authorize_url(params: { redirect_uri: redirect_uri })

          expect(authorize_url).to_not be_nil
          uri = URI.parse(authorize_url)
          expect(uri.hostname).to eq(URI.parse(auth_site).hostname)
          expect(uri.path).to eq(request_client.oauth2_client_options[:authorize_url])
          query_params = query_params_to_h(authorize_url)
          expect(query_params['response_type']).to eq('code')
          expect(query_params['scope']).to eq('WRITE')
          expect(query_params['redirect_uri']).to eq( CGI.escape(redirect_uri))
          expect(query_params['state']).to_not be_nil
        end
      end

      context 'without using CSRF state' do
        it 'disables CSRF STATE' do

          authorize_url = request_client.authorize_url(state: false, params: { redirect_uri: redirect_uri })

          expect(authorize_url).to_not be_nil
          uri = URI.parse(authorize_url)
          expect(uri.hostname).to eq(URI.parse(auth_site).hostname)
          expect(uri.path).to eq(request_client.oauth2_client_options[:authorize_url])
          query_params = query_params_to_h(authorize_url)
          expect(query_params['response_type']).to eq('code')
          expect(query_params['scope']).to eq('WRITE')
          expect(query_params['redirect_uri']).to eq( CGI.escape(redirect_uri))
          expect(query_params['state']).to be_nil
        end
      end

      context 'using given CSRF state' do
        it 'uses given CSRF STATE' do

          authorize_url = request_client.authorize_url(state: state_given, params: { redirect_uri: redirect_uri })

          expect(authorize_url).to_not be_nil
          uri = URI.parse(authorize_url)
          expect(uri.hostname).to eq(URI.parse(auth_site).hostname)
          expect(uri.path).to eq(request_client.oauth2_client_options[:authorize_url])
          query_params = query_params_to_h(authorize_url)
          expect(query_params['response_type']).to eq('code')
          expect(query_params['scope']).to eq('WRITE')
          expect(query_params['redirect_uri']).to eq( CGI.escape(redirect_uri))
          expect(query_params['state']).to eq(state_given)
        end
      end

      context 'using a proxy' do
        let(:proxy_site) { 'https://proxy_server' }
        let(:proxy_user) { 'brassman' }
        let(:proxy_password) { 'iambrassman' }
        subject(:proxy_request_client) do
          params = { site: auth_site, redirect_uri: redirect_uri, proxy_uri: proxy_site, proxy_user: proxy_user, proxy_password: proxy_password }
          JIRA::Oauth2Client.new(client_id: client_id,
                                 client_secret: client_secret,
                                 site: auth_site,
                                 oauth2_client_options: params)
        end

        it 'provides authorization redirect URI' do

          params = { redirect_uri: redirect_uri, proxy_uri: proxy_site, proxy_user: proxy_user, proxy_password: proxy_password }
          authorize_url = proxy_request_client.authorize_url(params: params)

          expect(authorize_url).to_not be_nil
          uri = URI.parse(authorize_url)
          expect(uri.hostname).to eq(URI.parse(auth_site).hostname)
          expect(uri.path).to eq(request_client.oauth2_client_options[:authorize_url])
          query_params = query_params_to_h(authorize_url)
          expect(query_params['response_type']).to eq('code')
          expect(query_params['scope']).to eq('WRITE')
          expect(query_params['redirect_uri']).to eq( CGI.escape(redirect_uri))
          expect(query_params['state']).to_not be_nil
          expect(query_params['proxy_uri']).to eq( CGI.escape(proxy_site) )
          expect(query_params['proxy_user']).to eq(proxy_user)
          expect(query_params['proxy_password']).to eq(proxy_password)
        end
      end
    end
  end

  context 'with Authentication Code' do
    let(:code) { 'Authentication Code String Value' }
    let(:token) { 'Access Token String Value' }
    let(:refresh_token) { 'Refresh Token String Value' }
    subject(:request_client) do
      JIRA::Oauth2Client.new(site: site,
                             client_id: client_id,
                             client_secret: client_secret)
    end
    let(:access_token) do
      OAuth2::AccessToken.new(request_client.oauth2_client,
                              token,
                              { refresh_token: refresh_token,
                                expires_in: 3600,
                                expires_at: (Time.now + 3600).to_i })
    end

    describe '.get_token' do
      it 'makes Access Request to get token from given code' do
        expect(request_client.oauth2_client.auth_code).to receive(:get_token).and_return(access_token)

        request_client.get_token(code)

        expect(request_client.prior_grant_type).to eq('authorization_code')
        expect(request_client.token).to eq(token)
        expect(request_client.refresh_token).to eq(refresh_token)
      end
    end
  end

  context 'with Access Token' do
    let(:token) { 'Access Token String Value' }
    let(:refresh_token) { 'Refresh Token String Value' }

    describe '.new' do

      it 'sets oauth2 client from token' do

        request_client = JIRA::Oauth2Client.new(client_id: client_id,
                                                client_secret: client_secret,
                                                site: auth_site,
                                                access_token: token)

        expect(request_client.prior_grant_type).to eq('access_token')
        expect(request_client.token).to eq(token)
      end
    end
  end

  context 'with Refresh Token' do
    let(:token) { 'Prior Access Token String Value' }
    let(:refresh_token) { 'Prior Refresh Token String Value' }
    let(:token_updated) { 'Updated Access Token String Value' }
    let(:refresh_token_updated) { 'Updated Refresh Token String Value' }
    subject(:request_client) do
      JIRA::Oauth2Client.new(client_id: client_id,
                             client_secret: client_secret,
                             site: auth_site,
                             refresh_token: refresh_token)
    end
    let(:access_token_updated) do
      OAuth2::AccessToken.new(request_client.oauth2_client,
                              token_updated,
                              { refresh_token: refresh_token_updated,
                                expires_in: 3600,
                                expires_at: (Time.now + 3600).to_i })
    end

    describe '' do
      it 'refreshes the token' do
        expect(request_client.access_token).to receive(:refresh).with(grant_type: 'refresh_token', refresh_token: refresh_token).and_return(access_token_updated)

        request_client.refresh

        expect(request_client.prior_grant_type).to eq('refresh_token')
        expect(request_client.token).to eq(token_updated)
        expect(request_client.refresh_token).to eq(refresh_token_updated)
      end
    end
  end

  context 'from client using Access Token' do
    let(:oauth2_client) { instance_double(OAuth2::Client) }
    let(:token) { 'Access Token String Value' }
    let(:refresh_token) { 'Refresh Token String Value' }
    let(:redirect_uri) { 'http://localhost/auth_response' }
    let(:access_token) do
      OAuth2::AccessToken.new(oauth2_client,
                              token,
                              { refresh_token: refresh_token,
                                expires_in: 3600,
                                expires_at: (Time.now + 3600).to_i })
    end
    subject(:client) do
      JIRA::Client.new(auth_type: :oauth2,
                       client_id: client_id,
                       client_secret: client_secret,
                       site: site,
                       access_token: token,
                       refresh_token: refresh_token)
    end
    let(:response) do
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      allow(response).to receive(:body).and_return('{}')
      response
    end

    describe '.request_client.access_token' do
      it 'initializes the oauth2 Access Token' do
        # OAuth2::AccessToken.from_hash(oauth2_client, _options)
        allow(OAuth2::Client).to receive(:new).and_return(oauth2_client)
        expect(OAuth2::AccessToken).to receive(:from_hash).with(oauth2_client,
                                                                {
                                                                  token: token,
                                                                  refresh_token: refresh_token
                                                                }).and_return(access_token)

        access_token_result = client.request_client.access_token

        expect(access_token_result).to_not be_nil
        expect(access_token_result.token).to eq(token)
        expect(access_token_result.refresh_token).to eq(refresh_token)
      end
    end

    describe 'ServerInfo.all' do
      it 'makes an HTTP get request' do
        allow(OAuth2::AccessToken).to receive(:from_hash).and_return(access_token)
        expect(access_token).to receive(:get).and_return( response )

        client.request_client
        result = JIRA::Resource::ServerInfo.all(client)

      end
    end

  end
end
