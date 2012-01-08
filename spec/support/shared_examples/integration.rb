shared_examples "a resource with a singular GET endpoint" do

  it "should GET a single resource" do
    # E.g., for JIRA::Resource::Project, we need to call
    # client.Project.find()
    class_basename = described_class.name.split('::').last
    subject = client.send(class_basename).find(key)

    subject.should have_attributes(expected_attributes)
  end

  it "should build and fetch a single resource" do
    # E.g., for JIRA::Resource::Project, we need to call
    # client.Project.build('key' => 'ABC123')
    class_basename = described_class.name.split('::').last

    subject = client.send(class_basename).build(described_class.key_attribute.to_s => key)
    subject.fetch

    subject.should have_attributes(expected_attributes)
  end

end
