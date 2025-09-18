# frozen_string_literal: true

require 'active_support/inflector'

module JIRA
  module Resource
    class PropertiesFactory < JIRA::BaseFactory # :nodoc:
    end

    class Properties < JIRA::Base
      belongs_to :issue

      def self.key_attribute
        :key
      end

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue

        response = client.get("#{issue.url}/#{endpoint_name}")
        json = parse_json(response.body)
        json[key_attribute.to_s.pluralize].map do |attrs|
          ## Net get the individual property
          self_response = client.get(attrs['self'])
          property = parse_json(self_response.body)
          ## Make sure to build the new resource via the issue.properties in order to support the has_many proxy
          issue.properties.build(property)
        end
      end

      ## Override save so we can handle the required attrs (and default 'value' when appropriate)
      def save!(attrs = {}, path = nil)
        if attrs.is_a?(Hash) && attrs.key?(self.class.key_attribute.to_s)
          raise ArgumentError, "Use of 'value' is required when '#{self.class.key_attribute}' is provided" \
            unless attrs.key?('value')

          set_attrs(self.class.key_attribute.to_s => attrs[self.class.key_attribute.to_s])
        end

        raise ArgumentError, "'key' is required on a new record" if new_record?

        path ||= patched_url
        ## We can take either the 'value' element from the hash, OR use the entire attrs as the value
        value = attrs.is_a?(Hash) && attrs.key?('value') ? attrs['value'] : attrs
        value = '' if value.nil?
        ## Note: this API endpoint requires a non-empty JSON body for the value of the property
        ## Note2: this API endpoint does not return a body, so no need to call set_attrs_from_response
        client.send(:put, path, value)
        set_attrs({ 'value' => value }, false)
        @expanded = false
        true
      end
    end
  end
end
