# frozen_string_literal: true

module JIRA
  module Resource
    class WatcherFactory < JIRA::BaseFactory # :nodoc:
    end

    class Watcher < JIRA::Base
      belongs_to :issue

      nested_collections true

      def self.endpoint_name
        'watchers'
      end

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue

        path = "#{issue.self}/#{endpoint_name}"
        response = client.get(path)
        json = parse_json(response.body)
        json['watchers'].map do |watcher|
          issue.watchers.build(watcher)
        end
      end

      def save!(user_id, path = nil)
        path ||= new_record? ? url : patched_url
        response = client.post(path, user_id.to_json)
        true
      end

    end
  end
end
