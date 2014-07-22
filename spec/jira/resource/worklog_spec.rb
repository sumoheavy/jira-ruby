require 'spec_helper'

describe JIRA::Resource::Worklog do

  let(:client) { double() }

  describe "relationships" do
    subject {
      JIRA::Resource::Worklog.new(client, :issue_id => '99999', :attrs => {
        'author' => {'foo' => 'bar'},
        'updateAuthor' => {'foo' => 'bar'}
      })
    }

    it "has the correct relationships" do
      expect(subject).to have_one(:author, JIRA::Resource::User)
      expect(subject.author.foo).to eq('bar')

      expect(subject).to have_one(:update_author, JIRA::Resource::User)
      expect(subject.update_author.foo).to eq('bar')
    end
  end

end
