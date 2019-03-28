$LOAD_PATH << __dir__

require 'active_support/inflector'
ActiveSupport::Inflector.inflections do |inflector|
  inflector.singular /status$/, 'status'
end

# JIRA Base
require 'jira/base'
require 'jira/base_factory'
require 'jira/has_many_proxy'
require 'jira/http_error'

# JIRA Resources
require 'jira/resource/user'
require 'jira/resource/watcher'
require 'jira/resource/attachment'
require 'jira/resource/component'
require 'jira/resource/issuetype'
require 'jira/resource/version'
require 'jira/resource/status'
require 'jira/resource/transition'
require 'jira/resource/project'
require 'jira/resource/priority'
require 'jira/resource/comment'
require 'jira/resource/worklog'
require 'jira/resource/applinks'
require 'jira/resource/issuelinktype'
require 'jira/resource/issuelink'
require 'jira/resource/remotelink'
require 'jira/resource/sprint'
require 'jira/resource/sprint_report'
require 'jira/resource/issue'
require 'jira/resource/filter'
require 'jira/resource/field'
require 'jira/resource/rapidview'
require 'jira/resource/resolution'
require 'jira/resource/serverinfo'
require 'jira/resource/createmeta'
require 'jira/resource/webhook'
require 'jira/resource/agile'
require 'jira/resource/board'

# Confluence Resources
require 'jira/resource/content'

# Clients
require 'jira/request_client'
require 'jira/http_client'
require 'jira/client'