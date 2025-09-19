# frozen_string_literal: true

module JIRA
  module Resource
    class CommentFactory < JIRA::BaseFactory # :nodoc:
    end

    class Comment < JIRA::Base
      belongs_to :issue

      nested_collections true

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue

        response = client.get("#{issue.url}/#{endpoint_name}")
        json = parse_json(response.body)
        json = json[endpoint_name.pluralize]
        json.map do |attrs|
          new(client, { attrs: }.merge(options))
        end
      end
    end
  end
end
