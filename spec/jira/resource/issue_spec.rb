require 'spec_helper'

describe JIRA::Resource::Issue do

  let(:client) { mock() }

  it "should find an issue by key or id" do
    response = mock()
    response.stub(:body).and_return('{"key":"foo","id":"101"}')
    JIRA::Resource::Issue.stub(:rest_base_path).and_return('/jira/rest/api/2/issue')
    client.should_receive(:get).with('/jira/rest/api/2/issue/foo')
    .and_return(response)
    client.should_receive(:get).with('/jira/rest/api/2/issue/101')
    .and_return(response)

    issue_from_id = JIRA::Resource::Issue.find(client,101)
    issue_from_key = JIRA::Resource::Issue.find(client,'foo')

    issue_from_id.attrs.should == issue_from_key.attrs
  end

  it "provides direct accessors to the fields" do
    subject = JIRA::Resource::Issue.new(client, :attrs => {'fields' => {'foo' =>'bar'}})
    subject.should respond_to(:foo)
    subject.foo.should == 'bar'
  end

  describe "relationships" do
    subject {
      JIRA::Resource::Issue.new(client, :attrs => {
        'fields' => {
          'reporter'    => {'foo' => 'bar'},
          'assignee'    => {'foo' => 'bar'},
          'project'     => {'foo' => 'bar'},
          'priority'    => {'foo' => 'bar'},
          'issuetype'   => {'foo' => 'bar'},
          'status'      => {'foo' => 'bar'},
          'components'  => [{'foo' => 'bar'}, {'baz' => 'flum'}],
          'comment'     => { 'comments' => [{'foo' => 'bar'}, {'baz' => 'flum'}]},
          'attachment'  => [{'foo' => 'bar'}, {'baz' => 'flum'}]
        }
      })
    }

    it "has the correct relationships" do
      subject.should have_one(:reporter, JIRA::Resource::User)
      subject.reporter.foo.should == 'bar'

      subject.should have_one(:assignee, JIRA::Resource::User)
      subject.assignee.foo.should == 'bar'

      subject.should have_one(:project, JIRA::Resource::Project)
      subject.project.foo.should == 'bar'

      subject.should have_one(:issuetype, JIRA::Resource::Issuetype)
      subject.issuetype.foo.should == 'bar'

      subject.should have_one(:priority, JIRA::Resource::Priority)
      subject.priority.foo.should == 'bar'

      subject.should have_one(:status, JIRA::Resource::Status)
      subject.status.foo.should == 'bar'

      subject.should have_many(:components, JIRA::Resource::Component)
      subject.components.length.should == 2

      subject.should have_many(:comments, JIRA::Resource::Comment)
      subject.comments.length.should == 2

      subject.should have_many(:attachments, JIRA::Resource::Attachment)
      subject.attachments.length.should == 2
    end
  end
end
