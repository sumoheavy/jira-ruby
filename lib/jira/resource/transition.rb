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

      # Saves the specified resource attributes by sending either a POST or PUT
      # request to JIRA, depending on resource.new_record?
      #
      # Accepts an attributes hash of the values to be saved.  Will throw a
      # JIRA::HTTPError if the request fails (response is not HTTP 2xx).
      def save!(attrs, path = nil)
        path = "#{client.options[:site]}#{client.options[:context]}/rest/api/2/issue/#{self.issue_id}/transitions"
        response = client.send(:post, path, attrs.to_json)
        set_attrs_from_response(response)
        @expanded = false
        true
      end
    end
  end
end
