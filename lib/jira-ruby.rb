Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f } if defined?(Rake)

$: << File.expand_path(File.dirname(__FILE__))
require 'jira-ruby/resource/base'
require 'jira-ruby/resource/base_factory'
require 'jira-ruby/resource/project'
require 'jira-ruby/client'
