require 'cgi'

module JIRA

  class JQLEnum

    include Enumerable

    # The number of elements of the search results array that are GETed at a time.
    # TODO(corey): This value was plucked from thin air.
    @@fetch_size = 100

    # The number of issues returned in the JQL search result.
    # TODO(corey): my reading of the Enumerable documentation implies that with this defined #each
    # will not be called to determine count. From testing this doesn't appear to be the case.
    attr_reader :size

    # construct with an instance of Jira::Access and a JQL query string.
    def initialize(client, jql)

      @client = client
      @jql = jql
      @size = nil
      
      # Fetch a reasonable starting range. These results are used to determine the (presumed) max
      # number of results.
      # This max assumes, of course, that new entries are not added to Jira during the lifecycle of
      # this object.
      @fetched_results = fetch(0, @@fetch_size)
    end

    # Applies a block to each of the search results. Each search result is a Jira::Issue instance.
    #
    # See Enumerable for other methods of iteration this supports.
    def each(&f)
      total_iterated = 0
      while total_iterated < size
        issues = @fetched_results.map do |item|
          @client.Issue.build(item)
        end

        num_iterated = 0

        issues.each do |issue|
          num_iterated += 1
          f.call(issue)
        end
        
        total_iterated += num_iterated

        if total_iterated >= self.size then
          @fetched_results = nil
        else
          @fetched_results = fetch(total_iterated, @@fetch_size)
        end
      end
    end

    private

    # Returns elements with indices [low, low + count) from the search results
    # With each range fetch the count is updated.
    # The result is an array of hashes. Each hash has the properties:
    #   self => URL for the resource for this issue
    #   key  => Unique ID for this issue
    def fetch(low, count)
      url = @client.options[:rest_base_path] + "/search?jql=" + CGI.escape(@jql) + "&startAt=#{low}&maxResults=#{count}"

      response = @client.get(url)

      case response.code
      when '200'
        json = JSON.parse(response.body)
        @size = json["total"]
        return json['issues']
      else
        raise Exception, response.body
      end
    end
  end
end

