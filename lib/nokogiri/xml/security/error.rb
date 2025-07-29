# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module XML
    module Security
      class Error
        attr_reader :locations

        def special_backtrace
          locations.map do |location|
            "#{location.file}:#{location.line}:in '#{location.func}'"
          end
        end

        def location
          locations.first
        end

        def to_s
          location.error_message
        end
      end
    end
  end
end
