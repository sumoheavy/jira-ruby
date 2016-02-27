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
        unless issue
          raise ArgumentError.new("parent issue is required")
        end

        path = "#{issue.self}/#{endpoint_name}"
        response = client.get(path)
        json = parse_json(response.body)
        json.map do |link|
          issue.remotelink.build(link)
        end
      end
    end
  end
end
