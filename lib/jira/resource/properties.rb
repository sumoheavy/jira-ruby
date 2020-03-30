require 'byebug'
module JIRA
  module Resource
    class PropertiesFactory < JIRA::BaseFactory # :nodoc:
    end

    class Properties < JIRA::Base
      belongs_to :issue

      def self.key_attribute
        'key'
      end

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue
        issue_properties = issue.properties
        response = client.get("#{issue.url}/#{endpoint_name}")
        json = parse_json(response.body)
        json['keys'].each do |prop|
          response = client.get(prop['self'])
          property = parse_json(response.body)
          issue_properties.build(property)
        end
        issue_properties
      end

      def self.find(client, key, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue
        ## Determine if we already have this property (via all or previous find)
        response = client.get("#{issue.url}/#{endpoint_name}/#{key}")
        property = parse_json(response.body)
        issue.properties.build(property)
      end

      ## force new_record? to false to always force :put (the only REST option for setting issue property)
      def new_record?
        false
      end

      def save!(attrs = {})
        attrs = @attrs if attrs.empty?
        super(attrs['value'], "#{url}/#{key_value}")
      end

      def save(attrs = {})
        attrs = @attrs if attrs.empty?
        super(attrs['value'], "#{url}/#{key_value}")
      end

    end
  end
end
