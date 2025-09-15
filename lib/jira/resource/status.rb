# frozen_string_literal: true

require_relative 'status_category'

module JIRA
  module Resource
    class StatusFactory < JIRA::BaseFactory # :nodoc:
    end

    class Status < JIRA::Base
      has_one :status_category, class: JIRA::Resource::StatusCategory, attribute_key: 'statusCategory'
    end
  end
end
