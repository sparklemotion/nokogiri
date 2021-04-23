#
#  Copyright 2013-2021 Sam Ruby, Stephen Checkoway, Mike Dalessio
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

require 'rubygems'
require 'fileutils'
require 'mkmf'

$CFLAGS += " -std=c99"
$LDFLAGS.gsub!('-Wl,--no-undefined', '')
$DLDFLAGS.gsub!('-Wl,--no-undefined', '')
$warnflags = CONFIG['warnflags'] = '-Wall'

append_cflags("-I../../../../ext/nokogiri")
append_cflags("-I../../../../tmp/x86_64-linux/nokogiri/2.7.2/include/libxml2")
# TODO: look at what to do with Nokogiri::VERSION_INFO["nokogiri"]["ldflags"] (if anything)

have_header('libxml/tree.h') || raise("could not find libxml2 headers")
have_header('nokogiri.h') || raise("could not find nokogiri.h")

append_cflags("-DNGLIB=1")

# Symlink gumbo-parser source files.
ext_dir = File.dirname(__FILE__)

Dir.chdir(ext_dir) do
  $srcs = Dir['*.c', '../../gumbo-parser/src/*.c']
  $hdrs = Dir['*.h', '../../gumbo-parser/src/*.h']
end
$INCFLAGS << ' -I$(srcdir)/../../gumbo-parser/src'
$VPATH << '$(srcdir)/../../gumbo-parser/src'

create_makefile('nokogumbo/nokogumbo') do |conf|
  conf.map! do |chunk|
    chunk.gsub(/^HDRS = .*$/, "HDRS = #{$hdrs.map { |h| File.join('$(srcdir)', h)}.join(' ')}")
  end
end
# vim: set sw=2 sts=2 ts=8 et:
