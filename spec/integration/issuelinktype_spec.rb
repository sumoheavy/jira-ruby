require 'spec_helper'

describe JIRA::Resource::Issuelinktype do

  before(:each) do
    stub_request(:get, "http://foo:bar@localhost:2990/jira/rest/api/2/issueLinkType")
      .with(headers: {
        'Accept'=>'application/json',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'User-Agent'=>'Ruby'
      })
      .to_return(
        :status => 200,
        :body => '{"issueLinkTypes":[{"id":"10000","self":"http://localhost:2990/jira/rest/api/2/issueLinkType/10000","name":"Blocks","inward":"is blocked by","outward":"blocks"},{"id":"10001","self":"http://localhost:2990/jira/rest/api/2/issueLinkType/10001","name":"Relates","inward":"relates to","outward":"relates to"},{"id":"10002","self":"http://localhost:2990/jira/rest/api/2/issueLinkType/10002","name":"Duplicates","inward":"is duplicated by","outward":"duplicates"}]}',
        :headers => {}
      )
  end

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }


    let(:key) { "10000" }

    let(:expected_attributes) do
      {
        'id' => key,
        "self"=>"http://localhost:2990/jira/rest/api/2/issueLinkType/10000",
        "name"=>"Blocks",
        "inward"=>"is blocked by",
        "outward"=>"blocks"
      }
    end

    let(:expected_collection_length) { 3 }

    it_should_behave_like "a resource"
    it_should_behave_like "a resource with a collection GET endpoint"
    it_should_behave_like "a resource with a singular GET endpoint"

  end
end
