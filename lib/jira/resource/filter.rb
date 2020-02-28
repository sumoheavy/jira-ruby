module JIRA
  module Resource
    class FilterFactory < JIRA::BaseFactory # :nodoc:
    end

    class Filter < JIRA::Base
      has_one :owner, class: JIRA::Resource::User

      # Returns all the issues for this filter
      def issues
        Issue.jql(client, jql)
      end

      # Returns all the favourite filters for the user
      def self.favourites(client, options = {})
        search_url = client.options[:rest_base_path] + '/filter/favourite'
        response = client.get(url_with_query_params(search_url, options))

        json = parse_json(response.body)
        client.Filter.build(json)
      end
    end
  end
end
