# frozen_string_literal: true

module Nokogiri
  module CSS
    module SelectorCache # :nodoc:
      @cache = {}
      @mutex = Mutex.new

      class << self
        # Retrieve the cached XPath expressions for the key
        def [](key)
          cache, mutex = storage
          mutex.synchronize { cache[key] }
        end

        # Insert the XPath expressions `value` at the cache key
        def []=(key, value)
          cache, mutex = storage
          mutex.synchronize { cache[key] = value }
        end

        # Clear the cache
        def clear_cache(create_new_object = false)
          cache, mutex = storage
          mutex.synchronize do
            if create_new_object && main_ractor? # used in tests to avoid 'method redefined' warnings when injecting spies
              @cache = {}
            else
              cache.clear
            end
          end
        end

        # Construct a unique key cache key
        def key(selector:, visitor:)
          [selector, visitor.config]
        end

        private

        # The cache is shared by all threads in the main Ractor. Other Ractors can't read
        # module-level state, so each of them keeps a cache of its own.
        def storage
          if main_ractor?
            [@cache, @mutex]
          else
            ::Ractor.current[:__nokogiri_css_selector_cache__] ||= [{}, Mutex.new]
          end
        end

        def main_ractor?
          !defined?(::Ractor) || ::Ractor.current == ::Ractor.main
        end
      end
    end
  end
end
