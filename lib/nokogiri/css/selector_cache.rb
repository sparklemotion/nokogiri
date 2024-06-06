# frozen_string_literal: true

require "thread"

module Nokogiri
  module CSS
    module SelectorCache # :nodoc:
      @cache = {}
      @mutex = Mutex.new

      class << self
        # Get the css selector in +string+ from the cache
        def [](key)
          @mutex.synchronize { @cache[key] }
        end

        # Set the css selector in +string+ in the cache to +value+
        def []=(key, value)
          @mutex.synchronize { @cache[key] = value }
        end

        # Clear the cache
        def clear_cache(create_new_object = false)
          @mutex.synchronize do
            if create_new_object
              @cache = {}
            else
              @cache.clear
            end
          end
        end

        # Construct a unique key cache key
        def key(ns:, selector:, visitor:)
          [ns, selector, visitor.config]
        end
      end
    end
  end
end
