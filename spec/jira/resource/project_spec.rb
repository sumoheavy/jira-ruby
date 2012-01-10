require 'spec_helper'

describe JIRA::Resource::Project do

  let(:client) { mock() }

  it "has one lead" do
    subject = JIRA::Resource::Project.new(client, :attrs => {'lead' => {'foo' =>'bar'}})
    subject.lead.class.should == JIRA::Resource::User
    subject.lead.foo.should == 'bar'
  end

  it "has many issuetypes" do
    subject = JIRA::Resource::Project.new(client, :attrs => {'issueTypes' => [{'foo' =>'bar'},{'baz' => 'flum'}]})
    subject.should have_many(:issuetypes, JIRA::Resource::Issuetype)
    subject.issuetypes.length.should == 2
  end

end
