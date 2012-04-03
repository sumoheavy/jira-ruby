require 'spec_helper'

describe JIRA::Resource::Changelog do

  let(:client) { mock() }

  describe "relationships" do
    subject {
      JIRA::Resource::Changelog.new(client, :attrs => {
        'author' => {'foo' => 'bar'},
        'items'  => ['item1','item2']
      })
    }

    it "has the correct relationships" do
      subject.should have_one(:author, JIRA::Resource::User)
      subject.author.foo.should == 'bar'

      subject.should have_many(:items, String)
      subject.items[0].should == 'item1'
    end
  end

end
