# frozen_string_literal: true

require "pathname"

module Nokogiri
  module TestHelpers
    class TrackingPathname < Pathname
      attr_reader :opened_io

      def expand_path
        self
      end

      def open(*args, &block)
        if block
          super(*args) do |io|
            @opened_io = io
            block.call(io)
          end
        else
          @opened_io = super(*args)
        end
      end
    end
  end
end
