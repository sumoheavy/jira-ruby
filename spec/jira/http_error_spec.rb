require 'spec_helper'

describe JIRA::HTTPError do

  let(:response)  { 
    response = mock("response") 
    response.stub(:code => 401)
    response.stub(:message => "A MESSAGE WOO")
    response
  }
  subject { described_class.new(response) }

  it "takes the response object as an argument" do
    subject.response.should == response
  end

  it "has a code method" do
    subject.code.should == response.code
  end

  it "returns code and class from message" do
    subject.message.should == response.message
  end

end
