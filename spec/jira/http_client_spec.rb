require 'spec_helper'

describe JIRA::HttpClient do

  let(:basic_client) do
    options = JIRA::Client::DEFAULT_OPTIONS.merge(JIRA::HttpClient::DEFAULT_OPTIONS)
    JIRA::HttpClient.new(options)
  end

  let(:basic_cookie_client) do
    options = JIRA::Client::DEFAULT_OPTIONS.merge(JIRA::HttpClient::DEFAULT_OPTIONS).merge(:use_cookies => true)
    JIRA::HttpClient.new(options)
  end

  let(:response) do
    response = double("response")
    allow(response).to receive(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  let(:cookie_response) do
    response = double("response")
    allow(response).to receive(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  it "creates an instance of Net:HTTP for a basic auth client" do
    expect(basic_client.basic_auth_http_conn.class).to eq(Net::HTTP)
  end

  it "responds to the http methods" do
    body = ''
    headers = double()
    basic_auth_http_conn = double()
    request = double()
    allow(basic_client).to receive(:basic_auth_http_conn).and_return(basic_auth_http_conn)
    expect(request).to receive(:basic_auth).with(basic_client.options[:username], basic_client.options[:password]).exactly(5).times.and_return(request)
    expect(basic_auth_http_conn).to receive(:request).exactly(5).times.with(request).and_return(response)
    [:delete, :get, :head].each do |method|
      expect(Net::HTTP.const_get(method.to_s.capitalize)).to receive(:new).with('/path', headers).and_return(request)
      expect(basic_client.make_request(method, '/path', nil, headers)).to eq(response)
    end
    [:post, :put].each do |method|
      expect(Net::HTTP.const_get(method.to_s.capitalize)).to receive(:new).with('/path', headers).and_return(request)
      expect(request).to receive(:body=).with(body).and_return(request)
      expect(basic_client.make_request(method, '/path', body, headers)).to eq(response)
    end
  end

  it "gets and sets cookies" do
    body = ''
    headers = double()
    basic_auth_http_conn = double()
    request = double()
    allow(basic_cookie_client).to receive(:basic_auth_http_conn).and_return(basic_auth_http_conn)
    expect(request).to receive(:basic_auth).with(basic_cookie_client.options[:username], basic_cookie_client.options[:password]).exactly(5).times.and_return(request)
    expect(cookie_response).to receive(:get_fields).with('set-cookie').exactly(5).times
    expect(basic_auth_http_conn).to receive(:request).exactly(5).times.with(request).and_return(cookie_response)
    [:delete, :get, :head].each do |method|
      expect(Net::HTTP.const_get(method.to_s.capitalize)).to receive(:new).with('/path', headers).and_return(request)
      expect(basic_cookie_client.make_request(method, '/path', nil, headers)).to eq(cookie_response)
    end
    [:post, :put].each do |method|
      expect(Net::HTTP.const_get(method.to_s.capitalize)).to receive(:new).with('/path', headers).and_return(request)
      expect(request).to receive(:body=).with(body).and_return(request)
      expect(basic_cookie_client.make_request(method, '/path', body, headers)).to eq(cookie_response)
    end
  end


  it "performs a basic http client request" do
    body = nil
    headers = double()
    basic_auth_http_conn = double()
    http_request = double()
    expect(Net::HTTP::Get).to receive(:new).with('/foo', headers).and_return(http_request)

    expect(basic_auth_http_conn).to receive(:request).with(http_request).and_return(response)
    expect(http_request).to receive(:basic_auth).with(basic_client.options[:username], basic_client.options[:password]).and_return(http_request)
    allow(basic_client).to receive(:basic_auth_http_conn).and_return(basic_auth_http_conn)
    basic_client.make_request(:get, '/foo', body, headers)
  end

  it "returns a URI" do
    uri = URI.parse(basic_client.options[:site])
    expect(basic_client.uri).to eq(uri)
  end

  it "sets up a http connection with options" do
    http_conn = double()
    uri = double()
    host = double()
    port = double()
    expect(uri).to receive(:host).and_return(host)
    expect(uri).to receive(:port).and_return(port)
    expect(Net::HTTP).to receive(:new).with(host, port).and_return(http_conn)
    expect(http_conn).to receive(:use_ssl=).with(basic_client.options[:use_ssl]).and_return(http_conn)
    expect(http_conn).to receive(:verify_mode=).with(basic_client.options[:ssl_verify_mode]).and_return(http_conn)
    expect(basic_client.http_conn(uri)).to eq(http_conn)
  end

  it "returns a http connection" do
    http_conn = double()
    uri = double()
    expect(basic_client).to receive(:uri).and_return(uri)
    expect(basic_client).to receive(:http_conn).and_return(http_conn)
    expect(basic_client.basic_auth_http_conn).to eq(http_conn)
  end
end
