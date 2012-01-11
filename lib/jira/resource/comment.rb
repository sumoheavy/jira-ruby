module JIRA
  module Resource

    class CommentFactory < BaseFactory ; end

    class Comment < Base
      belongs_to :issue
    end

  end
end
