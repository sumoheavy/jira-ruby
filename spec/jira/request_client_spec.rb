require 'spec_helper'

describe JIRA::RequestClient do
  it 'raises an exception for non success responses' do
    response = double
    allow(response).to receive(:kind_of?).with(Net::HTTPSuccess).and_return(false)
    rc = JIRA::RequestClient.new
    expect(rc).to receive(:make_request).with(:get, '/foo', '', {}).and_return(response)

    expect do
      rc.request(:get, '/foo', '', {})
    end.to raise_exception(JIRA::HTTPError)
  end
end
