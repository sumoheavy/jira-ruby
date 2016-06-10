module JIRA
  module Resource

    class CreatemetaFactory < JIRA::BaseFactory # :nodoc:
    end

    class Createmeta < JIRA::Base
      def self.endpoint_name
        '/issue/createmeta'
      end

      def self.all(client, params={})

        if params.has_key?(:projectKeys)
          values = Array(params[:projectKeys]).map{|i| (i.is_a?(JIRA::Resource::Project) ? i.key : i)}
          params[:projectKeys] = values.join(',')
        end

        if params.has_key?(:projectIds)
          values = Array(params[:projectIds]).map{|i| (i.is_a?(JIRA::Resource::Project) ? i.id : i)}
          params[:projectIds] = values.join(',')
        end

        if params.has_key?(:issuetypeNames)
          values = Array(params[:issuetypeNames]).map{|i| (i.is_a?(JIRA::Resource::Issuetype) ? i.name : i)}
          params[:issuetypeNames] = values.join(',')
        end

        if params.has_key?(:issuetypeIds)
          values = Array(params[:issuetypeIds]).map{|i| (i.is_a?(JIRA::Resource::Issuetype) ? i.id : i)}
          params[:issuetypeIds] = values.join(',')
        end

        create_meta_url = client.options[:rest_base_path] + self.endpoint_name
        params = hash_to_query_string(params)

        response = params.empty? ? client.get("#{create_meta_url}") : client.get("#{create_meta_url}?#{params}")

        json = parse_json(response.body)
        self.new(client, {:attrs => json['projects']})
      end

      def self.hash_to_query_string(query_params)
        query_params.map do |k,v|
          CGI.escape(k.to_s) + '=' + CGI.escape(v.to_s)
        end.join('&')
      end

    end

  end
end
