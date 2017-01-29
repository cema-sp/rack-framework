require 'rack'
require 'json'
require 'hashie'

module Forfun
  class Params < Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::IndifferentAccess
  end

  class App
    APP_HEADERS = { 'Content-Type' => 'application/json' }

    @@routes = {}

    class << self
      def call(env)
        http_method = env['REQUEST_METHOD'].to_sym
        path        = env['PATH_INFO'].downcase.to_s

        handler = @@routes.dig(http_method, path) || NotFound

        begin
          status, headers, body = handler.call(env)
        rescue JSON::ParserError
          status, headers, body = InvalidParams.call(env)
        end

        [status, APP_HEADERS.merge(headers), body.map { |b| JSON.dump(b) }]
      end

      def get(path)
        map(:GET, path) do |_env|
          result = yield
          [200, {}, [result]]
        end
      end

      def post(path)
        map(:POST, path) do |env|
          raw_params = JSON.parse(env['rack.input'].read)
          params = Forfun::Params[raw_params]

          result = yield params
          [200, {}, [result]]
        end
      end

      private

      def map(http_method, path, &block)
        http_method_sanitized = http_method.upcase.to_sym
        path_sanitized = path.downcase.to_s

        @@routes[http_method_sanitized] ||= {}
        @@routes[http_method_sanitized][path_sanitized] = block.to_proc
      end
    end
  end

  class NotFound
    def self.call(_env)
      [404, {}, [{ error: 'Not Found' }]]
    end
  end

  class InvalidParams
    def self.call(_env)
      [422, {}, [{ error: 'Invalid params' }]]
    end
  end
end

# ------ DSL ------

def get(path, &block)
  Forfun::App.get(path, &block)
end

def post(path, &block)
  Forfun::App.post(path, &block)
end

