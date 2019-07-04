module JIRA
  module Resource
    class WorklogFactory < JIRA::BaseFactory # :nodoc:
    end

    class Worklog < JIRA::Base
      has_one :author, class: JIRA::Resource::User
      has_one :update_author, class: JIRA::Resource::User,
                              attribute_key: 'updateAuthor'
      belongs_to :issue
      nested_collections true

      def self.endpoint_name
        'worklog'
      end

      def self.find(client, ids, remote_limit: 1000)
        return [] unless ids
        ids = Array(ids)
        worklogs_by_issue =
          ids.each_slice(remote_limit).map do |the_ids|
            response = client.post("#{client.options[:rest_base_path]}/#{endpoint_name}/list", JSON.dump({"ids"=>the_ids}))
            json = parse_json(response.body)
            json.map do |attrs|
              self.new(
                client,
                {
                  :attrs => attrs,
                  :issue => JIRA::Resource::Issue.new(
                    client,
                    :attrs => {'id' => attrs['issueId']}
                  )
                }
              )
            end
          end.flatten.group_by {|worklog| worklog.issue.id }

          worklog_issue_ids = worklogs_by_issue.keys
          issues =
            worklog_issue_ids.each_slice(remote_limit).map do |the_issue_ids|
              client.Issue.jql("id IN (#{the_issue_ids.join(',')})")
            end.flatten

          worklogs_by_issue.map do |issue_id, worklogs|
            the_issue = issues.find {|issue| issue.id == issue_id }
            worklogs.map do |worklog|
              self.new(
                client,
                {
                  :attrs => worklog.attrs,
                  :issue => the_issue
                }
              )
            end
          end.flatten
      end

      def self.modified_after(client, timestamp)
        response = client.get("#{client.options[:rest_base_path]}/#{endpoint_name}/updated?since=#{(timestamp.to_f * 1000).to_i}")
        json = JSON.parse(response.body)
        results = json['values']
        while json['lastPage'] == false
          response = client.get(json['nextPage'])
          json = JSON.parse(response.body)
          results += json['values']
        end
        find(client, results.map{|result| result['worklogId']})
      end

      def self.deleted_after(client, timestamp)
        response = client.get("#{client.options[:rest_base_path]}/#{endpoint_name}/deleted?since=#{(timestamp.to_f * 1000)}")
        json = JSON.parse response.body
        results = json['values']
        while json['lastPage'] == false
          response = client.get(json['nextPage'])
          json = JSON.parse(response.body)
          results += json['values']
        end
        find(client, results.map{|result| result['worklogId']})
      end

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue

        path = "#{issue.self}/#{endpoint_name}"
        response = client.get(path)
        json = parse_json(response.body)
        json['worklogs'].map do |worklog|
          issue.worklogs.build(worklog)
        end
      end
    end
  end
end
