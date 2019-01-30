require 'spec_helper'

describe JIRA::HttpClient do
  let(:basic_client) do
    options = JIRA::Client::DEFAULT_OPTIONS
              .merge(JIRA::HttpClient::DEFAULT_OPTIONS)
              .merge(basic_auth_credentials)
    JIRA::HttpClient.new(options)
  end

  let(:basic_cookie_client) do
    options = JIRA::Client::DEFAULT_OPTIONS
              .merge(JIRA::HttpClient::DEFAULT_OPTIONS)
              .merge(use_cookies: true)
              .merge(basic_auth_credentials)
    JIRA::HttpClient.new(options)
  end

  let(:custom_ssl_version_client) do
    options = JIRA::Client::DEFAULT_OPTIONS.merge(JIRA::HttpClient::DEFAULT_OPTIONS).merge(ssl_version: :TLSv1_2)
    JIRA::HttpClient.new(options)
  end

  let(:basic_cookie_client_with_context_path) do
    options = JIRA::Client::DEFAULT_OPTIONS.merge(JIRA::HttpClient::DEFAULT_OPTIONS).merge(
      use_cookies: true,
      context_path: '/context'
    )
    JIRA::HttpClient.new(options)
  end

  let(:basic_cookie_client_with_additional_cookies) do
    options = JIRA::Client::DEFAULT_OPTIONS
              .merge(JIRA::HttpClient::DEFAULT_OPTIONS)
              .merge(
                use_cookies: true,
                additional_cookies: ['sessionToken=abc123', 'internal=true']
              )
              .merge(basic_auth_credentials)
    JIRA::HttpClient.new(options)
  end

  let(:basic_client_cert_client) do
    options = JIRA::Client::DEFAULT_OPTIONS.merge(JIRA::HttpClient::DEFAULT_OPTIONS).merge(
      use_client_cert: true,
      cert: 'public certificate contents',
      key: 'private key contents'
    )
    JIRA::HttpClient.new(options)
  end

  let(:basic_client_with_no_auth_credentials) do
    options = JIRA::Client::DEFAULT_OPTIONS
              .merge(JIRA::HttpClient::DEFAULT_OPTIONS)
    JIRA::HttpClient.new(options)
  end

  let(:basic_auth_credentials) do
    { username: 'donaldduck', password: 'supersecret' }
  end

  let(:response) do
    response = double('response')
    allow(response).to receive(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  let(:cookie_response) do
    response = double('response')
    allow(response).to receive(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  it 'creates an instance of Net:HTTP for a basic auth client' do
    expect(basic_client.basic_auth_http_conn.class).to eq(Net::HTTP)
  end

  it 'makes a correct HTTP request for make_cookie_auth_request' do
    request = double
    basic_auth_http_conn = double

    headers = { 'Content-Type' => 'application/json' }
    expected_path = '/context/rest/auth/1/session'
    expected_body = '{"username":"","password":""}'

    allow(basic_cookie_client_with_context_path).to receive(:basic_auth_http_conn).and_return(basic_auth_http_conn)
    expect(basic_auth_http_conn).to receive(:request).with(request).and_return(response)

    allow(request).to receive(:basic_auth)
    allow(response).to receive(:get_fields).with('set-cookie')

    expect(request).to receive(:body=).with(expected_body)
    expect(Net::HTTP.const_get(:post.to_s.capitalize)).to receive(:new).with(expected_path, headers).and_return(request)

    basic_cookie_client_with_context_path.make_cookie_auth_request
  end

  it 'responds to the http methods' do
    body = ''
    headers = double
    basic_auth_http_conn = double
    request = double
    allow(basic_client).to receive(:basic_auth_http_conn).and_return(basic_auth_http_conn)
    expect(request).to receive(:basic_auth).with(basic_client.options[:username], basic_client.options[:password]).exactly(5).times.and_return(request)
    expect(basic_auth_http_conn).to receive(:request).exactly(5).times.with(request).and_return(response)
    %i[delete get head].each do |method|
      expect(Net::HTTP.const_get(method.to_s.capitalize)).to receive(:new).with('/path', headers).and_return(request)
      expect(basic_client.make_request(method, '/path', nil, headers)).to eq(response)
    end
    %i[post put].each do |method|
      expect(Net::HTTP.const_get(method.to_s.capitalize)).to receive(:new).with('/path', headers).and_return(request)
      expect(request).to receive(:body=).with(body).and_return(request)
      expect(basic_client.make_request(method, '/path', body, headers)).to eq(response)
    end
  end

  it 'gets and sets cookies' do
    body = ''
    headers = double
    basic_auth_http_conn = double
    request = double
    allow(basic_cookie_client).to receive(:basic_auth_http_conn).and_return(basic_auth_http_conn)
    expect(request).to receive(:basic_auth).with(basic_cookie_client.options[:username], basic_cookie_client.options[:password]).exactly(5).times.and_return(request)
    expect(cookie_response).to receive(:get_fields).with('set-cookie').exactly(5).times
    expect(basic_auth_http_conn).to receive(:request).exactly(5).times.with(request).and_return(cookie_response)
    %i[delete get head].each do |method|
      expect(Net::HTTP.const_get(method.to_s.capitalize)).to receive(:new).with('/path', headers).and_return(request)
      expect(basic_cookie_client.make_request(method, '/path', nil, headers)).to eq(cookie_response)
    end
    %i[post put].each do |method|
      expect(Net::HTTP.const_get(method.to_s.capitalize)).to receive(:new).with('/path', headers).and_return(request)
      expect(request).to receive(:body=).with(body).and_return(request)
      expect(basic_cookie_client.make_request(method, '/path', body, headers)).to eq(cookie_response)
    end
  end

  it 'sets additional cookies when they are provided' do
    client = basic_cookie_client_with_additional_cookies
    body = ''
    headers = double
    basic_auth_http_conn = double
    request = double
    allow(client).to receive(:basic_auth_http_conn).and_return(basic_auth_http_conn)
    expect(request).to receive(:basic_auth).with(client.options[:username], client.options[:password]).exactly(5).times.and_return(request)
    expect(request).to receive(:add_field).with('Cookie', 'sessionToken=abc123; internal=true').exactly(5).times
    expect(cookie_response).to receive(:get_fields).with('set-cookie').exactly(5).times
    expect(basic_auth_http_conn).to receive(:request).exactly(5).times.with(request).and_return(cookie_response)
    %i[delete get head].each do |method|
      expect(Net::HTTP.const_get(method.to_s.capitalize)).to receive(:new).with('/path', headers).and_return(request)
      expect(client.make_request(method, '/path', nil, headers)).to eq(cookie_response)
    end
    %i[post put].each do |method|
      expect(Net::HTTP.const_get(method.to_s.capitalize)).to receive(:new).with('/path', headers).and_return(request)
      expect(request).to receive(:body=).with(body).and_return(request)
      expect(client.make_request(method, '/path', body, headers)).to eq(cookie_response)
    end
  end

  it 'performs a basic http client request' do
    body = nil
    headers = double
    basic_auth_http_conn = double
    http_request = double
    expect(Net::HTTP::Get).to receive(:new).with('/foo', headers).and_return(http_request)

    expect(basic_auth_http_conn).to receive(:request).with(http_request).and_return(response)
    expect(http_request).to receive(:basic_auth).with(basic_client.options[:username], basic_client.options[:password]).and_return(http_request)
    allow(basic_client).to receive(:basic_auth_http_conn).and_return(basic_auth_http_conn)
    basic_client.make_request(:get, '/foo', body, headers)
  end

  it 'performs a basic http client request with a full domain' do
    body = nil
    headers = double
    basic_auth_http_conn = double
    http_request = double
    expect(Net::HTTP::Get).to receive(:new).with('/foo', headers).and_return(http_request)

    expect(basic_auth_http_conn).to receive(:request).with(http_request).and_return(response)
    expect(http_request).to receive(:basic_auth).with(basic_client.options[:username], basic_client.options[:password]).and_return(http_request)
    allow(basic_client).to receive(:basic_auth_http_conn).and_return(basic_auth_http_conn)
    basic_client.make_request(:get, 'http://mydomain.com/foo', body, headers)
  end

  it 'does not try to use basic auth if the credentials are not set' do
    body = nil
    headers = double
    basic_auth_http_conn = double
    http_request = double
    expect(Net::HTTP::Get).to receive(:new).with('/foo', headers).and_return(http_request)

    expect(basic_auth_http_conn).to receive(:request).with(http_request).and_return(response)
    expect(http_request).not_to receive(:basic_auth)
    allow(basic_client_with_no_auth_credentials).to receive(:basic_auth_http_conn).and_return(basic_auth_http_conn)
    basic_client_with_no_auth_credentials.make_request(:get, '/foo', body, headers)
  end

  it 'returns a URI' do
    uri = URI.parse(basic_client.options[:site])
    expect(basic_client.uri).to eq(uri)
  end

  it 'sets up a http connection with options' do
    http_conn = double
    uri = double
    host = double
    port = double
    expect(uri).to receive(:host).and_return(host)
    expect(uri).to receive(:port).and_return(port)
    expect(Net::HTTP).to receive(:new).with(host, port).and_return(http_conn)
    expect(http_conn).to receive(:use_ssl=).with(basic_client.options[:use_ssl]).and_return(http_conn)
    expect(http_conn).to receive(:verify_mode=).with(basic_client.options[:ssl_verify_mode]).and_return(http_conn)
    expect(http_conn).to receive(:read_timeout=).with(basic_client.options[:read_timeout]).and_return(http_conn)
    expect(basic_client.http_conn(uri)).to eq(http_conn)
  end

  it 'sets the SSL version when one is provided' do
    http_conn = double
    uri = double
    host = double
    port = double
    expect(uri).to receive(:host).and_return(host)
    expect(uri).to receive(:port).and_return(port)
    expect(Net::HTTP).to receive(:new).with(host, port).and_return(http_conn)
    expect(http_conn).to receive(:use_ssl=).with(basic_client.options[:use_ssl]).and_return(http_conn)
    expect(http_conn).to receive(:verify_mode=).with(basic_client.options[:ssl_verify_mode]).and_return(http_conn)
    expect(http_conn).to receive(:ssl_version=).with(custom_ssl_version_client.options[:ssl_version]).and_return(http_conn)
    expect(http_conn).to receive(:read_timeout=).with(basic_client.options[:read_timeout]).and_return(http_conn)
    expect(custom_ssl_version_client.http_conn(uri)).to eq(http_conn)
  end

  it 'can use client certificates' do
    http_conn = double
    uri = double
    host = double
    port = double
    expect(Net::HTTP).to receive(:new).with(host, port).and_return(http_conn)
    expect(uri).to receive(:host).and_return(host)
    expect(uri).to receive(:port).and_return(port)
    expect(http_conn).to receive(:use_ssl=).with(basic_client.options[:use_ssl])
    expect(http_conn).to receive(:verify_mode=).with(basic_client.options[:ssl_verify_mode])
    expect(http_conn).to receive(:read_timeout=).with(basic_client.options[:read_timeout])
    expect(http_conn).to receive(:cert=).with(basic_client_cert_client.options[:cert])
    expect(http_conn).to receive(:key=).with(basic_client_cert_client.options[:key])
    expect(basic_client_cert_client.http_conn(uri)).to eq(http_conn)
  end

  it 'returns a http connection' do
    http_conn = double
    uri = double
    expect(basic_client).to receive(:uri).and_return(uri)
    expect(basic_client).to receive(:http_conn).and_return(http_conn)
    expect(basic_client.basic_auth_http_conn).to eq(http_conn)
  end

  describe '#make_multipart_request' do
    subject { JIRA::HttpClient.new(client_options).make_multipart_request(path, data, headers) }

    let(:client_options) { JIRA::Client::DEFAULT_OPTIONS.merge(JIRA::HttpClient::DEFAULT_OPTIONS) }
    let(:headers) { { 'X-Atlassian-Token' => 'no-check' } }
    let(:data) { {} }
    let(:path) { '/foo' }
    let(:basic_auth_http_conn) { double }
    let(:request){  double }
    let(:response) { double('response') }

    before do
      allow(request).to receive(:basic_auth)
      allow(response).to receive(:get_fields).with('set-cookie')
      allow(Net::HTTP::Post::Multipart).to receive(:new).with(path, data, headers).and_return(request)
    end

    it 'performs a basic http client request' do
      expect(request).to receive(:basic_auth).with(client.options[:username], client.options[:password]).and_return(request)

      subject
    end

    it 'makes a correct HTTP request' do
      expect(basic_auth_http_conn).to receive(:request).with(request).and_return(response)
      expect(response).to receive(:is_a?).with(Net::HTTPOK)

      subject
    end
  end
end
