module ClientsHelper
  def with_each_client(opts = {}, &)
    clients = {}

    oauth_client = JIRA::Client.new({ consumer_key: 'foo', consumer_secret: 'bar' }.merge(opts))
    oauth_client.set_access_token('abc', '123')
    clients['http://localhost:2990'] = oauth_client

    basic_client = JIRA::Client.new({ username: 'foo', password: 'bar', auth_type: :basic, use_ssl: false }.merge(opts))
    clients['http://localhost:2990'] = basic_client

    clients.each(&)
  end
end
