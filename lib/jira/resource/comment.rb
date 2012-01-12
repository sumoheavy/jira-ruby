module JIRA
  module Resource

    class CommentFactory < JIRA::BaseFactory ; end

    class Comment < JIRA::Base
      belongs_to :issue

      nested_collections true
    end

  end
end
