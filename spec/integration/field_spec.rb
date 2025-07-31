require 'spec_helper'

describe JIRA::Resource::Field do

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }


    let(:key) { "1" }

    let(:expected_attributes) do
      {
        "id"=>key,
        "name"=>"Description",
        "custom"=>false,
        "orderable"=>true,
        "navigable"=>true,
        "searchable"=>true,
        "clauseNames"=>["description"],
        "schema"=>  {
                      "type"=>"string",
                      "system"=>"description"
                    }
      }
    end

    let(:expected_collection_length) { 2 }
    before(:each) do
      stub_request(:get, "http://foo:bar@localhost:2990/jira/rest/api/2/field")
        .with(headers: {
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Ruby'
        })
        .to_return(:status => 200, :body => '[{"id":"1","name":"Description","custom":false,"orderable":true,"navigable":true,"searchable":true,"clauseNames":["description"],"schema":{"type":"string","system":"description"}},{"id":"2","name":"Summary","custom":false,"orderable":true,"navigable":true,"searchable":true,"clauseNames":["summary"],"schema":{"type":"string","system":"summary"}}]', :headers => {})
    end
    it_should_behave_like "a resource"
    it_should_behave_like "a resource with a collection GET endpoint"
    it_should_behave_like "a resource with a singular GET endpoint"

  end
end
