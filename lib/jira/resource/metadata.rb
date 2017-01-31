module JIRA
  module Resource
    class Metadata
      DEFAULT_REQUIRED_KEYS = ['project', 'issuetype', 'summary', 'reporter']

      attr_accessor :issuetypes, :raw_issuetypes, :main_custom_fields, :project, :project_key, :project_id
      def initialize(project, raw_issuetypes)
        @project          = project
        @project_id       = @project.id
        @project_key      = @project.key
        @raw_issuetypes   = raw_issuetypes
        @issuetypes =  @raw_issuetypes.map do |raw_issuetype|
          raw_issuetype.tap { |issuetype| issuetype["key"] = issuetype["name"].downcase }
        end

        @main_custom_fields = {}.with_indifferent_access
        issuetypes.each do |issuetype|
          fields = issuetype.fetch('fields')
          fields.each do |field|
            if ['Story Points', 'Epic Link', 'Sprint', 'Epic Name'].include? field[1]['name']
              label = "#{issuetype['name']} #{field[1]['name']}".downcase.parameterize
              @main_custom_fields[label] = field[0]
            end
          end
        end

      end

      def issuetype_info(issuetype_key)
        issuetypes.find { |issuetype| issuetype["key"] == issuetype_key.downcase } || {}
      end

      def required_fields(type)
        issuetypes.detect { |issuetype| issuetype['name'] == type }['fields']
            .select { |k, value| value['required'] }
      end

      def unsupported_fields(type)
        required_fields(type).reject { |key, v| (main_custom_fields.values+DEFAULT_REQUIRED_KEYS).include? v['key'] }
             .map { |k, value| value['name'] }
      end

      def [](key)
        @main_custom_fields[key] || ""
      end

      def to_h
        @main_custom_fields.merge({project_id: @project_id, project_key: @project_key})
      end

      def id
        "#{@project_key}-#{@project_id}"
      end

    end
  end
end
