require 'nokogiri'

if ((defined?(Nokogiri::HTML5) && Nokogiri::HTML5.respond_to?(:parse)) &&
    (defined?(Nokogiri::Gumbo) && Nokogiri::Gumbo.respond_to?(:parse)) &&
    !(ENV.key?("NOKOGUMBO_IGNORE_NOKOGIRI_HTML5") && ENV["NOKOGUMBO_IGNORE_NOKOGIRI_HTML5"] != "false"))

  warn "NOTE: nokogumbo: Using Nokogiri::HTML5 provided by Nokogiri. See https://github.com/sparklemotion/nokogiri/issues/2205 for more information."

  ::Nokogumbo = ::Nokogiri::Gumbo
else
  require 'nokogumbo/html5'
  require 'nokogumbo/nokogumbo'

  module Nokogumbo
    # The default maximum number of attributes per element.
    DEFAULT_MAX_ATTRIBUTES = 400

    # The default maximum number of errors for parsing a document or a fragment.
    DEFAULT_MAX_ERRORS = 0

    # The default maximum depth of the DOM tree produced by parsing a document
    # or fragment.
    DEFAULT_MAX_TREE_DEPTH = 400
  end
end

require 'nokogumbo/version'
