require 'spec_helper'

describe JIRA::Resource::Attachment do

  with_each_client do |site_url, client|
    let(:client) { client }
    let(:site_url) { site_url }

    let(:key) { "10000" }

    let(:expected_attributes) do
      {
        'self' => "http://localhost:2990/jira/rest/api/2/attachment/10000",
        'size' => 15360,
        'filename' => "ballmer.png"
      }
    end

    it_should_behave_like "a resource"
    it_should_behave_like "a resource with a singular GET endpoint"
    it_should_behave_like "a resource with a DELETE endpoint"
  end
end
