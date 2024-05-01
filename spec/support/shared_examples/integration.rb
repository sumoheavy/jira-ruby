require 'cgi'

def get_mock_from_path(method, options = {})
  prefix = if defined? belongs_to
             "#{belongs_to.path_component}/"
           else
             ''
           end

  url = if options[:url]
          options[:url]
        elsif options[:key]
          described_class.singular_path(client, options[:key], prefix)
        else
          described_class.collection_path(client, prefix)
        end
  file_path = url.sub(client.options[:rest_base_path], '')
  file_path = "#{file_path}.#{options[:suffix]}" if options[:suffix]
  file_path = "#{file_path}.#{method}" unless method == :get
  value_if_not_found = options.key?(:value_if_not_found) ? options[:value_if_not_found] : false
  get_mock_response("#{file_path}.json", value_if_not_found)
end

def class_basename
  described_class.name.split('::').last
end

def options
  options = {}
  options[belongs_to.to_sym] = belongs_to if defined? belongs_to
  options
end

def prefix
  prefix = '/'
  prefix = "#{belongs_to.path_component}/" if defined? belongs_to
  prefix
end

def build_receiver
  if defined?(belongs_to)
    belongs_to.send(described_class.endpoint_name.pluralize.to_sym)
  else
    client.send(class_basename)
  end
end

shared_examples 'a resource' do
  it 'gracefully handles non-json responses' do
    subject = if defined? target
                target
              else
                client.send(class_basename).build(described_class.key_attribute.to_s => '99999')
              end
    stub_request(:put, site_url + subject.url)
      .to_return(status: 405, body: '<html><body>Some HTML</body></html>')
    expect(subject.save('foo' => 'bar')).to be_falsey
    expect do
      expect(subject.save!('foo' => 'bar')).to be_falsey
    end.to raise_error(JIRA::HTTPError)
  end
end

shared_examples 'a resource with a collection GET endpoint' do
  it 'gets the collection' do
    stub_request(:get, site_url + described_class.collection_path(client))
      .to_return(status: 200, body: get_mock_from_path(:get))
    collection = build_receiver.all

    expect(collection.length).to eq(expected_collection_length)
    expect(collection.first).to have_attributes(expected_attributes)
  end
end

shared_examples 'a resource with JQL inputs and a collection GET endpoint' do
  it 'gets the collection' do
    stub_request(
      :get,
      "#{site_url}#{client.options[:rest_base_path]}/search?jql=#{CGI.escape(jql_query_string)}"
    ).to_return(status: 200, body: get_mock_response('issue.json'))

    collection = build_receiver.jql(jql_query_string)

    expect(collection.length).to eq(expected_collection_length)
    expect(collection.first).to have_attributes(expected_attributes)
  end
end

shared_examples 'a resource with a singular GET endpoint' do
  it 'GETs a single resource' do
    # E.g., for JIRA::Resource::Project, we need to call
    # client.Project.find()
    stub_request(:get, site_url + described_class.singular_path(client, key, prefix))
      .to_return(status: 200, body: get_mock_from_path(:get, key:))
    subject = client.send(class_basename).find(key, options)

    expect(subject).to have_attributes(expected_attributes)
  end

  it 'builds and fetches a single resource' do
    # E.g., for JIRA::Resource::Project, we need to call
    # client.Project.build('key' => 'ABC123')
    stub_request(:get, site_url + described_class.singular_path(client, key, prefix))
      .to_return(status: 200, body: get_mock_from_path(:get, key:))

    subject = build_receiver.build(described_class.key_attribute.to_s => key)
    subject.fetch

    expect(subject).to have_attributes(expected_attributes)
  end

  it 'handles a 404' do
    stub_request(:get, site_url + described_class.singular_path(client, '99999', prefix))
      .to_return(status: 404, body: "{\"errorMessages\":[\"#{class_basename} Does Not Exist\"],\"errors\": {}}")
    expect do
      client.send(class_basename).find('99999', options)
    end.to raise_exception(JIRA::HTTPError)
  end
end

shared_examples 'a resource with a DELETE endpoint' do
  it 'deletes a resource' do
    # E.g., for JIRA::Resource::Project, we need to call
    # client.Project.delete()
    stub_request(:delete, site_url + described_class.singular_path(client, key, prefix))
      .to_return(status: 204, body: nil)

    subject = build_receiver.build(described_class.key_attribute.to_s => key)
    expect(subject.delete).to be_truthy
  end
end

shared_examples 'a resource with a POST endpoint' do
  it 'saves a new resource' do
    stub_request(:post, site_url + described_class.collection_path(client, prefix))
      .to_return(status: 201, body: get_mock_from_path(:post))
    subject = build_receiver.build
    expect(subject.save(attributes_for_post)).to be_truthy
    expected_attributes_from_post.each do |method_name, value|
      expect(subject.send(method_name)).to eq(value)
    end
  end
end

shared_examples 'a resource with a PUT endpoint' do
  it 'saves an existing component' do
    stub_request(:get, site_url + described_class.singular_path(client, key, prefix))
      .to_return(status: 200, body: get_mock_from_path(:get, key:))
    stub_request(:put, site_url + described_class.singular_path(client, key, prefix))
      .to_return(status: 200, body: get_mock_from_path(:put, key:, value_if_not_found: nil))
    subject = build_receiver.build(described_class.key_attribute.to_s => key)
    subject.fetch
    expect(subject.save(attributes_for_put)).to be_truthy
    expected_attributes_from_put.each do |method_name, value|
      expect(subject.send(method_name)).to eq(value)
    end
  end
end

shared_examples 'a resource with a PUT endpoint that rejects invalid fields' do
  it 'fails to save with an invalid field' do
    stub_request(:get, site_url + described_class.singular_path(client, key))
      .to_return(status: 200, body: get_mock_from_path(:get, key:))
    stub_request(:put, site_url + described_class.singular_path(client, key))
      .to_return(status: 400, body: get_mock_from_path(:put, key:, suffix: 'invalid'))
    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.fetch

    expect(subject.save('fields' => { 'invalid' => 'field' })).to be_falsey
    expect do
      subject.save!('fields' => { 'invalid' => 'field' })
    end.to raise_error(JIRA::HTTPError)
  end
end
