module JIRA
  module Resource

    class UserFactory < JIRA::BaseFactory # :nodoc:
    end

    class User < JIRA::Base
      def self.singular_path(client, key, prefix = '/')
        collection_path(client, prefix) + '?username=' + key
      end
      
      def myself        
        myself_url = client.options[:rest_base_path] +  "/myself"
        response = client.get(myself_url)
        json = self.class.parse_json(response.body)
      end
    end
  end
end
