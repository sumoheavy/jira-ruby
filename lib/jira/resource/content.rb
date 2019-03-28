require 'cgi'
require 'json'

module JIRA
  module Resource
    class ContentFactory < JIRA::BaseFactory # :nodoc:
    end

    class Content < JIRA::Base
      def self.fetch_template(client, key)
        url = client.options[:site] + client.options[:rest_base_path] + "/template/#{key}"
        response = client.get(url)
        json = parse_json(response.body)
        client.Content.build(json)
      end

      def self.all(client, options = {})
        start_at = 0
        max_results = 25
        data = []
        loop do
          url = client.options[:site] + 
            client.options[:rest_base_path] +
            "/content?limit=#{max_results}&start=#{start_at}"

          response = client.get(url)
          json = parse_json(response.body)
          json['results'].map do |result|
            data.push(client.Content.build(result))
          end
          break if json['results'].empty?
          start_at += json['results'].size
        end
        data
      end
    end
  end
end
