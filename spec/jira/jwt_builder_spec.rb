require 'spec_helper'

describe JIRA::JwtClient::JwtBuilder do
  subject(:jwt_builder) do
    JIRA::JwtClient::JwtBuilder.new(url, http_method, shared_secret, site, issuer)
  end

  let(:url) { '/foo' }
  let(:http_method) { :get }
  let(:shared_secret) { 'shared_secret' }
  let(:site) { 'http://localhost:2990' }
  let(:issuer) { nil }

  describe '#build' do
    subject { jwt_builder.build }

    it 'generates jwt' do
      expect(subject).to be_present
    end
  end
end
