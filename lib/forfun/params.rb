# frozen_string_literal: true

require 'hashie'

module Forfun
  class Params < Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::IndifferentAccess
  end
end
