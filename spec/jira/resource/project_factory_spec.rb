require 'spec_helper'

describe Jira::Resource::ProjectFactory do

  let(:client)  { mock() }
  subject       { Jira::Resource::ProjectFactory.new(client) }

  it "initializes correctly" do
    subject.class.should  == Jira::Resource::ProjectFactory
    subject.client.should == client
  end

end
