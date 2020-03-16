require 'spec_helper'

describe JIRA::JwtClient::JwtUriBuilder do
  subject(:url_builder) do
    JIRA::JwtClient::JwtUriBuilder.new(url, http_method, shared_secret, site, issuer)
  end

  let(:url) { '/foo' }
  let(:http_method) { :get }
  let(:shared_secret) { 'shared_secret' }
  let(:site) { 'http://localhost:2990' }
  let(:issuer) { nil }

  describe '#build' do
    subject { url_builder.build }

    it 'includes the jwt param' do
      expect(subject).to include('?jwt=')
    end

    context 'when the url already contains params' do
      let(:url) { '/foo?expand=projects.issuetypes.fields' }

      it 'includes the jwt param' do
        expect(subject).to include('&jwt=')
      end
    end

    context 'with a complete url' do
      let(:url) { 'http://localhost:2990/rest/api/2/issue/createmeta' }

      it 'includes the jwt param' do
        expect(subject).to include('?jwt=')
      end

      it { is_expected.to start_with('/') }

      it 'contains only one ?' do
        expect(subject.count('?')).to eq(1)
      end
    end

    context 'with a complete url containing a param' do
      let(:url) do
        'http://localhost:2990/rest/api/2/issue/createmeta?expand=projects.issuetypes.fields'
      end

      it 'includes the jwt param' do
        expect(subject).to include('&jwt=')
      end

      it { is_expected.to start_with('/') }

      it 'contains only one ?' do
        expect(subject.count('?')).to eq(1)
      end
    end
  end
end
