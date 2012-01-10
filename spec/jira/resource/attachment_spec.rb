require 'spec_helper'

describe JIRA::Resource::Attachment do

  let(:client) { mock() }

  describe "relationships" do
    subject {
      JIRA::Resource::Attachment.new(client, :attrs => {
        'author' => {'foo' => 'bar'}
      })
    }

    it "has the correct relationships" do
      subject.should have_one(:author, JIRA::Resource::User)
      subject.author.foo.should == 'bar'
    end
  end

end
