require 'spec_helper'

describe JIRA::Resource::Attachment do

  let(:client) { double() }

  describe "relationships" do
    subject {
      JIRA::Resource::Attachment.new(client, :attrs => {
        'author' => {'foo' => 'bar'}
      })
    }

    it "has the correct relationships" do
      expect(subject).to have_one(:author, JIRA::Resource::User)
      expect(subject.author.foo).to eq('bar')
    end
  end

end
