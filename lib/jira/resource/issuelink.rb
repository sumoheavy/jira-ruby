module JIRA
  module Resource
    class IssuelinkFactory < JIRA::BaseFactory # :nodoc:
    end

    # Because of circular dependency Issue->IssueLink->Issue
    # we have to declare JIRA::Resource::Issue class.
    class Issue < JIRA::Base; end

    class Issuelink < JIRA::Base
      has_one :type, class: JIRA::Resource::Issuelinktype
      has_one :inwardIssue, class: JIRA::Resource::Issue
      has_one :outwardIssue, class: JIRA::Resource::Issue

      def self.endpoint_name
        'issueLink'
      end
    end
  end
end
