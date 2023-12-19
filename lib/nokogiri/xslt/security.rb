# frozen_string_literal: true

module Nokogiri
  module XSLT
    module Security
      class Config
        attr_accessor :allow_read_file
        attr_accessor :allow_write_file
        attr_accessor :allow_create_directory
        attr_accessor :allow_read_network
        attr_accessor :allow_write_network

        # Mirror xslt (implicit) internal defaults
        def initialize
          @allow_read_file = true
          @allow_write_file = true
          @allow_create_directory = true
          @allow_read_network = true
          @allow_write_network = true
        end
      end
    end
  end
end
