# frozen_string_literal: true

module Forfun
  NotFound = lambda do |env|
    [404, {}, [{ error: 'Not Found' }]]
  end

  InvalidParams = lambda do |env|
    [422, {}, [{ error: 'Invalid params' }]]
  end
end
