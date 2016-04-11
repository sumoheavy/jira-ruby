require 'cgi'

module JIRA
  module Resource

    class IssueCountFactory < JIRA::BaseFactory # :nodoc:
    end

    class IssueCount < JIRA::Base

      def self.all(client)
        url = client.options[:rest_base_path] + "/search?expand=transitions.fields"
        response = client.get(url)
        json = parse_json(response.body)
        return json[:total]
        end
      end

      def self.jql(client, jql, options = {fields: nil, start_at: nil, max_results: 0, expand: nil})
        url = client.options[:rest_base_path] + "/search?jql=" + CGI.escape(jql)

        url << "&fields=#{options[:fields].map{ |value| CGI.escape(value.to_s) }.join(',')}" if options[:fields]
        url << "&startAt=#{CGI.escape(options[:start_at].to_s)}" if options[:start_at]
        url << "&maxResults=#{CGI.escape(options[:max_results].to_s)}" if options[:max_results]

        if options[:expand]
          options[:expand] = [options[:expand]] if options[:expand].is_a?(String)
          url << "&expand=#{options[:expand].to_a.map{ |value| CGI.escape(value.to_s) }.join(',')}"
        end

        response = client.get(url)
        json = parse_json(response.body)
        return json[:total]
        end
      end

    end

  end
end
