# frozen_string_literal: true

module JIRA
  module Resource
    class IssuelinktypeFactory < JIRA::BaseFactory # :nodoc:
    end

    class Issuelinktype < JIRA::Base
      nested_collections true

      def self.endpoint_name
        'issueLinkType'
      end
    end
  end
end
