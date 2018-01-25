module JIRA
  module Resource

    class WorklogFactory < JIRA::BaseFactory # :nodoc:
    end

    class Worklog < JIRA::Base
      has_one :author, :class => JIRA::Resource::User
      has_one :update_author, :class => JIRA::Resource::User,
                              :attribute_key => "updateAuthor"
      nested_collections true

      def self.all(client, options = {})
        url = client.options[:rest_base_path] + "/issue/#{options[:issue].key}/worklog"
        response = client.get(url)
        json = parse_json(response.body)
        json['worklogs'].map do |attrs|
          self.new(client, {:attrs => attrs})
        end
      end
    end

  end
end
