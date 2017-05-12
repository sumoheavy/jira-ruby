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

        raise ArgumentError.new("parent issue is required") unless issue

        path     = "#{issue.self}/#{endpoint_name}"
        response = client.get path
        json     = parse_json response.body

        json['watchers'].map { |watcher| issue.watchers.build watcher }
      end

      # We have to override this, because it appears the watchers API
      # call to create a watcher is the only API call that doesn't use
      # a key/value hash, but simply just the username.
      #
      # issue = issue.watchers.build
      # issue.save! 'username'
      def save!(username)
        method, uri = if new_record?
                       [:post, url]
                      else
                       [:put, patched_url]
                      end

        client.send method, uri, username.to_json

        @expanded = false

        true
      end
    end
  end
end
