require 'spec_helper'

describe JIRA::RequestClient do

  it "raises an exception for non success responses" do
    response = double()
    response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(false)
    rc = JIRA::RequestClient.new
    rc.should_receive(:make_request).with(:get, '/foo', '', {}).and_return(response)
    expect {
      rc.request(:get, '/foo', '', {})
    }.to raise_exception(JIRA::HTTPError)
  end
end
