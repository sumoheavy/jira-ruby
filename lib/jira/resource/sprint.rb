# frozen_string_literal: true

module JIRA
  module Resource
    class SprintFactory < JIRA::BaseFactory # :nodoc:
    end

    class Sprint < JIRA::Base
      def self.find(client, key)
        response = client.get(agile_path(client, key))
        json = parse_json(response.body)
        client.Sprint.build(json)
      end

      # get all issues of sprint
      def issues(options = {})
        jql = "sprint = #{id}"
        jql += " and updated >= '#{options[:updated]}'" if options[:updated]
        Issue.jql(client, jql)
      end

      def add_issue(issue)
        add_issues([issue])
      end

      def add_issues(issues)
        issue_ids = issues.map(&:id)
        request_body = { issues: issue_ids }.to_json
        client.post("#{agile_path}/issue", request_body)
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
        attribute = instance_variable_get("@#{attribute_name}")
        return attribute if attribute

        get_sprint_details
        instance_variable_get("@#{attribute_name}")
      end

      def get_sprint_details
        search_url =
          "#{client.options[:site]}#{client.options[:client_path]}/rest/agile/1.0/sprint/#{id}"
        begin
          response = client.get(search_url)
        rescue StandardError
          return nil
        end
        json = self.class.parse_json(response.body)

        @start_date = json['sprint']['startDate'] && Date.parse(json['sprint']['startDate'])
        @end_date = json['sprint']['endDate'] && Date.parse(json['sprint']['endDate'])
        @completed_date = json['sprint']['completeDate'] && Date.parse(json['sprint']['completeDate'])
        @sprint_report = client.SprintReport.build(json['contents'])
      end

      def save(attrs = {}, _path = nil)
        attrs = @attrs if attrs.empty?
        super(attrs, agile_path)
      end

      def save!(attrs = {}, _path = nil)
        attrs = @attrs if attrs.empty?
        super(attrs, agile_path)
      end

      # WORK IN PROGRESS
      def complete
        complete_url = "#{client.options[:site]}/rest/greenhopper/1.0/sprint/#{id}/complete"
        response = client.put(complete_url)
        self.class.parse_json(response.body)
      end

      private

      def agile_path
        self.class.agile_path(client, id)
      end

      def self.agile_path(client, key)
        "#{client.options[:context_path]}/rest/agile/1.0/sprint/#{key}"
      end
    end
  end
end
