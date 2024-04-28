# frozen_string_literal: true

module JIRA
  module Resource
    class IssuePickerSuggestionsIssueFactory < JIRA::BaseFactory # :nodoc:
    end

    class IssuePickerSuggestionsIssue < JIRA::Base
      has_many :issues, class: JIRA::Resource::SuggestedIssue
    end
  end
end
