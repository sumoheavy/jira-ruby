# frozen_string_literal: true

require 'forwardable'
require 'active_support/core_ext/object'

module JIRA
  class HTTPError < StandardError
    extend Forwardable

    def_instance_delegators :@response, :code
    attr_reader :response, :message

    def initialize(response)
      @response = response
      @message = response.try(:message).presence || response.try(:body)
    end
  end
end
