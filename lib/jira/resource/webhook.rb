# frozen_string_literal: true

module JIRA
  module Resource
    class WebhookFactory < JIRA::BaseFactory # :nodoc:
    end

    class Webhook < JIRA::Base
      REST_BASE_PATH = '/rest/webhooks/1.0'.freeze

      def self.endpoint_name
        'webhook'
      end

      def self.full_url(client)
        client.options[:context_path] + REST_BASE_PATH
      end

      def self.collection_path(client, prefix = '/')
        full_url(client) + prefix + endpoint_name
      end

      def self.all(client, options = {})
        response = client.get(collection_path(client))
        json = parse_json(response.body)
        json.map do |attrs|
          new(client, { attrs: }.merge(options))
        end
      end

      # def self.save(options={})
      # end

      # def self.delete(options={})

      # end
    end
  end
end
