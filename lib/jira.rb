$: << File.expand_path(File.dirname(__FILE__))

require 'active_support/inflector'
ActiveSupport::Inflector.inflections do |inflector|
  inflector.singular 'status', 'status'
end

require 'jira/base'
require 'jira/base_factory'
require 'jira/has_many_proxy'
require 'jira/http_error'

require 'jira/resource/user'
require 'jira/resource/attachment'
require 'jira/resource/component'
require 'jira/resource/issuetype'
require 'jira/resource/version'
require 'jira/resource/project'
require 'jira/resource/priority'
require 'jira/resource/status'
require 'jira/resource/comment'
require 'jira/resource/worklog'
require 'jira/resource/transition'
require 'jira/resource/issue'

require 'jira/request_client'
require 'jira/oauth_client'
require 'jira/http_client'
require 'jira/client'

require 'jira/railtie' if defined?(Rails)
