module JIRA
  module Resource

    class FieldFactory < JIRA::BaseFactory # :nodoc:
       delegate_to_target_class :map_fields, :name_to_id, :field_map
    end

    class Field < JIRA::Base
      def self.map_fields(client)
        field_map = {}
        field_map_reverse = {}
        fields = client.Field.all
        fields.each {|f|
          name = if field_map.key? f.name
            renamed = ("#{f.name}_#{f.id.split('_')[1]}").gsub(/[^a-zA-Z0-9]/,'_') rescue f.id
            warn "Duplicate Field name #{f.name} #{f.id} - renaming as #{renamed}"
            renamed
          else
            f.name.gsub(/[^a-zA-Z0-9]/,'_')
          end
          field_map[name] = f.id
          field_map_reverse[f.id] = [f.name, name] # capture both the official name, and the mapped name
        }
        client.cache.field_map = field_map
        client.cache.field_map_reverse = field_map_reverse   # not sure where this will be used yet, but sure to be useful
      end

      def self.field_map(client)
        client.cache.field_map
      end

      def self.name_to_id(client, field_name)
        field_name = field_name.to_s
        return field_name unless client.cache.field_map && client.cache.field_map[field_name]
        client.cache.field_map[field_name]
      end
    end
  end
end
