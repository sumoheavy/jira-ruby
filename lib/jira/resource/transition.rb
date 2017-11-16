module JIRA
  module Resource
    class TransitionFactory < JIRA::BaseFactory # :nodoc:
    end

    class Transition < JIRA::Base
      has_one :to, :class => JIRA::Resource::Status
      belongs_to :issue

      nested_collections true

      def self.endpoint_name
        'transitions'
      end

      def self.available_names(issue)
        transition_names = []
        transitions      = all(issue.client, :issue => issue)
        transitions.each { |t| transition_names << t.name }
        transition_names
      end

      def self.find_id(issue, transition_name)
        transition = all(issue.client, issue: issue).detect do |trans|
          # Allows either a symbol or string to be passed through
          trans.name.downcase == transition_name.to_s.downcase.gsub('_', ' ')
        end
        transition ? transition.id : transition
      end

      def self.all(client, options = {})
        issue = options[:issue]
        unless issue
          raise ArgumentError.new("parent issue is required")
        end

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
