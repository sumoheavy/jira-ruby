module JIRA
  module Resource

    class SprintFactory < JIRA::BaseFactory # :nodoc:
    end

    class Sprint < JIRA::Base

      def self.find(client, key)
        response = client.get(client.options[:site] + '/rest/greenhopper/1.0/sprint/' + key.to_s + '/edit/model')
        json = parse_json(response.body)
        client.Sprint.build(json['sprint'])
      end

      # get all issues of sprint
      def issues(options = {})
        jql = 'sprint = ' + id.to_s
        jql += " and updated >= '#{options[:updated]}'" if options[:updated]
        Issue.jql(client, jql)
      end

      def add_issue(issue)
        request_body = {issues: [issue.id]}.to_json
        response = client.post(client.options[:site] + '/rest/agile/1.0/sprint/' + self.id + '/issue', request_body)
        true
      end

      def sprint_report
        get_sprint_details_attribute('sprint_report')
      end

      def start_date
        get_sprint_details_attribute('start_date')
      end

      def end_date
        get_sprint_details_attribute('end_date')
      end

      def complete_date
        get_sprint_details_attribute('complete_date')
      end

      def get_sprint_details_attribute(attribute_name)
        attribute = self.instance_variable_get("@#{attribute_name}")
        if attribute
          return attribute
        end
        get_sprint_details
        self.instance_variable_get("@#{attribute_name}")
      end

      def get_sprint_details
        search_url = client.options[:site] + '/rest/greenhopper/1.0/rapid/charts/sprintreport?rapidViewId=' +
          rapidview_id.to_s + '&sprintId=' + id.to_s
        begin
          response = client.get(search_url)
        rescue
          return nil
        end
        json = self.class.parse_json(response.body)

        @start_date = Date.parse(json['sprint']['startDate']) unless json['sprint']['startDate'] == 'None'
        @end_date = Date.parse(json['sprint']['endDate']) unless json['sprint']['endDate'] == 'None'
        @completed_date = Date.parse(json['sprint']['completeDate']) unless json['sprint']['completeDate'] == 'None'
        @sprint_report = client.SprintReport.build(json['contents'])
      end

      def rapidview_id
        if @attrs['rapidview_id']
          return @attrs['rapidview_id']
        end
        search_url = client.options[:site] + '/secure/GHGoToBoard.jspa?sprintId=' + id.to_s
        begin
          response = client.get(search_url)
        rescue JIRA::HTTPError => error
          unless error.response.instance_of? Net::HTTPFound
            return
          end
          rapid_view_match = /rapidView=(\d+)&/.match(error.response['location'])
          if rapid_view_match != nil
            @attrs['rapidview_id'] = rapid_view_match[1]
          end
        end
      end


      # WORK IN PROGRESS
      def complete
        complete_url = client.options[:site] + '/rest/greenhopper/1.0/sprint/' + id.to_s + '/complete'
        response = client.put(complete_url)
        self.class.parse_json(response.body)
      end

      def save(attrs = {})
        return unless rapidview_id.is_a?(Integer)
        url_key = new_record? ? rapidview_id : id
        url = client.options[:site] + '/rest/greenhopper/1.0/sprint/' + url_key.to_s
        super(attrs, url)
      end

    end
  end
end
