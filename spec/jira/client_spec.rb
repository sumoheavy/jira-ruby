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
    expect(subject.send(:merge_default_headers, {})).to eq({'Accept' => 'application/json'})
  end

  describe 'http methods' do
    it 'merges default headers' do
      # stubbed response for generic client request method
      expect(subject).to receive(:request).exactly(5).times.and_return(successful_response)

      # response for merging headers for http methods with no body
      expect(subject).to receive(:merge_default_headers).exactly(3).times.with({})

      # response for merging headers for http methods with body
      expect(subject).to receive(:merge_default_headers).exactly(2).times.with(content_type_header)

      [:delete, :get, :head].each { |method| subject.send(method, '/path', {}) }
      [:post, :put].each {|method| subject.send(method, '/path', '', content_type_header)}
    end

    it 'calls the generic request method' do
      [:delete, :get, :head].each do |method|
        expect(subject).to receive(:request).with(method, '/path', nil, headers).and_return(successful_response)
        subject.send(method, '/path', {})
      end

      [:post, :put].each do |method|
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
end

RSpec.shared_examples 'HttpClient tests' do
  it 'makes a valid request' do
    [:delete, :get, :head].each do |method|
      expect(subject.request_client).to receive(:make_request).with(method, '/path', nil, headers).and_return(successful_response)
      subject.send(method, '/path', headers)
    end
    [:post, :put].each do |method|
      expect(subject.request_client).to receive(:make_request).with(method, '/path', '', merged_headers).and_return(successful_response)
      subject.send(method, '/path', '', headers)
    end
  end
end

describe JIRA::Client do
  let(:request) { subject.request_client.class }
  let(:successful_response) do
    response = double('response')
    allow(response).to receive(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    response
  end
  let(:content_type_header) { {'Content-Type' => 'application/json'} }
  let(:headers) { {'Accept' => 'application/json'} }
  let(:merged_headers) { headers.merge(content_type_header) }

  context 'behaviour that applies to all client classes irrespective of authentication method' do
    it 'allows the overriding of some options' do
      client = JIRA::Client.new({:consumer_key => 'foo', :consumer_secret => 'bar', :site => 'http://foo.com/'})
      expect(client.options[:site]).to eq('http://foo.com/')
      expect(JIRA::Client::DEFAULT_OPTIONS[:site]).not_to eq('http://foo.com/')
    end
  end

  context 'with basic http authentication' do
    subject { JIRA::Client.new(username: 'foo', password: 'bar', auth_type: :basic) }

    before(:each) do
      stub_request(:get, 'https://foo:bar@localhost:2990/jira/rest/api/2/project')
        .to_return(status: 200, body: '[]', headers: {} )

      stub_request(:get, 'https://foo:badpassword@localhost:2990/jira/rest/api/2/project').
        to_return(status: 401, headers: {} )
    end

    include_examples 'Client Common Tests'
    include_examples 'HttpClient tests'

    specify { expect(subject.request_client).to be_a JIRA::HttpClient }

    it 'sets the username and password' do
      expect(subject.options[:username]).to eq('foo')
      expect(subject.options[:password]).to eq('bar')
    end

    it 'fails with wrong user name and password' do
      bad_login = JIRA::Client.new(username: 'foo', password: 'badpassword', auth_type: :basic)
      expect(bad_login.authenticated?).to be_falsey
      expect{bad_login.Project.all}.to raise_error JIRA::HTTPError
    end

    it 'only returns a true for #authenticated? once we have requested some data' do
      expect(subject.authenticated?).to be_falsey
      expect(subject.Project.all).to be_empty
      expect(subject.authenticated?).to be_truthy
    end

  end

  context 'with cookie authentication' do
    subject { JIRA::Client.new(username: 'foo', password: 'bar', auth_type: :cookie) }

    let(:session_cookie) { '6E3487971234567896704A9EB4AE501F' }
    let(:session_body) do
      {
        'session': {'name' => "JSESSIONID", 'value' => session_cookie },
        'loginInfo': {'failedLoginCount' => 1, 'loginCount' => 2,
                      'lastFailedLoginTime' => (DateTime.now - 2).iso8601,
                      'previousLoginTime' => (DateTime.now - 5).iso8601 }
      }
    end

    before(:each) do
      # General case of API call with no authentication, or wrong authentication
      stub_request(:post, 'https://localhost:2990/jira/rest/auth/1/session').
        to_return(status: 401, headers: {} )

      # Now special case of API with correct authentication.  This gets checked first by RSpec.
      stub_request(:post, 'https://localhost:2990/jira/rest/auth/1/session')
        .with(body: '{"username":"foo","password":"bar"}')
        .to_return(status: 200, body: session_body.to_json,
                   headers: { 'Set-Cookie': "JSESSIONID=#{session_cookie}; Path=/; HttpOnly"})

      stub_request(:get, 'https://localhost:2990/jira/rest/api/2/project')
        .with(headers: { cookie: "JSESSIONID=#{session_cookie}" } )
        .to_return(status: 200, body: '[]', headers: {} )
    end

    include_examples 'Client Common Tests'
    include_examples 'HttpClient tests'

    specify { expect(subject.request_client).to be_a JIRA::HttpClient }

    it 'authenticates with a correct username and password' do
      expect(subject).to be_authenticated
      expect(subject.Project.all).to be_empty
    end

    it 'does not authenticate with an incorrect username and password' do
      bad_client = JIRA::Client.new(username: 'foo', password: 'bad_password', auth_type: :cookie)
      expect(bad_client).not_to be_authenticated
    end

    it 'destroys the username and password once authenticated' do
      expect(subject.options[:username]).to be_nil
      expect(subject.options[:password]).to be_nil
    end
  end

  context 'oath2 authentication' do
    subject { JIRA::Client.new(consumer_key: 'foo', consumer_secret: 'bar') }

    include_examples 'Client Common Tests'

    specify { expect(subject.request_client).to be_a JIRA::OauthClient }

    it 'allows setting an access token' do
      token = double
      expect(OAuth::AccessToken).to receive(:new).with(subject.consumer, 'foo', 'bar').and_return(token)

      expect(subject.authenticated?).to be_falsey
      access_token = subject.set_access_token('foo', 'bar')
      expect(access_token).to eq(token)
      expect(subject.access_token).to eq(token)
      expect(subject.authenticated?).to be_truthy
    end

    it 'allows initializing the access token' do
      request_token = OAuth::RequestToken.new(subject.consumer)
      allow(subject.consumer).to receive(:get_request_token).and_return(request_token)
      mock_access_token = double
      expect(request_token).to receive(:get_access_token).with(:oauth_verifier => 'abc123').and_return(mock_access_token)
      subject.init_access_token(:oauth_verifier => 'abc123')
      expect(subject.access_token).to eq(mock_access_token)
    end

    specify 'that has specific default options' do
      [:signature_method, :private_key_file].each do |key|
        expect(subject.options[key]).to eq(JIRA::Client::DEFAULT_OPTIONS[key])
      end
    end

    describe 'that call a oauth client' do
      specify 'which makes a request' do
        [:delete, :get, :head].each do |method|
          expect(subject.request_client).to receive(:make_request).with(method, '/path', nil, headers).and_return(successful_response)
          subject.send(method, '/path', {})
        end
        [:post, :put].each do |method|
          expect(subject.request_client).to receive(:make_request).with(method, '/path', '', merged_headers).and_return(successful_response)
          subject.send(method, '/path', '', {})
        end
      end
    end
  end
end

