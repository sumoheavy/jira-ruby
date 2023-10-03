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

      def self.vputs(msg)
        puts msg if verbose_log
      end 

      def self.verbose_log
        return @verbose_log unless @verbose_log.nil?
        @verbose_log = ENV.fetch('WORKLOG_VERBOSE_FETCH') { false }
      end

      def self.modified_after(client, timestamp, with_hydrated_issues: true, filter: nil)
        response = client.get("#{client.options[:rest_base_path]}/#{endpoint_name}/updated?since=#{(timestamp.to_f * 1000).to_i}")
        json = JSON.parse(response.body)
        results = json['values']
        while json['lastPage'] == false
          vputs "Fetching next page of worklogs..."
          vputs "Loaded #{results.count} so far"
          vputs "Last..."
          vputs results.last.to_yaml
          response = client.get(json['nextPage'])
          json = JSON.parse(response.body)
          results += json['values']
        end
        vputs 'finding'
        find(client, results.map{|result| result['worklogId']}, with_hydrated_issues: with_hydrated_issues, filter: filter)
      end
    
      def self.deleted_after(client, timestamp)
        response = client.get("#{client.options[:rest_base_path]}/#{endpoint_name}/deleted?since=#{(timestamp.to_f * 1000).to_i}")
        json = JSON.parse response.body
        results = json['values']
        while json['lastPage'] == false
          response = client.get(json['nextPage'])
          json = JSON.parse(response.body)
          results += json['values']
        end
        results.map do |wl|
          JIRA::Resource::Worklog.new(
            client,
            :attrs => wl.merge({'id' => wl['worklogId'] }),
            :issue => JIRA::Resource::Issue.new(
                    client,
                    :attrs => {'id' => 'non'}
                  )
          )
        end 
      end
    
      def self.find(client, ids, remote_limit: 666, with_hydrated_issues: true, filter: nil)
        return [] unless ids
        running_total = 0
        ids = Array(ids)
        worklogs =
          ids.each_slice(remote_limit).map do |the_ids|
            vputs 'Finding another set of '
            vputs the_ids.count 
            running_total += the_ids.count
            response = client.post("#{client.options[:rest_base_path]}/#{endpoint_name}/list", JSON.dump({"ids"=>the_ids}))
            json = parse_json(response.body)
            vputs "total searched: #{running_total}" 
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
          end.flatten
    
        filtered_worklogs =
          case
          when filter
            filter.call(worklogs)
          else
            worklogs
          end
        return filtered_worklogs unless with_hydrated_issues
        rehydrate_worklog_issues_for_worklogs client, filtered_worklogs
      end
    
      def self.rehydrate_worklog_issues_for_worklogs(client, worklawgs)
        worklogs_by_issue = worklawgs.group_by {|worklog| worklog.issue.id }
        worklog_issue_ids = worklogs_by_issue.keys.compact
        vputs 'rehydrating issues'
        rehydrated = 0
        issue_batch_size = 
          case client.request_client 
          when JIRA::OauthClient
            puts '== Y! REQUEST CLIENT IS'
            puts client.request_client.class.name 
            5
          else 
            puts '== N! REQUEST CLIENT IS'
            puts client.request_client.class.name 

            100 
          end 

          issues =
          worklog_issue_ids.each_slice(issue_batch_size).map do |the_issue_ids|
            rehydrated += the_issue_ids.count
            vputs 'Rehydrated issue count'
            vputs rehydrated 
            vputs 'of' 
            vputs worklog_issue_ids.count
            puts the_issue_ids.count
            puts "id IN (#{the_issue_ids.join(',')})"
            client.Issue.jql("id IN (#{the_issue_ids.join(',')})")
          end.compact.flatten
    
        missing_issue_ids = worklog_issue_ids - (issues.map(&:id))
        if missing_issue_ids.count.positive?
          vputs "MISSING #{missing_issue_ids.count} out of #{worklog_issue_ids.count} issues during lookup" 
          vputs "They will be retrieved manually during worklog storage"
        end
        worklogs_by_issue.map do |issue_id, worklogs|
          found_issue = issues.find {|issue| issue.id == issue_id }
          the_issue = case
            when found_issue
              found_issue
            else
              # iss = 
                # begin 
                #  vputs 'fetching issue with id'
                #  vputs issue_id
                #   client.Issue.find(issue_id)
                # rescue 
                #  vputs "There was an issue retrieving the issue with id #{issue_id}"
                #  vputs $!.message.first(100)
                #  vputs $!.backtrace.first(50)
    
                  iz = JIRA::Resource::Issue.new(
                    client,
                    :attrs => {'id' => issue_id }
                  )
                  # iz.instance_variable_set('@deleted', true)
                  iz  
              #   end 
              # iss
            end
    
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
