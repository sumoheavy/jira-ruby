require 'spec_helper'

describe JiraRuby::Resource::Project do

  let(:client)  { mock() }
  let(:attrs)   { mock() }

  subject { JiraRuby::Resource::Project.new(client, attrs) }

  it "assigns the client and attrs" do
    subject.client.should == client
    subject.attrs.should  == attrs
  end

  it "returns all the projects" do
    response = mock()
    response.should_receive(:body).and_return('[{"self":"http://foo/","key":"FOO"}]')
    client.should_receive(:get).with('/jira/rest/api/2.0.alpha1/project').and_return(response)
    projects = JiraRuby::Resource::Project.all(client)
    projects.length.should == 1
    first = projects.first
    first.class.should == JiraRuby::Resource::Project
    first.attrs['self'].should  == 'http://foo/'
    first.attrs['key'].should   == 'FOO'
  end

  it "finds a project by key" do
    response = mock()
    response.should_receive(:body).and_return('{"self":"http://foo/","key":"FOO"}')
    client.should_receive(:get).with('/jira/rest/api/2.0.alpha1/project/FOO').and_return(response)
    project = JiraRuby::Resource::Project.find(client, 'FOO')
    project.client.should == client
    project.attrs['self'].should  == 'http://foo/'
    project.attrs['key'].should   == 'FOO'
  end

  describe "dynamic instance methods" do

    let(:attrs) { {'foo' => 'bar', 'flum' => 'goo', 'object_id' => 'dummy'} }
    subject     { JiraRuby::Resource::Project.new(client, attrs.to_json) }

    it "responds to each of the top level attribute names" do
      project = JiraRuby::Resource::Project.new(client, attrs)
      project.should respond_to(:foo)
      project.should respond_to('flum')
      project.should respond_to(:object_id)

      project.foo.should  == 'bar'
      project.flum.should == 'goo'

      # Should not override existing method names, but should still allow
      # access to their values via the attrs[] hash
      project.object_id.should_not == 'dummy'
      project.attrs['object_id'].should == 'dummy'
    end
  end
end
