# frozen_string_literal: true

require "delegate"

module Nokogiri
  module XML
    class XPathFunctions < SimpleDelegator
      class << self
        def wrap(handler)
          if handler.nil?
            @wrap_nil ||= new(Object.new)
          else
            new(handler)
          end
        end
      end
    end
  end
end
