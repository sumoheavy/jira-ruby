# frozen_string_literal: true

module JIRA
  module Resource
    class FieldFactory < JIRA::BaseFactory # :nodoc:
      delegate_to_target_class :map_fields, :name_to_id, :field_map
    end

    class Field < JIRA::Base
      # translate a custom field description to a method-safe name
      def self.safe_name(description)
        description.gsub(/[^a-zA-Z0-9]/, '_')
      end

      # safe_name plus disambiguation if it fails it uses the original jira id (customfield_#####)
      def self.safer_name(description, jira_id)
        "#{safe_name(description)}_#{jira_id.split('_')[1]}"
      rescue StandardError
        jira_id
      end

      def self.map_fields(client)
        field_map = {}
        field_map_reverse = {}
        fields = client.Field.all

        # two pass approach, so that a custom field with the same name
        # as a system field can't take precedence
        fields.each do |f|
          next if f.custom

          name = safe_name(f.name)
          field_map_reverse[f.id] = [f.name, name] # capture both the official name, and the mapped name
          field_map[name] = f.id
        end

        fields.each do |f|
          next unless f.custom

          name = if field_map.key? f.name
                   renamed = safer_name(f.name, f.id)
                   warn "Duplicate Field name #{f.name} #{f.id} - renaming as #{renamed}"
                   renamed
                 else
                   safe_name(f.name)
                 end
          field_map_reverse[f.id] = [f.name, name] # capture both the official name, and the mapped name
          field_map[name] = f.id
        end

        client.cache.field_map_reverse = field_map_reverse # not sure where this will be used yet, but sure to be useful
        client.cache.field_map = field_map
      end

      def self.field_map(client)
        client.cache.field_map
      end

      def self.name_to_id(client, field_name)
        field_name = field_name.to_s
        return field_name unless client.cache.field_map && client.cache.field_map[field_name]

        client.cache.field_map[field_name]
      end

      def respond_to?(method_name, _include_all = false)
        if [method_name.to_s, client.Field.name_to_id(method_name)].any? { |k| attrs.key?(k) }
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &)
        if attrs.key?(method_name.to_s)
          attrs[method_name.to_s]
        else
          official_name = client.Field.name_to_id(method_name)
          if attrs.key?(official_name)
            attrs[official_name]
          else
            super(method_name, *args, &)
          end
        end
      end
    end
  end
end
