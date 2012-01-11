module JIRA
  module Resource

    class WorklogFactory < BaseFactory ; end

    class Worklog < Base
      has_one :author, :class => JIRA::Resource::User
      has_one :update_author, :class => JIRA::Resource::User,
                              :attribute_key => "updateAuthor"
    end

  end
end
