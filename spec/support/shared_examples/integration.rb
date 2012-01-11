def get_mock_from_path(method, options = {})#,key = nil, value_if_not_found = false)

  if defined? belongs_to
    prefix = belongs_to.path_component + '/'
  else
    prefix = ''
  end

  if options[:url]
    url = options[:url]
  elsif options[:key]
    url = described_class.singular_path(client, options[:key], prefix)
  else
    url = described_class.collection_path(client, prefix)
  end
  file_path = url.sub(client.options[:rest_base_path], '')
  file_path = file_path + '.' + options[:suffix] if options[:suffix]
  file_path = file_path + '.' + method.to_s unless method == :get
  value_if_not_found = options.keys.include?(:value_if_not_found) ? options[:value_if_not_found] : false
  get_mock_response("#{file_path}.json", value_if_not_found)
end

shared_examples "a resource" do

  it "gracefully handles non-json responses" do
    class_basename = described_class.name.split('::').last
    if defined? target
      subject = target
    else
      subject = client.send(class_basename).build(described_class.key_attribute.to_s => '99999')
    end
    stub_request(:put, 'http://localhost:2990' + subject.url).
                to_return(:status => 405, :body => "<html><body>Some HTML</body></html>")
    subject.save('foo' => 'bar').should be_false
    lambda do
      subject.save!('foo' => 'bar').should be_false
    end.should raise_error(JIRA::Resource::HTTPError)
  end

end

shared_examples "a resource with a collection GET endpoint" do

  it "should get the collection" do
    class_basename = described_class.name.split('::').last
    stub_request(:get, "http://localhost:2990" + described_class.collection_path(client)).
                 to_return(:status => 200, :body => get_mock_from_path(:get))
    collection = client.send(class_basename).all
    collection.length.should == expected_collection_length

    first = collection.first
    first.should have_attributes(expected_attributes)
  end

end

shared_examples "a resource with a singular GET endpoint" do

  it "GETs a single resource" do
    # E.g., for JIRA::Resource::Project, we need to call
    # client.Project.find()
    class_basename = described_class.name.split('::').last
    options = {}
    prefix = '/'
    if defined? belongs_to
      options[belongs_to.to_sym] = belongs_to
      prefix = belongs_to.path_component + '/'
    end
    stub_request(:get, "http://localhost:2990" + described_class.singular_path(client, key, prefix)).
                to_return(:status => 200, :body => get_mock_from_path(:get, :key => key))
    subject = client.send(class_basename).find(key, options)

    subject.should have_attributes(expected_attributes)
  end

  it "builds and fetches a single resource" do
    # E.g., for JIRA::Resource::Project, we need to call
    # client.Project.build('key' => 'ABC123')
    class_basename = described_class.name.split('::').last
    options = {}
    prefix = '/'
    if defined? belongs_to
      options[belongs_to.to_sym] = belongs_to
      prefix = belongs_to.path_component + '/'
    end
    stub_request(:get, "http://localhost:2990" + described_class.singular_path(client, key, prefix)).
                to_return(:status => 200, :body => get_mock_from_path(:get, :key => key))

    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.fetch

    subject.should have_attributes(expected_attributes)
  end

  it "handles a 404" do
    class_basename = described_class.name.split('::').last
    options = {}
    prefix = '/'
    if defined? belongs_to
      options[belongs_to.to_sym] = belongs_to
      prefix = belongs_to.path_component + '/'
    end
    stub_request(:get, "http://localhost:2990" + described_class.singular_path(client, '99999', prefix)).
                to_return(:status => 404, :body => '{"errorMessages":["'+class_basename+' Does Not Exist"],"errors": {}}')
    lambda do
      client.send(class_basename).find('99999', options)
    end.should raise_exception(JIRA::Resource::HTTPError)
  end
end

shared_examples "a resource with a DELETE endpoint" do
  it "deletes a resource" do
    # E.g., for JIRA::Resource::Project, we need to call
    # client.Project.delete()
    class_basename = described_class.name.split('::').last
    stub_request(:delete, "http://localhost:2990" + described_class.singular_path(client, key)).
                to_return(:status => 204, :body => nil)

    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.delete.should be_true
  end
end

shared_examples "a resource with a POST endpoint" do

  it "saves a new resource" do
    class_basename = described_class.name.split('::').last
    stub_request(:post, "http://localhost:2990" + described_class.collection_path(client)).
                to_return(:status => 201, :body => get_mock_from_path(:post))
    subject = client.send(class_basename).build
    subject.save(attributes_for_post).should be_true
    expected_attributes_from_post.each do |method_name, value|
      subject.send(method_name).should == value
    end
  end

end

shared_examples "a resource with a PUT endpoint" do

  it "saves an existing component" do
    class_basename = described_class.name.split('::').last
    stub_request(:get, "http://localhost:2990" + described_class.singular_path(client, key)).
                to_return(:status => 200, :body => get_mock_from_path(:get, :key =>key))
    stub_request(:put, "http://localhost:2990" + described_class.singular_path(client, key)).
                  to_return(:status => 200, :body => get_mock_from_path(:put, :key => key, :value_if_not_found => nil))
    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.fetch
    subject.save(attributes_for_put).should be_true
    expected_attributes_from_put.each do |method_name, value|
      subject.send(method_name).should == value
    end
  end

  it "fails to save with an invalid field" do
    class_basename = described_class.name.split('::').last
    stub_request(:get, "http://localhost:2990" + described_class.singular_path(client, key)).
                to_return(:status => 200, :body => get_mock_from_path(:get, :key => key))
    stub_request(:put, "http://localhost:2990" + described_class.singular_path(client, key)).
                to_return(:status => 400, :body => get_mock_from_path(:put, :key => key, :suffix => "invalid"))
    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.fetch
    subject.save('fields'=> {'invalid' => 'field'}).should be_false
  end

  it "fails to save with an invalid field" do
    class_basename = described_class.name.split('::').last
    stub_request(:get, "http://localhost:2990" + described_class.singular_path(client, key)).
                #to_return(:status => 200, :body => get_mock_response("#{class_basename.downcase}/#{key}.json"))
                to_return(:status => 200, :body => get_mock_from_path(:get, :key => key))
    stub_request(:put, "http://localhost:2990" + described_class.singular_path(client, key)).
                #to_return(:status => 400, :body => get_mock_response("#{class_basename.downcase}/#{key}.put.invalid.json"))
                to_return(:status => 400, :body => get_mock_from_path(:put, :key => key, :suffix => "invalid"))
    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.fetch
    lambda do
      subject.save!('fields'=> {'invalid' => 'field'})
    end.should raise_error(JIRA::Resource::HTTPError)
  end
end
