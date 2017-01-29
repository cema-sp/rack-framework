# frozen_string_literal: true

require_relative './forfun/app.rb'

module Forfun
  APP_METHODS = %i(get post put patch delete).freeze
end

# ------ DSL ------

Forfun::APP_METHODS.each do |http_method|
  app = Forfun::App.instance

  define_method(http_method) do |path, &block|
    app.map(http_method, path, &block)
    run app if respond_to? :run
  end
end
