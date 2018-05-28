module JIRA
  module Resource

    class UserFactory < JIRA::BaseFactory # :nodoc:
      def myself
        instance = build
        response = client.get("#{client.options[:rest_base_path]}/myself")
        instance.set_attrs_from_response(response)
        instance
      end

      delegate_to_target_class :search, :search_path
    end

    class User < JIRA::Base
      def self.singular_path(client, key, prefix = '/')
        collection_path(client, prefix) + '?username=' + key
      end

      def self.search_path(client, search, prefix='/')
        collection_path(client, prefix) + '/search?username=' + search
      end

      def self.search(client, search, options = {})
        response = client.get(search_path(client, search))
        json = parse_json(response.body)
        if collection_attributes_are_nested
          json = json[endpoint_name.pluralize]
        end
        json.map do |attrs|
          self.new(client, { attrs: attrs }.merge(options))
        end
      end
    end

  end
end
