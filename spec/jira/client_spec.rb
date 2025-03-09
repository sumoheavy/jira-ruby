require 'spec_helper'

# We have three forms of authentication with two clases to represent the client for those different authentications.
# Some behaviours are shared across all three types of authentication.  these are captured here.
RSpec.shared_examples 'Client Common Tests' do
  it { is_expected.to be_a JIRA::Client }

  it 'freezes the options once initialised' do
    expect(subject.options).to be_frozen
  end

  it 'prepends context path to rest base_path' do
    options = [:rest_base_path]
    defaults = JIRA::Client::DEFAULT_OPTIONS
    options.each { |key| expect(subject.options[key]).to eq(defaults[:context_path] + defaults[key]) }
  end

  it 'merges headers' do
    expect(subject.send(:merge_default_headers, {})).to eq('Accept' => 'application/json')
  end

  describe 'http methods' do
    it 'merges default headers' do
      # stubbed response for generic client request method
      expect(subject).to receive(:request).exactly(5).times.and_return(successful_response)

      # response for merging headers for http methods with no body
      expect(subject).to receive(:merge_default_headers).exactly(3).times.with({})

      # response for merging headers for http methods with body
      expect(subject).to receive(:merge_default_headers).twice.with(content_type_header)

      %i[delete get head].each { |method| subject.send(method, '/path', {}) }
      %i[post put].each { |method| subject.send(method, '/path', '', content_type_header) }
    end

    it 'calls the generic request method' do
      %i[delete get head].each do |method|
        expect(subject).to receive(:request).with(method, '/path', nil, headers).and_return(successful_response)
        subject.send(method, '/path', {})
      end

      %i[post put].each do |method|
        expect(subject).to receive(:request).with(method, '/path', '', merged_headers)
        subject.send(method, '/path', '', {})
      end
    end
  end

  describe 'Resource Factories' do
    it 'gets all projects' do
      expect(JIRA::Resource::Project).to receive(:all).with(subject).and_return([])
      expect(subject.Project.all).to eq([])
    end

    it 'finds a single project' do
      find_result = double
      expect(JIRA::Resource::Project).to receive(:find).with(subject, '123').and_return(find_result)
      expect(subject.Project.find('123')).to eq(find_result)
    end
  end

  describe 'SSL client options' do
    context 'without certificate and key' do
      subject { JIRA::Client.new(options) }

      let(:options) { { use_client_cert: true } }

      it 'raises an ArgumentError' do
        expect do
          subject
        end.to raise_exception(ArgumentError,
                               'Options: :cert_path or :ssl_client_cert must be set when :use_client_cert is true')
        options[:ssl_client_cert] = '<cert></cert>'
        expect do
          subject
        end.to raise_exception(ArgumentError,
                               'Options: :key_path or :ssl_client_key must be set when :use_client_cert is true')
      end
    end
  end
end

RSpec.shared_examples 'HttpClient tests' do
  it 'makes a valid request' do
    %i[delete get head].each do |method|
      expect(subject.request_client).to receive(:make_request).with(method, '/path', nil,
                                                                    headers).and_return(successful_response)
      subject.send(method, '/path', headers)
    end
    %i[post put].each do |method|
      expect(subject.request_client).to receive(:make_request).with(method, '/path', '',
                                                                    merged_headers).and_return(successful_response)
      subject.send(method, '/path', '', headers)
    end
  end
end

RSpec.shared_examples 'OAuth Common Tests' do
  include_examples 'Client Common Tests'

  specify { expect(subject.request_client).to be_a JIRA::OauthClient }

  it 'allows setting an access token' do
    token = double
    expect(OAuth::AccessToken).to receive(:new).with(subject.consumer, '', '').and_return(token)

    expect(subject.authenticated?).to be_falsey
    access_token = subject.set_access_token('', '')
    expect(access_token).to eq(token)
    expect(subject.access_token).to eq(token)
    expect(subject.authenticated?).to be_truthy
  end

  describe 'that call a oauth client' do
    specify 'which makes a request' do
      %i[delete get head].each do |method|
        expect(subject.request_client).to receive(:make_request).with(method, '/path', nil,
                                                                      headers).and_return(successful_response)
        subject.send(method, '/path', {})
      end
      %i[post put].each do |method|
        expect(subject.request_client).to receive(:make_request).with(method, '/path', '',
                                                                      merged_headers).and_return(successful_response)
        subject.send(method, '/path', '', {})
      end
    end
  end
end

