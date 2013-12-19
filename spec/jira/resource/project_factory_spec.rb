require 'spec_helper'

describe JIRA::Resource::ProjectFactory do

  let(:client)  { double() }
  subject       { JIRA::Resource::ProjectFactory.new(client) }

  it "initializes correctly" do
    subject.class.should  == JIRA::Resource::ProjectFactory
    subject.client.should == client
  end

end
