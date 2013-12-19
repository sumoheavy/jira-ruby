require 'spec_helper'

describe JIRA::Resource::Project do

  let(:client) { double() }

  describe "relationships" do
    subject {
      JIRA::Resource::Project.new(client, :attrs => {
        'lead'        => {'foo' => 'bar'},
        'issueTypes'  => [{'foo' =>'bar'},{'baz' => 'flum'}],
        'versions'    => [{'foo' =>'bar'},{'baz' => 'flum'}]
      })
    }

    it "has the correct relationships" do
      subject.should have_one(:lead, JIRA::Resource::User)
      subject.lead.foo.should == 'bar'

      subject.should have_many(:issuetypes, JIRA::Resource::Issuetype)
      subject.issuetypes.length.should == 2

      subject.should have_many(:versions, JIRA::Resource::Version)
      subject.versions.length.should == 2
    end
  end

end
