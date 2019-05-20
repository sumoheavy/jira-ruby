module JIRA
  module Resource
    class ChangelogFactory < JIRA::BaseFactory # :nodoc:
    end

    class Changelog < JIRA::Base
      belongs_to :issue

      nested_collections true

      def self.endpoint_name
        ''
      end

      def self.expand_value
        :changelog
      end

      def differences
        items[1]
      end

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue

        path = "#{issue.self}?expand=#{self.expand_value}"
        response = client.get(path)
        json = parse_json(response.body)
        # [
        #   'startAt',
        #   0,
        #   'maxResults',
        #   77,
        #   'total',
        #   77,
        #   'histories',
        #   [.......]
        # ]
        json['changelog']['histories'].map do |changelog|
          issue.changelogs.build(changelog)
        end
      end
    end
  end
end
