module JIRA
  module Resource

    class IssueFactory < BaseFactory ; end

    class Issue < Base

      def self.key_attribute
        :id
      end

    end

  end
end
