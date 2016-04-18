module JIRA
  module Resource

    class UserFactory < JIRA::BaseFactory # :nodoc:

    end

    class User < JIRA::Base
      def self.singular_path(client, key, prefix = '/')
        collection_path(client, prefix) + '?username=' + key
      end


      def self.all(client, options = {startAt: 0, maxResults: 50})
        client.Project.all.map do|project|
          fetches = []
          last_fetch = project.users(options)
          fetches << last_fetch
          while last_fetch.count == options[:maxResults]
            options[:startAt] += options[:maxResults]
            last_fetch = project.users(options)
            fetches << last_fetch
          end
          fetches
        end.flatten.group_by(&:attrs).map{|k,v| v.first}
      end
    end
  end
end
