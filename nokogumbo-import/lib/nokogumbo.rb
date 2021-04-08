#
#  Copyright 2013-2021 Sam Ruby, Stephen Checkoway
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

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
