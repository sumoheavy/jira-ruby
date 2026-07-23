require 'spec_helper'

describe JIRA::Atlassian::Jwt do
  let(:jwt_opts) do
    {
      algorithm: 'HS256',
      leeway: (3600 * 24 * 365 * 20) # 10 years of leeway -- the JWT gem verifies the token expiry time
    }
  end
  let(:base_url) { '' }
  let(:shared_secret) { TEST_DATA['secret'] }

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
  TEST_DATA = JSON.parse(
    File.read(File.expand_path('../../data/files/jwt-signed-urls.json', File.dirname(__FILE__)))
  ).freeze

  TEST_DATA['tests'].each do |test|
    context test['name'] do
      let(:signed_url) { test['signedUrl'] }
      let(:token) { CGI.parse(URI.parse(signed_url).query)['jwt'].first }

      it 'builds the canonical URL' do
        canonical_uri = described_class.create_canonical_request(signed_url, 'GET', base_url)

        # Remote the jwt query param from the signed URL to get the original
        expect(canonical_uri).to eq test['canonicalUrl']
      end

      it 'matches the qsh claim' do
        expected_qsh = Digest::SHA256.hexdigest(described_class.create_canonical_request(signed_url, 'GET', base_url))

        decoded_token = JWT.decode(token, shared_secret, true, jwt_opts).first

        expect(expected_qsh).to eq decoded_token['qsh']
      end
    end
  end
end
