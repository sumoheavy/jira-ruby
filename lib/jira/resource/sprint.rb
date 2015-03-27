module JIRA
  module Resource

    class SprintFactory < JIRA::BaseFactory # :nodoc:
    end

    class Sprint < JIRA::Base
      # get all issues of sprint
      def issues
        jql = "sprint = " + id.to_s
        Issue.jql(client, jql)
      end

      def sprint_report
        get_sprint_details_attribute('sprint_report')
      end

      def start_date
        get_sprint_details_attribute("start_date")
      end

      def end_date
        get_sprint_details_attribute("end_date")
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
        search_url = client.options[:site] + "/rest/greenhopper/1.0/rapid/charts/sprintreport?rapidViewId=" +
          rapidview_id.to_s + "&sprintId=" + id.to_s
        begin
          response = client.get(search_url)
        rescue
          return nil
        end
        json = self.class.parse_json(response.body)
        @start_date = Date.parse(json['sprint']['startDate'])
        @end_date = Date.parse(json['sprint']['endDate'])
        @sprint_report = client.SprintReport.build(json['contents'])
      end

      def rapidview_id
        if @attrs['rapidview_id']
          return @attrs['rapidview_id']
        end
        search_url = client.options[:site] + "/secure/GHGoToBoard.jspa?sprintId=" + id.to_s
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

    end
  end
end