# frozen_string_literal: true

module Nokogiri
  class << self
    # :nodoc:
    #
    # Deeply freeze +obj+ so that it can be read from any Ractor, and return it. On Ruby
    # implementations without Ractors, freeze only +obj+ itself.
    def make_shareable(obj)
      if defined?(::Ractor.make_shareable)
        ::Ractor.make_shareable(obj)
      else
        obj.freeze
      end
    end
  end
end
