require 'cgi'

module JIRA
  module Resource

    class LinkFactory < JIRA::BaseFactory # :nodoc:
    end

    class Link < JIRA::Base
      nested_collections true
      def self.forIssue(client, issue_key)
        url = client.options[:rest_base_path] + "/issue/" + CGI.escape(issue_key) + "/remotelink"
        response = client.get(url)
        json = parse_json(response.body)
        json.map do |link|
          client.Link.build(link)
        end
      end
    end
  end
end
