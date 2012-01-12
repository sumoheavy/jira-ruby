module JIRA
  module Resource

    class WorklogFactory < JIRA::BaseFactory ; end

    class Worklog < JIRA::Base
      has_one :author, :class => JIRA::Resource::User
      has_one :update_author, :class => JIRA::Resource::User,
                              :attribute_key => "updateAuthor"
      belongs_to :issue
      nested_collections true
    end

  end
end
