require 'oauth2'

module JIRA
  # Client using OAuth 2.0
  #
  # == OAuth 2.0 Overview
  #
  # OAuth 2.0 sepearates the roles of Resource Server and Authentication Server.
  #
  # The Resource Server will be Jira.
  # The Authentication Server can be Jira or some other OAuth 2.0 Authentication server.
  # For example you can use Git Hub Enterprise allowing all your GHE users are users which can use the Jira REST API.
  #
  # The impact of this is that while this gem handles calls to Jira as the Resource Server,
  # communication with the Authentication Server may be out of the scope of this gem.
  # Where other Request Clients authenticate and call the Jira REST API,
  # calling code must authenticate and pass the credentials to this class which can then call the API.
  #
  # The Resource Server and the Authentication Server need to communicate with each other,
  # and require clients of the Resource Server
  # to communicate reflecting its communication with the Authentication Server
  # as a necessity of secure authentication.
  # Where this Request Client can support authentication is facilitating that consistent communication.
  # It helps format the Authentication Request in a way which will be needed with the Resource Server
  # and it accepts initialization from the OAuth 2.0 authentication.
  #
  # While a single threaded web application can keep the same Request Client object,
  # a multi-process one may need to initialize the Request Client from an Access Token.
  # This requires different initialization for making an Authentication Request, using an Access Token,
  # and another way for refreshing the Access Token.
  #
  # === Authentication Request
  #
  # When no credentials have been established, the first step is to redirect to the Authentication Server
  # to make an Authorization Request.
  # That server will serve any needed web forms.
  #
  # When the Authentication Request is successful, it will redirect to a call back URI which was provided.
  #
  # === Access Request
  #
  # A successful Authentication Request sends an Authentication Code to the callback URI.
  # This is used to make an Access Request which provides an Access Token,
  # a Refresh Token, and the expiration timestamp.
  #
  #
  #
  # == Process
  #
  # === Register Client
  #
  # Register your application with the Authentication Server.
  # This will provide a Client ID and a Client SECRET used by OAuth 2.0.
  #
  # === Authentication Request
  #
  # Get the URI to redirect for the Authentication Request from this RequestClient.
  #
  # === Implement Callback
  #
  # Implement the callback URI in your app for the result of the Authentication Request.
  #
  # Verify the CSRF Prevention State.
  # This is a value sent to the Authentication Server which is sent to the callback.
  # This is a value that a forger would not be able to provide.
  #
  # To be secure, this should not be compared with some other part of the HTTP request to the callback,
  # such as in a cookie or session.
  #
  # === Access Request.
  #
  # The callback next makes a call to this RequestClient to use the Authentication Code to get the Access Token.
  # This Access Token is used to make Jira REST API calls using OAuth 2.0.
  #
  # @example Make Authentication Request
  #   code code code
  #   code code code
  #
  # @example Authentication Result and Access Request
  #   code code code
  #   code code code
  #
  # @example Refresh Token
  #   code code code
  #   code code code
  #
  # @example Call Jira API
  #   code code code
  #   code code code
  #
  # @since 0.2.4
  #
  # @!attribute [r] client_id
  #   @return [String] The CLIENT ID registered with the Authentication Server
  # @!attribute [r] client_secret
  #   @return [String] The CLIENT SECRET registered with the Authentication Server
  # @!attribute [r] cstf_state
  #   @return [String] An unpredictable value which a CSRF forger would not be able to provide
  # @!attribute [r] oauth2_client
  #   @return [OAuth2::Client] The oauth2 gem client object used.
  # @!attribute [r] options
  #   @return [Hash] The oauth2 gem options for the client object.
  #
  class Oauth2Client < RequestClient

    # @private
    OAUTH2_CLIENT_OPTIONS_KEYS =
      %i[auth_scheme authorize_url redirect_uri token_url max_redirects site
         use_ssl ssl_verify_mode ssl_version]
    # @private
    DEFAULT_AUTHORIZE_OPTIONS = {
      authorize_url: '/rest/oauth2/latest/authorize',
      auth_scheme: 'request_body'
    }.freeze
    # @private
    DEFAULT_OAUTH2_CLIENT_OPTIONS = {
      auth_scheme: 'request_body',
      authorize_url: '/rest/oauth2/latest/authorize',
      token_url: '/rest/oauth2/latest/token'
    }.freeze
    DEFAULT_OPTIONS = {
      token_url: '/rest/oauth2/latest/token',
    }.freeze
    attr_reader :prior_grant_type, :access_token
    # attr_reader :options
    attr_reader :oauth2_client_options, :client_id, :client_secret, :csrf_state

    # @param [Hash] options
    # @option options [String] :client_id The registered client id
    # @option options [String] :client_secret The registered client secret
    # @option options [String] :site The hostname of the Authentication Server
    # @option options [String] :authorize_url The Authorization Request URI (default '/rest/oauth2/latest/authorize')
    # @option options [String] :token_url The Jira Resource Server Access Request URI (default '/rest/oauth2/latest/token')
    # @option options [String] :auth_scheme Way of passing parameters for authentication (default 'request_body')
    # @option options [String] :redirect_uri Callback for result of Authentication Request
    # @option options [String] :proxy_uri Proxy URI
    # @option options [String] :proxy_user Proxy user
    # @option options [String] :proxy_password Proxy Password
    def initialize(options = {})
      @options = init_oauth2_options(options)
      if options.has_key?(:access_token_options)
        @access_token = access_token_from_options(options[:access_token_options])
      end
    end

    # @private
    private def init_oauth2_options(options)
      # byebug
      options_local = options.dup
      @client_id = options_local.delete(:client_id)
      @client_secret = options_local.delete(:client_secret)

      options_local = DEFAULT_OAUTH2_CLIENT_OPTIONS.merge(options)
      # @oauth2_client_options = DEFAULT_AUTHORIZE_OPTIONS.merge(options_local.delete(:oauth2_client_options) || {})
      # @oauth2_client_options = DEFAULT_AUTHORIZE_OPTIONS.merge(options_local.delete(:oauth2_client_options) || {})
      @oauth2_client_options = options_local.slice(*OAUTH2_CLIENT_OPTIONS_KEYS)


      @oauth2_client_options[:connection_opts] ||= {}


      @oauth2_client_options[:connection_opts][:headers] ||= options[:default_headers] if options[:default_headers]


      if options[:use_ssl]
        @oauth2_client_options[:connection_opts][:ssl] ||= {}
        @oauth2_client_options[:connection_opts][:ssl][:version] = options[:ssl_version] if options[:ssl_version]
        @oauth2_client_options[:connection_opts][:ssl][:verify] = options[:ssl_verify_mode] if options[:ssl_verify_mode]
        @oauth2_client_options[:connection_opts][:ssl][:ca_path] = options[:cert_path] if options[:cert_path]
        @oauth2_client_options[:connection_opts][:ssl][:client_cert] = options[:ssl_client_cert] if options[:ssl_client_cert]
        @oauth2_client_options[:connection_opts][:ssl][:client_key] = options[:ssl_client_key] if options[:ssl_client_key]
      end


      proxy_uri = oauth2_client_options.delete(:proxy_uri)
      proxy_user = oauth2_client_options.delete(:proxy_user)
      proxy_password = oauth2_client_options.delete(:proxy_password)
      if proxy_uri
        @oauth2_client_options[:connection_opts][:proxy] ||= {}
        proxy_opts = @oauth2_client_options[:connection_opts][:proxy]
        proxy_opts[:uri] = proxy_uri
        proxy_opts[:user] = proxy_user if proxy_user
        proxy_opts[:password] = proxy_password if proxy_password
      end

      @oauth2_client_options
    end

    # @private
    # private def init_oauth2_client(oauth2_client_options)
    #   OAuth2::Client.new(client_id,
    #                      client_secret,
    #                      oauth2_client_options)
    # end

    def oauth2_client
      @oauth2_client ||=
        OAuth2::Client.new(client_id,
                           client_secret,
                           oauth2_client_options)

    end

    def access_token_from_options(_options)
      @prior_grant_type = 'access_token'
      OAuth2::AccessToken.from_hash(oauth2_client, _options)
    end

    # @private
    private def init_access_token(_options)
      @prior_grant_type = 'access_token'
      hash = { token: _options[:token], refresh_token: _options[:refresh_token] }
      OAuth2::AccessToken.from_hash(oauth2_client, hash)
    end

    # @private
    private def generate_encoded_state
      ran = OpenSSL::Random.random_bytes(32)
      Base64.encode64(ran).strip.gsub('+', '-').gsub('/', '_')
    end

    # Provides redirect URI for Authentication Request.
    #
    # Making an Authenticaiton Request requires redirecting to a URI on the Authentication Server.
    #
    # @param [String] scope The scope (default 'WRITE')
    # @param [String] state Provided state or false to use no state (default random 32 bytes)
    # @param [Hash] params Additional parameters to pass to the oauth2 gem.
    # @option params [String,NilClass] :redirect_uri Callback for result of Authentication Request
    # @return [String] URI to redirect to for Authentication Request
    def authorize_url(scope: "WRITE", state: nil, params: {})
      params = params.dup
      params[:scope] = scope

      unless false == state
        @csrf_state = state || generate_encoded_state
        params[:state] = @csrf_state
      end

      oauth2_client.auth_code.authorize_url(params)
    end

    def get_token(code, opts = {})
      @prior_grant_type = 'authorization_code'
      @access_token = oauth2_client.auth_code.get_token(code, { :redirect_uri => oauth2_client.options[:authorize_url] }, opts)
    end

    def token
      access_token&.token
    end

    def refresh_token
      access_token&.refresh_token
    end

    def expires_at
      access_token&.expires_at
    end

    def refresh
      @prior_grant_type = 'refresh_token'
      @access_token = @access_token.refresh(grant_type: 'refresh_token', refresh_token: refresh_token)
    end

    def make_request(http_method, url, body = '', headers = {})
      access_token.send(http_method, url, headers)
    end
  end
end
