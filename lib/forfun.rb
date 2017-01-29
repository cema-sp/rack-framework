# frozen_string_literal: true

require 'rack'
require 'json'
require 'hashie'
require 'singleton'

module Forfun
  APP_METHODS = %i(get post put patch delete).freeze

  class Params < Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::IndifferentAccess
  end

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

  NotFound = lambda do |env|
    [404, {}, [{ error: 'Not Found' }]]
  end

  InvalidParams = lambda do |env|
    [422, {}, [{ error: 'Invalid params' }]]
  end
end

# ------ DSL ------

app = Forfun::App.instance

Forfun::APP_METHODS.each do |http_method|
  define_method(http_method) do |path, &block|
    app.map(http_method, path, &block)
    run app if respond_to? :run
  end
end
