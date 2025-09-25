# frozen_string_literal: true

module JIRA
  module Resource
    class RemotelinkFactory < JIRA::BaseFactory # :nodoc:
    end

    class Remotelink < JIRA::Base
      belongs_to :issue

      def self.endpoint_name
        'remotelink'
      end

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue

        path = client.options[:rest_base_path] + "/issue/#{issue.key}/#{endpoint_name}"
        response = client.get(path)
        json = parse_json(response.body)
        json.map do |link|
          issue.remotelink.build(link)
        end
      end
    end
  end
end
