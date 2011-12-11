require 'spec_helper'

describe JiraRuby::Resource::ProjectFactory do

  let(:client)  { mock() }
  subject       { JiraRuby::Resource::ProjectFactory.new(client) }

  it "initializes correctly" do
    subject.class.should  == JiraRuby::Resource::ProjectFactory
    subject.client.should == client
  end

end
