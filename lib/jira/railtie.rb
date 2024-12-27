# frozen_string_literal: true

require 'jira-ruby'
require 'rails'

module JIRA
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/generate.rake'
    end
  end
end
