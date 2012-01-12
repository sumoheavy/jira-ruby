module JIRA
  module Resource

    class CommentFactory < BaseFactory ; end

    class Comment < Base
      belongs_to :issue

      nested_collections true
    end

  end
end
