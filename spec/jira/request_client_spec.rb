require 'spec_helper'

describe JIRA::RequestClient do
  let(:request_client) { described_class.new }

  describe '#request' do
    subject(:request) { request_client.request(:get, '/foo', '', {}) }

    context 'when doing a request fails' do
      let(:response) { double }

      before do
        allow(response).to receive(:kind_of?).with(Net::HTTPSuccess).and_return(false)
        allow(request_client).to receive(:make_request).with(:get, '/foo', '', {}).and_return(response)
      end

      it 'raises an exception' do
        expect { subject }.to raise_exception(JIRA::HTTPError)
      end
    end
  end

  describe '#request_multipart' do
    subject(:request) { request_client.request_multipart('/foo', data, {}) }

    let(:data) { double }

    context 'when doing a request fails' do
      let(:response) { double }

      before do
        allow(response).to receive(:kind_of?).with(Net::HTTPSuccess).and_return(false)
        allow(request_client).to receive(:make_multipart_request).with('/foo', data, {}).and_return(response)
      end

      it 'raises an exception' do
        expect { subject }.to raise_exception(JIRA::HTTPError)
      end
    end
  end
end
