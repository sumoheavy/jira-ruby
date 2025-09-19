require 'spec_helper'

describe JIRA::Resource::Transition do
  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { '10000' }

    let(:target) { described_class.new(client, attrs: { 'id' => '99999' }, issue_id: '10014') }

    let(:belongs_to) do
      JIRA::Resource::Issue.new(client, attrs: {
                                  'id' => '10002',
                                  'self' => "#{site_url}/jira/rest/api/2/issue/10002",
                                  'fields' => {
                                    'comment' => { 'comments' => [] }
                                  }
                                })
    end

    let(:expected_attributes) do
      {
        'self' => "#{site_url}/jira/rest/api/2/issue/10002/transition/10000",
        'id' => key
      }
    end

    let(:attributes_for_post) do
      {
        'transition' => {
          'id' => '42'
        }
      }
    end

    it_behaves_like 'a resource'

    describe 'POST endpoint' do
      it 'saves a new resource' do
        req_url = build_url
        stub_request(:post, req_url)
          .with(body: attributes_for_post.to_json)
          .to_return(status: 200, body: get_mock_from_url(:post, req_url))
        subject = build_receiver.build
        expect(subject.save(attributes_for_post)).to be_truthy
      end
    end
  end
end
