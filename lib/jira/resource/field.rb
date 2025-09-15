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
        fields = client.Field.all

        # two pass approach, so that a custom field with the same name
        # as a system field can't take precedence
        fields.each do |f|
          next if f.custom

          name = safe_name(f.name)
          field_map[name] = f.id
        end

        fields.each do |f| # rubocop:disable Style/CombinableLoops
          next unless f.custom

          name = if field_map.key? f.name
                   renamed = safer_name(f.name, f.id)
                   warn "Duplicate Field name #{f.name} #{f.id} - renaming as #{renamed}"
                   renamed
                 else
                   safe_name(f.name)
                 end
          field_map[name] = f.id
        end

        client.field_map_cache = field_map
      end

      def self.field_map(client)
        client.field_map_cache
      end

      def self.name_to_id(client, field_name)
        field_name = field_name.to_s
        return field_name unless client.field_map_cache && client.field_map_cache[field_name]

        client.field_map_cache[field_name]
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
            super
          end
        end
      end
    end
  end
end
