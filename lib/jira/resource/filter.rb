module JIRA
  module Resource
    class FilterFactory < JIRA::BaseFactory # :nodoc:
    end

    class Filter < JIRA::Base
      has_one :owner, class: JIRA::Resource::User

      # Returns all the issues for this filter
      def issues
        Issue.jql(client, jql)
      end
    end
  end
end
