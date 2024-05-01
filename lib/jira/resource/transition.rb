# frozen_string_literal: true

module JIRA
  module Resource
    class TransitionFactory < JIRA::BaseFactory # :nodoc:
    end

    class Transition < JIRA::Base
      has_one :to, class: JIRA::Resource::Status
      belongs_to :issue

      nested_collections true

      def self.endpoint_name
        'transitions'
      end

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue

        path = "#{issue.self}/#{endpoint_name}?expand=transitions.fields"
        response = client.get(path)
        json = parse_json(response.body)
        json['transitions'].map do |transition|
          issue.transitions.build(transition)
        end
      end
    end
  end
end
