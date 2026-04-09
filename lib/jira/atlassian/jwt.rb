# frozen_string_literal: true

# Copyright 2013 Atlassian Pty Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'jwt'
require 'uri'
require 'cgi'

module JIRA
  module Atlassian
    module Jwt
      class << self
        CANONICAL_QUERY_SEPARATOR = '&'
        ESCAPED_CANONICAL_QUERY_SEPARATOR = '%26'

        def create_canonical_request(uri, http_method, base_uri)
          uri = URI.parse(uri) unless uri.is_a? URI
          base_uri = URI.parse(base_uri) unless base_uri.is_a? URI

          [
            http_method.upcase,
            canonicalize_uri(uri, base_uri),
            canonicalize_query_string(uri.query)
          ].join(CANONICAL_QUERY_SEPARATOR)
        end

        def build_claims(issuer, url, http_method, base_url = '', issued_at = nil, expires = nil, attributes = {}) # rubocop:disable Metrics/ParameterLists
          issued_at ||= Time.now.to_i
          expires ||= issued_at + 60
          qsh = Digest::SHA256.hexdigest(create_canonical_request(url, http_method, base_url))

          {
            iss: issuer,
            iat: issued_at,
            exp: expires,
            qsh: qsh
          }.merge(attributes)
        end

        def canonicalize_uri(uri, base_uri)
          path = uri.path.sub(/^#{base_uri.path}/, '')
          path = '/' if path.nil? || path.empty?
          path = "/#{path}" unless path.start_with? '/'
          path.chomp!('/') if path.length > 1
          path.gsub(CANONICAL_QUERY_SEPARATOR, ESCAPED_CANONICAL_QUERY_SEPARATOR)
        end

        def canonicalize_query_string(query)
          return '' if query.nil? || query.empty?

          query = CGI.parse(query)
          query.delete('jwt')
          query.each do |k, v|
            query[k] = v.map { |a| CGI.escape a }.join(',') if v.is_a? Array
            query[k].gsub!('+', '%20')  # Use %20, not CGI.escape default of "+"
            query[k].gsub!('%7E', '~')  # Unescape "~" per JS tests
          end
          query = query.sort.to_h
          query.map { |k, v| "#{CGI.escape k}=#{v}" }.join(CANONICAL_QUERY_SEPARATOR)
        end
      end
    end
  end
end
