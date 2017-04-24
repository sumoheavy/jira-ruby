require 'spec_helper'

describe JIRA::Resource::Attachment do

  let(:client) {
    double(
      'client',
      :options => {
        :rest_base_path => '/jira/rest/api/2'
      }
    )
  }

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

  describe '#meta' do
    let(:response) {
      double(
        'response',
        :body => '{"enabled":true,"uploadLimit":10485760}'
      )
    }

    it 'returns meta information about attachment upload' do
      expect(client).to receive(:get).with('/jira/rest/api/2/attachment/meta').and_return(response)
      JIRA::Resource::Attachment.meta(client)
    end
  end
end