describe JIRA::Client do
  let(:request) { subject.request_client.class }
  let(:successful_response) do
    response = double('response')
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    response
  end
  let(:content_type_header) { { 'Content-Type' => 'application/json' } }
  let(:headers) { { 'Accept' => 'application/json' } }
  let(:merged_headers) { headers.merge(content_type_header) }

  context 'behaviour that applies to all client classes irrespective of authentication method' do
    it 'allows the overriding of some options' do
      client = described_class.new(consumer_key: 'foo', consumer_secret: 'bar', site: 'http://foo.com/')
      expect(client.options[:site]).to eq('http://foo.com/')
      expect(JIRA::Client::DEFAULT_OPTIONS[:site]).not_to eq('http://foo.com/')
    end
  end

  context 'with basic http authentication' do
    subject { described_class.new(username: 'foo', password: 'bar', auth_type: :basic) }

    before do
      stub_request(:get, 'https://localhost:2990/jira/rest/api/2/project')
        .with(headers: { 'Authorization' => "Basic #{Base64.strict_encode64('foo:bar').chomp}" })
        .to_return(status: 200, body: '[]', headers: {})

      stub_request(:get, 'https://localhost:2990/jira/rest/api/2/project')
        .with(headers: { 'Authorization' => "Basic #{Base64.strict_encode64('foo:badpassword').chomp}" })
        .to_return(status: 401, headers: {})
    end

    include_examples 'Client Common Tests'
    include_examples 'HttpClient tests'

    specify { expect(subject.request_client).to be_a JIRA::HttpClient }

    it 'sets the username and password' do
      expect(subject.options[:username]).to eq('foo')
      expect(subject.options[:password]).to eq('bar')
    end

    it 'only returns a true for #authenticated? once we have requested some data' do
      expect(subject.authenticated?).to be_nil
      expect(subject.Project.all).to be_empty
      expect(subject.authenticated?).to be_truthy
    end

    it 'fails with wrong user name and password' do
      bad_login = described_class.new(username: 'foo', password: 'badpassword', auth_type: :basic)
      expect(bad_login.authenticated?).to be_falsey
      expect { bad_login.Project.all }.to raise_error JIRA::HTTPError
    end
  end

  context 'with cookie authentication' do
    subject { described_class.new(username: 'foo', password: 'bar', auth_type: :cookie) }

    let(:session_cookie) { '6E3487971234567896704A9EB4AE501F' }
    let(:session_body) do
      {
        session: { 'name' => 'JSESSIONID', 'value' => session_cookie },
        loginInfo: { 'failedLoginCount' => 1, 'loginCount' => 2,
                     'lastFailedLoginTime' => (DateTime.now - 2).iso8601,
                     'previousLoginTime' => (DateTime.now - 5).iso8601 }
      }
    end

    before do
      # General case of API call with no authentication, or wrong authentication
      stub_request(:post, 'https://localhost:2990/jira/rest/auth/1/session')
        .to_return(status: 401, headers: {})

      # Now special case of API with correct authentication.  This gets checked first by RSpec.
      stub_request(:post, 'https://localhost:2990/jira/rest/auth/1/session')
        .with(body: '{"username":"foo","password":"bar"}')
        .to_return(status: 200, body: session_body.to_json,
                   headers: { 'Set-Cookie': "JSESSIONID=#{session_cookie}; Path=/; HttpOnly" })

      stub_request(:get, 'https://localhost:2990/jira/rest/api/2/project')
        .with(headers: { cookie: "JSESSIONID=#{session_cookie}" })
        .to_return(status: 200, body: '[]', headers: {})
    end

    include_examples 'Client Common Tests'
    include_examples 'HttpClient tests'

    specify { expect(subject.request_client).to be_a JIRA::HttpClient }

    it 'authenticates with a correct username and password' do
      expect(subject).to be_authenticated
      expect(subject.Project.all).to be_empty
    end

    it 'does not authenticate with an incorrect username and password' do
      bad_client = described_class.new(username: 'foo', password: 'bad_password', auth_type: :cookie)
      expect(bad_client).not_to be_authenticated
    end

    it 'destroys the username and password once authenticated' do
      expect(subject.options[:username]).to be_nil
      expect(subject.options[:password]).to be_nil
    end
  end

  context 'with jwt authentication' do
    subject do
      described_class.new(
        issuer: 'foo',
        base_url: 'https://host.tld',
        shared_secret: 'shared_secret_key',
        auth_type: :jwt
      )
    end

    before do
      stub_request(:get, 'https://localhost:2990/jira/rest/api/2/project')
        .with(headers: { 'Authorization' => /JWT .+/ })
        .to_return(status: 200, body: '[]', headers: {})
    end

    include_examples 'Client Common Tests'
    include_examples 'HttpClient tests'

    specify { expect(subject.request_client).to be_a JIRA::JwtClient }

    it 'sets the username and password' do
      expect(subject.options[:shared_secret]).to eq('shared_secret_key')
    end

    context 'with a incorrect jwt key' do
      before do
        stub_request(:get, 'https://localhost:2990/jira/rest/api/2/project')
          .with(headers: { 'Authorization' => /JWT .+/ })
          .to_return(status: 401, body: '[]', headers: {})
      end

      it 'is not authenticated' do
        expect(subject.authenticated?).to be_falsey
      end

      it 'raises a JIRA::HTTPError when trying to fetch projects' do
        expect { subject.Project.all }.to raise_error JIRA::HTTPError
      end
    end

    it 'only returns a true for #authenticated? once we have requested some data' do
      expect(subject.authenticated?).to be_falsey
      expect(subject.Project.all).to be_empty
      expect(subject.authenticated?).to be_truthy
    end
  end

  context 'oauth authentication' do
    subject { described_class.new(consumer_key: 'foo', consumer_secret: 'bar') }

    include_examples 'OAuth Common Tests'
  end

  context 'with oauth_2legged' do
    subject { described_class.new(consumer_key: 'foo', consumer_secret: 'bar', auth_type: :oauth_2legged) }

    include_examples 'OAuth Common Tests'
  end

  context 'with unknown options' do
    subject { described_class.new(options) }

    let(:options) { { 'username' => 'foo', 'password' => 'bar', auth_type: :basic } }

    it 'raises an ArgumentError' do
      expect { subject }.to raise_exception(ArgumentError, 'Unknown option(s) given: ["username", "password"]')
    end
  end
end
