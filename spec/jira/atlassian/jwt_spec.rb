require 'spec_helper'

# rubocop:disable RSpec/LeakyLocalVariable
describe JIRA::Atlassian::Jwt do
  let(:jwt_opts) do
    {
      algorithm: 'HS256',
      leeway: (3600 * 24 * 365 * 10) # 10 years of leeway -- the JWT gem verifies the token expiry time
    }
  end
  let(:base_url) { '' }

  it 'generates claims' do
    url = 'https://example.atlassian.com/jira/projects'
    issuer = 'com.atlassian.test'

    now = Time.now.to_i
    qsh = Digest::SHA256.hexdigest(
      described_class.create_canonical_request(url, 'get', base_url)
    )

    expected_claim = {
      iss: 'com.atlassian.test',
      iat: now,
      exp: now + 60,
      qsh: qsh
    }

    claim = described_class.build_claims(issuer, url, 'get', base_url, now, now + 60)
    expect(claim).to eq expected_claim
  end

  # Offical Atlassian signed URL test data
  json_tests = File.read(File.expand_path('../../data/files/jwt-signed-urls.json', File.dirname(__FILE__)))

  test_data = JSON.parse(json_tests)
  shared_secret = test_data['secret']

  test_data['tests'].each do |test|
    signed_url = test['signedUrl']
    signed_uri = URI.parse(signed_url)
    token = CGI.parse(signed_uri.query)['jwt'].first

    it "#{test['name']} - Canonical URL" do
      canonical_uri = described_class.create_canonical_request(signed_url, 'GET', base_url)

      # Remote the jwt query param from the signed URL to get the original
      expect(canonical_uri).to eq test['canonicalUrl']
    end

    it "#{test['name']} - QSH match" do
      expected_qsh = Digest::SHA256.hexdigest(described_class.create_canonical_request(signed_url, 'GET', base_url))

      decoded_token = JWT.decode(token, shared_secret, true, jwt_opts).first

      expect(expected_qsh).to eq decoded_token['qsh']
    end
  end
end
# rubocop:enable RSpec/LeakyLocalVariable
