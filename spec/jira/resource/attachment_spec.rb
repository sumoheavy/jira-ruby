require 'spec_helper'

describe JIRA::Resource::Attachment do

  let(:client) {
    double(
      'client',
      :options => {
        :rest_base_path => '/jira/rest/api/2'
      },
      :request_client => double(
        :options => {
          :username => 'username',
          :password => 'password'
        }
      )
    )
  }

  describe "relationships" do
    subject {
      JIRA::Resource::Attachment.new(client,
                                     :issue => JIRA::Resource::Issue.new(client),
                                     :attrs => { 'author' => {'foo' => 'bar'} })
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

  describe '#save!' do
    it 'successfully update the attachment' do
      basic_auth_http_conn = double()
      response = double(
        body: [
          {
            "id": 10001,
            "self": "http://www.example.com/jira/rest/api/2.0/attachments/10000",
            "filename": "picture.jpg",
            "created": "2017-07-19T12:23:06.572+0000",
            "size": 23123,
            "mimeType": "image/jpeg",
          }
        ].to_json
      )

      allow(client.request_client).to receive(:basic_auth_http_conn).and_return(basic_auth_http_conn)
      allow(basic_auth_http_conn).to receive(:request).and_return(response)

      issue = JIRA::Resource::Issue.new(client)
      path_to_file = './spec/mock_responses/issue.json'
      attachment = JIRA::Resource::Attachment.new(client, issue: issue)
      attachment.save!('file' => path_to_file)

      expect(attachment.filename).to eq 'picture.jpg'
      expect(attachment.mimeType).to eq 'image/jpeg'
      expect(attachment.size).to eq 23123
    end
  end
end
