# frozen_string_literal: true

require 'json'
require 'singleton'

require_relative './params.rb'
require_relative './errors.rb'

module Forfun
  APP_METHODS = %i(get post put patch delete).freeze

  class App
    include Singleton

    APP_HEADERS = { 'Content-Type' => 'application/json' }

    def initialize
      @routes = {}
    end

    def call(env)
      http_method = env['REQUEST_METHOD'].to_sym
      path        = env['PATH_INFO'].downcase.to_s

      handler = @routes.dig(http_method, path) || NotFound

      begin
        status, headers, body = handler.call(env)
      rescue JSON::ParserError
        status, headers, body = InvalidParams.call(env)
      end

      response(status, headers, body)
    end

    def map(http_method, path, &block)
      http_method_sanitized = http_method.upcase.to_sym
      path_sanitized = path.downcase.to_s

      handler = lambda do |env|
        params = extract_params(env)

        result = if block.nil?
                   {}
                 elsif params
                   block.call(params)
                 else
                   block.call
                 end

        [200, {}, [result]]
      end

      @routes[http_method_sanitized] ||= {}
      @routes[http_method_sanitized][path_sanitized] = handler
    end

    private

    def response(status, headers, body)
      [status, APP_HEADERS.merge(headers), body.map { |b| JSON.dump(b) }]
    end

    def extract_params(env)
      return nil unless env['rack.input']

      params_encoded = env['rack.input'].read
      return nil if params_encoded.empty?

      params_decoded = JSON.parse(params_encoded)

      Forfun::Params[params_decoded]
    end
  end
end
