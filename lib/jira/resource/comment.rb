module JIRA
  module Resource

    class CommentFactory < JIRA::BaseFactory # :nodoc:
    end

    class Comment < JIRA::Base
      belongs_to :issue

      nested_collections true
      nested_under :issue
    end

  end
end
