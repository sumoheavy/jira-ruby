require 'spec_helper'

describe JIRA::HttpClient do

  let(:basic_client) do
    options = JIRA::Client::DEFAULT_OPTIONS.merge(JIRA::HttpClient::DEFAULT_OPTIONS)
    JIRA::HttpClient.new(options)
  end

  let(:response) do
    response = mock("response")
    response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    response
  end

  it "creates an instance of Net:HTTP for a basic auth client" do
    basic_client.basic_auth_http_conn.class.should == Net::HTTP
  end

  it "responds to the http methods" do
    body = ''
    headers = mock()
    basic_auth_http_conn = mock()
    request = mock()
    basic_client.stub(:basic_auth_http_conn => basic_auth_http_conn)
    request.should_receive(:basic_auth).with(basic_client.options[:username], basic_client.options[:password]).exactly(5).times.and_return(request)
    basic_auth_http_conn.should_receive(:request).exactly(5).times.with(request).and_return(response)
    [:delete, :get, :head].each do |method|
      Net::HTTP.const_get(method.to_s.capitalize).should_receive(:new).with('/path', headers).and_return(request)
      basic_client.make_request(method, '/path', nil, headers).should == response
    end
    [:post, :put].each do |method|
      Net::HTTP.const_get(method.to_s.capitalize).should_receive(:new).with('/path', headers).and_return(request)
      request.should_receive(:body=).with(body).and_return(request)
      basic_client.make_request(method, '/path', body, headers).should == response
    end
  end

  it "performs a basic http client request" do
    body = nil
    headers = mock()
    basic_auth_http_conn = mock()
    http_request = mock()
    Net::HTTP::Get.should_receive(:new).with('/foo', headers).and_return(http_request)

    basic_auth_http_conn.should_receive(:request).with(http_request).and_return(response)
    http_request.should_receive(:basic_auth).with(basic_client.options[:username], basic_client.options[:password]).and_return(http_request)
    basic_client.stub(:basic_auth_http_conn => basic_auth_http_conn)
    basic_client.make_request(:get, '/foo', body, headers)
  end

  it "returns a URI" do
    uri = URI.parse(basic_client.options[:site])
    basic_client.uri.should == uri
  end

  it "sets up a http connection with options" do
    http_conn = mock()
    uri = mock()
    host = mock()
    port = mock()
    uri.should_receive(:host).and_return(host)
    uri.should_receive(:port).and_return(port)
    Net::HTTP.should_receive(:new).with(host, port).and_return(http_conn)
    http_conn.should_receive(:use_ssl=).with(basic_client.options[:use_ssl]).and_return(http_conn)
    http_conn.should_receive(:verify_mode=).with(basic_client.options[:ssl_verify_mode]).and_return(http_conn)
    basic_client.http_conn(uri).should == http_conn
  end

  it "returns a http connection" do
    http_conn = mock()
    uri = mock()
    basic_client.should_receive(:uri).and_return(uri)
    basic_client.should_receive(:http_conn).and_return(http_conn)
    basic_client.basic_auth_http_conn.should == http_conn
  end
end
