# frozen_string_literal: true

module Nokogiri
  module MemoryDebugger
    class << self
      def active?
        if defined?(@active)
          @active
        else
          @active = valgrind_active? || asan_active?
        end
      end

      private

      def valgrind_active?
        # https://stackoverflow.com/questions/365458/how-can-i-detect-if-a-program-is-running-from-within-valgrind/62364698#62364698
        ENV["LD_PRELOAD"] =~ /valgrind|vgpreload/
      end

      def asan_active?
        # https://stackoverflow.com/questions/35012059/check-whether-sanitizer-like-addresssanitizer-is-active
        `ldd #{Gem.ruby}`.include?("libasan.so")
      rescue
        false
      end
    end
  end
end
