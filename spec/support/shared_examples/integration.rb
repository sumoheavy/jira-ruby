shared_examples "a resource" do

  it "gracefully handles non-json responses" do
    class_basename = described_class.name.split('::').last
    stub_request(:put, "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}/99999").
                to_return(:status => 405, :body => "<html><body>Some HTML</body></html>")
    subject = client.send(class_basename).build(described_class.key_attribute.to_s => '99999')
    subject.save('foo' => 'bar').should be_false
    lambda do
      subject.save!('foo' => 'bar').should be_false
    end.should raise_error(JIRA::Resource::HTTPError)
  end

end

shared_examples "a resource with a collection GET endpoint" do

  it "should get the collection" do
    class_basename = described_class.name.split('::').last
    stub_request(:get,
                 "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}").
                 to_return(:status => 200, :body => get_mock_response("#{class_basename.downcase}.json"))
    collection = client.send(class_basename).all
    collection.length.should == 1

    first = collection.first
    first.should have_attributes(expected_attributes)
  end

end

shared_examples "a resource with a singular GET endpoint" do

  it "GETs a single resource" do
    # E.g., for JIRA::Resource::Project, we need to call
    # client.Project.find()
    class_basename = described_class.name.split('::').last
    stub_request(:get,
                "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}/#{key}").
                to_return(:status => 200, :body => get_mock_response("#{class_basename.downcase}/#{key}.json"))
    subject = client.send(class_basename).find(key)

    subject.should have_attributes(expected_attributes)
  end

  it "builds and fetches a single resource" do
    # E.g., for JIRA::Resource::Project, we need to call
    # client.Project.build('key' => 'ABC123')
    class_basename = described_class.name.split('::').last
    stub_request(:get,
                "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}/#{key}").
                to_return(:status => 200, :body => get_mock_response("#{class_basename.downcase}/#{key}.json"))

    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.fetch

    subject.should have_attributes(expected_attributes)
  end

  it "handles a 404" do
    class_basename = described_class.name.split('::').last
    stub_request(:get,
                "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}/99999").
                to_return(:status => 404, :body => '{"errorMessages":["'+class_basename+' Does Not Exist"],"errors": {}}')
    lambda do
      client.send(class_basename).find('99999')
    end.should raise_exception(JIRA::Resource::HTTPError)
  end
end

shared_examples "a resource with a DELETE endpoint" do
  it "deletes a resource" do
    # E.g., for JIRA::Resource::Project, we need to call
    # client.Project.delete()
    class_basename = described_class.name.split('::').last
    stub_request(:delete,
                "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}/#{key}").
                to_return(:status => 204, :body => nil)

    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.delete.should be_true
  end
end

shared_examples "a resource with a POST endpoint" do

  it "saves a new resource" do
    class_basename = described_class.name.split('::').last
    stub_request(:post, "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}").
                to_return(:status => 201, :body => get_mock_response("#{class_basename.downcase}.post.json"))
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
    stub_request(:get,
                "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}/#{key}").
                to_return(:status => 200, :body => get_mock_response("#{class_basename.downcase}/#{key}.json"))
    stub_request(:put,
                  "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}/#{key}").
                  to_return(:status => 200, :body => get_mock_response("#{class_basename.downcase}/#{key}.put.json", nil))
    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.fetch
    subject.save(attributes_for_put).should be_true
    expected_attributes_from_put.each do |method_name, value|
      subject.send(method_name).should == value
    end
  end

  it "fails to save with an invalid field" do
    class_basename = described_class.name.split('::').last
    stub_request(:get,
                "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}/#{key}").
                to_return(:status => 200, :body => get_mock_response("#{class_basename.downcase}/#{key}.json"))
    stub_request(:put, "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}/#{key}").
                to_return(:status => 400, :body => get_mock_response("#{class_basename.downcase}/#{key}.put.invalid.json"))
    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.fetch
    subject.save('fields'=> {'invalid' => 'field'}).should be_false
  end

  it "fails to save with an invalid field" do
    class_basename = described_class.name.split('::').last
    stub_request(:get,
                "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}/#{key}").
                to_return(:status => 200, :body => get_mock_response("#{class_basename.downcase}/#{key}.json"))
    stub_request(:put, "http://localhost:2990/jira/rest/api/2/#{class_basename.downcase}/#{key}").
                to_return(:status => 400, :body => get_mock_response("#{class_basename.downcase}/#{key}.put.invalid.json"))
    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.fetch
    lambda do
      subject.save!('fields'=> {'invalid' => 'field'})
    end.should raise_error(JIRA::Resource::HTTPError)
  end
end
